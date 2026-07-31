import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/family_models.dart';
import '../../services/care_coach_chat_assistant.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CHAT SCREEN — Family Member ↔ Elderly User
// ─────────────────────────────────────────────────────────────────────────────
// Dependencies to add to pubspec.yaml:
//   record: ^5.1.2
//   audioplayers: ^6.0.0
//   path_provider: ^2.1.4
//
// Android: add to AndroidManifest.xml
//   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
//   <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
//
// iOS: add to Info.plist
//   <key>NSMicrophoneUsageDescription</key>
//   <string>BridgeCare needs mic access for voice notes.</string>

class FamilyChatScreen extends StatefulWidget {
  final LinkedUser linkedUser;
  /// When true (e.g. main bottom-nav shell), hides the back arrow — there is no parent route.
  final bool embeddedInShell;

  const FamilyChatScreen({
    super.key,
    required this.linkedUser,
    this.embeddedInShell = false,
  });

  @override
  State<FamilyChatScreen> createState() => _FamilyChatScreenState();
}

class _FamilyChatScreenState extends State<FamilyChatScreen> with TickerProviderStateMixin {
  // ── Colors ─────────────────────────────────────────────────────────────────
  static const _primary      = Color(0xFF1565C0);
  static const _primaryDark  = Color(0xFF1565C0);
  static const _myBubble     = Color(0xFF1565C0);
  static const _theirBubble  = Color(0xFFEFF4FF);
  static const _coachBubble  = Color(0xFFF5F3FF);
  static const _coachBorder  = Color(0xFFC4B5FD);
  static const _coachAccent  = Color(0xFF7C3AED);
  static const _green         = Color(0xFF2E7D32);
  static const _red           = Color(0xFFC62828);
  static const _textPrimary  = Color(0xFF1A1A2E);
  static const _textMuted    = Color(0xFF6B7280);
  static const _divider      = Color(0xFFE3EAF3);

  // ── Services ───────────────────────────────────────────────────────────────
  final _supabase = Supabase.instance.client;
  final _ctrl     = TextEditingController();
  final _scroll   = ScrollController();
  final _focusNode = FocusNode();

  // ── Recording ──────────────────────────────────────────────────────────────
  final _recorder    = AudioRecorder();
  final _player      = AudioPlayer();
  bool   _isRecording = false;
  String? _recordingPath;
  Timer?  _recTimer;
  int    _recSeconds  = 0;

  // ── Playback state per message ─────────────────────────────────────────────
  final Map<String, bool>    _playingMap  = {};
  final Map<String, Duration> _positionMap = {};

  // ── Messages ───────────────────────────────────────────────────────────────
  List<_ChatMessage> _messages = [];
  bool _sending = false;
  bool _messagesBackendAvailable = true;
  RealtimeChannel? _messagesChannel;
  Timer? _coachReplyTimer;
  bool _coachTyping = false;
  int _userSendCount = 0;

  String get _myId    => _supabase.auth.currentUser?.id ?? 'me';
  String get _theirId => widget.linkedUser.uid;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadMessages();
    _subscribeRealtime();
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed) {
        setState(() {
          for (final k in _playingMap.keys.toList()) _playingMap[k] = false;
        });
      }
    });
    _player.onPositionChanged.listen((pos) {
      final key = _playingMap.entries.firstWhere((e) => e.value, orElse: () => const MapEntry('', false)).key;
      if (key.isNotEmpty) setState(() => _positionMap[key] = pos);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    _focusNode.dispose();
    _recorder.dispose();
    _player.dispose();
    _recTimer?.cancel();
    _coachReplyTimer?.cancel();
    _messagesChannel?.unsubscribe();
    super.dispose();
  }

  // ── Load messages ──────────────────────────────────────────────────────────
  Future<void> _loadMessages() async {
    try {
      final res = await _supabase
          .from('messages')
          .select()
          .or('and(sender_id.eq.$_myId,receiver_id.eq.$_theirId),'
              'and(sender_id.eq.$_theirId,receiver_id.eq.$_myId)')
          .order('created_at');
      if (mounted) {
        setState(() {
          _messagesBackendAvailable = true;
          _messages = (res as List).map((m) => _ChatMessage(
            id: m['id']?.toString() ?? '',
            senderId: m['sender_id']?.toString() ?? '',
            text: m['content']?.toString() ?? '',
            isVoice: m['type'] == 'voice',
            voiceDuration: m['voice_duration'] as int?,
            voiceUrl: m['voice_url']?.toString(),
            timestamp: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
          )).toList();
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('ERROR LOADING MESSAGES: $e');
      final tableMissing = e is PostgrestException && e.code == 'PGRST205';
      if (mounted) {
        setState(() {
          _messages = [];
          if (tableMissing) {
            _messagesBackendAvailable = false;
          }
        });
      }
      _scrollToBottom();
    }
  }


  // ── Realtime ───────────────────────────────────────────────────────────────
  void _subscribeRealtime() {
    if (!_messagesBackendAvailable) return;
    try {
      _messagesChannel = _supabase.channel('messages_channel').onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          final m = payload.newRecord;
          final msg = _ChatMessage(
            id: m['id']?.toString() ?? '',
            senderId: m['sender_id']?.toString() ?? '',
            text: m['content']?.toString() ?? '',
            isVoice: m['type'] == 'voice',
            voiceDuration: m['voice_duration'] as int?,
            voiceUrl: m['voice_url']?.toString(),
            timestamp: DateTime.tryParse(m['created_at']?.toString() ?? '') ?? DateTime.now(),
          );
          if (msg.senderId == CareCoachChatAssistant.syntheticSenderId) return;
          if (mounted && (msg.senderId == _myId || msg.senderId == _theirId)) {
            setState(() => _messages.add(msg));
            _scrollToBottom();
          }
        },
      );
      _messagesChannel?.subscribe();
    } catch (_) {}
  }

  // ── Send text ──────────────────────────────────────────────────────────────
  Future<void> _sendText() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    _ctrl.clear();
    _focusNode.requestFocus();
    final optimistic = _ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: _myId, text: text,
      timestamp: DateTime.now(), isPending: true);
    setState(() { _messages.add(optimistic); _sending = true; });
    _scrollToBottom();
    try {
      await _insertTextMessage(text);
      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m.id == optimistic.id);
        if (idx >= 0) _messages[idx] = _ChatMessage(
          id: optimistic.id, senderId: _myId, text: text,
          timestamp: optimistic.timestamp);
        _sending = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == optimistic.id);
          if (idx >= 0) {
            _messages[idx] = _ChatMessage(
              id: optimistic.id,
              senderId: _myId,
              text: text,
              timestamp: optimistic.timestamp,
              isPending: true,
            );
          }
          _sending = false;
        });
      }
    } finally {
      if (mounted) {
        _userSendCount++;
        _scheduleCoachReply(text);
      }
    }
  }

  Future<void> _insertTextMessage(String text) async {
    if (!_messagesBackendAvailable) return;
    final payloads = <Map<String, dynamic>>[
      {'sender_id': _myId, 'receiver_id': _theirId, 'content': text, 'type': 'text'},
      {'sender_id': _myId, 'recipient_id': _theirId, 'content': text, 'type': 'text'},
      {'from_user_id': _myId, 'to_user_id': _theirId, 'content': text, 'type': 'text'},
      {'sender_id': _myId, 'receiver_id': _theirId, 'message': text, 'type': 'text'},
    ];
    Object? lastError;
    for (final payload in payloads) {
      try {
        await _supabase.from('messages').insert(payload);
        return;
      } catch (e) {
        if (e is PostgrestException && e.code == 'PGRST205') {
          _messagesBackendAvailable = false;
          return;
        }
        lastError = e;
      }
    }
    throw lastError ?? Exception('Failed to send message');
  }

  void _scheduleCoachReply(String trimmedMessage, {bool voiceNote = false}) {
    _coachReplyTimer?.cancel();
    if (!mounted) return;

    final recipientFirst =
        CareCoachChatAssistant.recipientFirstName(widget.linkedUser.fullName);
    setState(() => _coachTyping = true);
    _scrollToBottom();

    final delayMs = 700 + Random().nextInt(1100);
    _coachReplyTimer = Timer(Duration(milliseconds: delayMs), () async {
      final replyText = await CareCoachChatAssistant.composeReplyAsync(
        message: trimmedMessage,
        recipientName: recipientFirst,
        voiceNote: voiceNote,
        conversationTurn: _userSendCount,
      );
      if (!mounted) return;
      setState(() {
        _coachTyping = false;
        _messages.add(
          _ChatMessage(
            id: 'coach_${DateTime.now().microsecondsSinceEpoch}',
            senderId: CareCoachChatAssistant.syntheticSenderId,
            text: replyText,
            timestamp: DateTime.now(),
            isAiCoach: true,
          ),
        );
      });
      _scrollToBottom();
    });
  }

  // ── Voice recording — START ────────────────────────────────────────────────
  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied. Please allow access in settings.')));
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    _recordingPath = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
      path: _recordingPath!,
    );

    _recSeconds = 0;
    _recTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _recSeconds++);
        if (_recSeconds >= 120) _stopAndSend();
      }
    });

    setState(() => _isRecording = true);
  }

  // ── Voice recording — STOP & SEND ─────────────────────────────────────────
  Future<void> _stopAndSend() async {
    _recTimer?.cancel();
    final path = await _recorder.stop();
    setState(() => _isRecording = false);

    final duration = _recSeconds;
    _recSeconds = 0;

    if (path == null) return;

    // Add optimistic voice message locally
    final voiceId = DateTime.now().millisecondsSinceEpoch.toString();
    final msg = _ChatMessage(
      id: voiceId, senderId: _myId, text: '',
      isVoice: true, voiceDuration: duration,
      voiceLocalPath: path,
      timestamp: DateTime.now(), isPending: true);
    setState(() => _messages.add(msg));
    _scrollToBottom();

    if (!_messagesBackendAvailable) {
      if (mounted) {
        _userSendCount++;
        _scheduleCoachReply('', voiceNote: true);
      }
      return;
    }

    // Try uploading to Supabase Storage
    try {
      final bytes = await File(path).readAsBytes();
      final storagePath = 'voice_notes/$_myId/$voiceId.m4a';
      await _supabase.storage.from('messages').uploadBinary(storagePath, bytes,
        fileOptions: const FileOptions(contentType: 'audio/m4a'));
      final publicUrl = _supabase.storage.from('messages').getPublicUrl(storagePath);

      await _supabase.from('messages').insert({
        'sender_id': _myId, 'receiver_id': _theirId,
        'content': '', 'type': 'voice',
        'voice_duration': duration,
        'voice_url': publicUrl,
      });

      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m.id == voiceId);
        if (idx >= 0) _messages[idx] = _ChatMessage(
          id: voiceId, senderId: _myId, text: '',
          isVoice: true, voiceDuration: duration,
          voiceLocalPath: path, voiceUrl: publicUrl,
          timestamp: msg.timestamp);
      });
    } catch (e) {
      if (e is PostgrestException && e.code == 'PGRST205') {
        setState(() {
          _messagesBackendAvailable = false;
        });
      }
      // Keep local playback even if upload fails
      if (mounted) setState(() {
        final idx = _messages.indexWhere((m) => m.id == voiceId);
        if (idx >= 0) _messages[idx] = _ChatMessage(
          id: voiceId, senderId: _myId, text: '',
          isVoice: true, voiceDuration: duration,
          voiceLocalPath: path,
          timestamp: msg.timestamp);
      });
    }
    if (mounted) {
      _userSendCount++;
      _scheduleCoachReply('', voiceNote: true);
    }
  }

  // ── Cancel recording ───────────────────────────────────────────────────────
  Future<void> _cancelRecording() async {
    _recTimer?.cancel();
    await _recorder.stop();
    setState(() { _isRecording = false; _recSeconds = 0; });
  }

  // ── Play voice message ─────────────────────────────────────────────────────
  Future<void> _playVoice(String id, String? localPath, String? url) async {
    if (_playingMap[id] == true) {
      await _player.stop();
      setState(() => _playingMap[id] = false);
      return;
    }
    // Stop any currently playing
    await _player.stop();
    setState(() {
      for (final k in _playingMap.keys.toList()) _playingMap[k] = false;
      _playingMap[id] = true;
    });

    try {
      if (localPath != null && File(localPath).existsSync()) {
        await _player.play(DeviceFileSource(localPath));
      } else if (url != null) {
        await _player.play(UrlSource(url));
      }
    } catch (_) {
      setState(() => _playingMap[id] = false);
    }
  }

  // ── Video / Audio call ─────────────────────────────────────────────────────
  Future<void> _showCallSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE9ECEF), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Start a Call', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _primaryDark)),
          const SizedBox(height: 6),
          Text('Call ${widget.linkedUser.fullName}?',
            style: const TextStyle(color: _textMuted)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _callOption('Audio Call', Icons.phone_rounded, _green, () async {
              Navigator.pop(context);
              final uri = Uri(scheme: 'tel', path: widget.linkedUser.phoneNumber);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            })),
            const SizedBox(width: 12),
            Expanded(child: _callOption('Video Call', Icons.videocam_rounded, _primary, () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Video calling coming soon (integrate WebRTC / Agora)')));
            })),
          ]),
        ]),
      ),
    );
  }

  Widget _callOption(String label, IconData icon, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60))),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22)),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
        ])));

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FA),
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned(
            left: -30,
            top: -36,
            child: IgnorePointer(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _primary.withValues(alpha: 0.13),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -36,
            bottom: 120,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _coachAccent.withValues(alpha: 0.09),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Column(children: [
            Expanded(child: _buildMessageList()),
            if (!_isRecording) _quickComposerStrip(),
            _isRecording ? _buildRecordingBar() : _buildInputBar(),
          ]),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.94),
                const Color(0xFFE7F0FA).withValues(alpha: 0.92),
              ],
            ),
          ),
        ),
        automaticallyImplyLeading: !widget.embeddedInShell,
        leadingWidth: widget.embeddedInShell ? 12 : null,
        leading: widget.embeddedInShell
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: _primary),
                onPressed: () => Navigator.pop(context),
              ),
        titleSpacing: widget.embeddedInShell ? 4 : NavigationToolbar.kMiddleSpacing,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.linkedUser.fullName.isNotEmpty
                      ? widget.linkedUser.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.linkedUser.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: _coachAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Care Coach AI · smart replies',
                          style: TextStyle(fontSize: 11, color: _textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_rounded, color: _primary),
            onPressed: _showCallSheet,
          ),
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: _primary),
            onPressed: () async {
              final uri =
                  Uri(scheme: 'tel', path: widget.linkedUser.phoneNumber);
              if (await canLaunchUrl(uri)) await launchUrl(uri);
            },
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: _divider),
        ),
      );
  Widget _quickComposerStrip() {
    final quick = [
      'How are you feeling now?',
      'Did you eat and drink water?',
      'I am proud of you today.',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: SizedBox(
        height: 34,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: quick.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final text = quick[index];
            return ActionChip(
              backgroundColor: Colors.white.withValues(alpha: 0.92),
              side: BorderSide(color: _primary.withValues(alpha: 0.22)),
              avatar: Icon(Icons.bolt_rounded, size: 14, color: _primary.withValues(alpha: 0.85)),
              label: Text(
                text,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                _ctrl.text = text;
                _sendText();
              },
            );
          },
        ),
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────
  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE3EAF3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded,
                        color: _coachAccent.withValues(alpha: 0.95), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Chat with Care Coach',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _coachAccent.withValues(alpha: 0.95),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Send a message and the Care Coach will answer with ideas, reassurance, '
                  'and wording you can use with your loved one. Works offline—or add an '
                  'OpenAI key at build time for full AI replies.',
                  style: TextStyle(
                    height: 1.35,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('How are you feeling today?'),
                onPressed: () {
                  _ctrl.text = 'How are you feeling today?';
                  _sendText();
                },
              ),
              ActionChip(
                label: const Text('Did you take your medication?'),
                onPressed: () {
                  _ctrl.text = 'Did you take your medication?';
                  _sendText();
                },
              ),
              ActionChip(
                label: const Text('I am here if you need anything.'),
                onPressed: () {
                  _ctrl.text = 'I am here if you need anything.';
                  _sendText();
                },
              ),
            ],
          ),
        ],
      );
    }

    final extra = _coachTyping ? 1 : 0;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      itemCount: _messages.length + extra,
      itemBuilder: (_, i) {
        if (_coachTyping && i == _messages.length) {
          return _coachTypingRow();
        }
        final msg = _messages[i];
        final isMe = msg.senderId == _myId;
        final showDate =
            i == 0 || _messages[i - 1].timestamp.day != msg.timestamp.day;
        return Column(children: [
          if (showDate) _dateDivider(msg.timestamp),
          _messageBubble(msg, isMe),
        ]);
      },
    );
  }

  Widget _coachAvatar({double size = 28}) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)]),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.auto_awesome_rounded,
        color: Colors.white,
        size: size * 0.52,
      ),
    );
  }

  Widget _coachTypingRow() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _coachAvatar(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _coachBubble,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: _coachBorder),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Typing',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _coachAccent),
                ),
                SizedBox(width: 8),
                _CoachTypingDots(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateDivider(DateTime dt) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      const Expanded(child: Divider(color: _divider)),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(_fmtDate(dt), style: const TextStyle(fontSize: 11, color: _textMuted))),
      const Expanded(child: Divider(color: _divider)),
    ]));

  String _fmtDate(DateTime dt) {
    final now = DateTime.now();
    if (dt.day == now.day) return 'Today';
    if (dt.day == now.day - 1) return 'Yesterday';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Widget _messageBubble(_ChatMessage msg, bool isMe) {
    final coach = msg.isAiCoach;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Their avatar
          if (!isMe) ...[
            if (coach)
              _coachAvatar()
            else
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  color: _primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.linkedUser.fullName.isNotEmpty
                        ? widget.linkedUser.fullName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],

          // Bubble
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? _myBubble : (coach ? _coachBubble : _theirBubble),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18)),
              border: isMe
                  ? null
                  : Border.all(
                      color: coach ? _coachBorder : const Color(0xFFDBEAFE),
                    ),
            ),
            child: msg.isVoice
                ? _voiceBubble(msg, isMe)
                : _textBubble(msg, isMe),
          ),

          // Status ticks (mine only)
          if (isMe) ...[
            const SizedBox(width: 4),
            Icon(
              msg.isPending ? Icons.access_time_rounded : Icons.done_all_rounded,
              size: 14,
              color: msg.isPending ? _textMuted : _primary),
          ],
        ],
      ),
    );
  }

  Widget _textBubble(_ChatMessage msg, bool isMe) {
    final coach = msg.isAiCoach;
    final textColor =
        isMe ? Colors.white : (coach ? const Color(0xFF3B0764) : _textPrimary);
    return Column(
      crossAxisAlignment:
          coach ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        if (coach) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 14, color: _coachAccent),
              const SizedBox(width: 4),
              Text(
                'Care Coach',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _coachAccent,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          msg.text,
          style: TextStyle(color: textColor, fontSize: 14, height: 1.35),
        ),
        const SizedBox(height: 3),
        Text(
          _fmtTime(msg.timestamp),
          style: TextStyle(
            fontSize: 10,
            color: isMe ? Colors.white60 : _textMuted,
          ),
        ),
      ],
    );
  }

  // ── Voice bubble ───────────────────────────────────────────────────────────
  Widget _voiceBubble(_ChatMessage msg, bool isMe) {
    final isPlaying = _playingMap[msg.id] == true;
    final iconColor = isMe ? Colors.white : _primary;
    final waveColor = isMe ? Colors.white.withAlpha(150) : _primary.withAlpha(100);
    final dur = msg.voiceDuration ?? 0;

    return Row(mainAxisSize: MainAxisSize.min, children: [
      // Play / Pause button
      GestureDetector(
        onTap: () => _playVoice(msg.id, msg.voiceLocalPath, msg.voiceUrl),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withAlpha(46) : _primary.withAlpha(38),
            shape: BoxShape.circle),
          child: Icon(
            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: iconColor, size: 22)),
      ),
      const SizedBox(width: 8),

      // Waveform bars + duration
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          children: List.generate(20, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 3,
            height: isPlaying ? (4 + (i % 5) * 4.0) * (i == (_recSeconds % 20) ? 1.4 : 1.0) : (4 + (i % 5) * 4.0),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: waveColor.withOpacity(isPlaying && i == (_recSeconds % 20) ? 1.0 : 0.7),
              borderRadius: BorderRadius.circular(2)),
          )),
        ),
        const SizedBox(height: 3),
        Text(
          _fmtDuration(dur),
          style: TextStyle(fontSize: 10,
            color: isMe ? Colors.white60 : _textMuted)),
      ]),
      const SizedBox(width: 6),
      Text(_fmtTime(msg.timestamp),
        style: TextStyle(fontSize: 10,
          color: isMe ? Colors.white60 : _textMuted)),
    ]);
  }

  String _fmtDuration(int secs) {
    final m = secs ~/ 60;
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _fmtTime(DateTime dt) =>
    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── Normal input bar ───────────────────────────────────────────────────────
  Widget _buildInputBar() => Container(
    padding: EdgeInsets.fromLTRB(12, 8, 12, MediaQuery.of(context).padding.bottom + 8),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))]),
    child: Row(children: [
      // Mic button — tap to start recording
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _startRecording();
        },
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: const Color(0x1A1565C0),
            borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.mic_rounded, color: _primary, size: 20))),
      const SizedBox(width: 8),
      // Text field
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4FA),
            borderRadius: BorderRadius.circular(24),
          ),
          child: TextField(
              controller: _ctrl,
              focusNode: _focusNode,
              textCapitalization: TextCapitalization.sentences,
              maxLines: 1,
              textInputAction: TextInputAction.send,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onSubmitted: (_) {
                if (!_sending) _sendText();
              },
            ),
        ),
      ),
      const SizedBox(width: 8),
      // Send button
      GestureDetector(
        onTap: _sending
            ? null
            : () {
                HapticFeedback.lightImpact();
                _sendText();
              },
        child: Opacity(
          opacity: _sending ? 0.6 : 1,
          child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: _primary.withAlpha(77),
              blurRadius: 8, offset: const Offset(0, 3))]),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20)),
        )),
    ]),
  );

  // ── Active recording bar ───────────────────────────────────────────────────
  Widget _buildRecordingBar() => Container(
    padding: EdgeInsets.fromLTRB(14, 10, 12, MediaQuery.of(context).padding.bottom + 10),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -3))]),
    child: Row(children: [
      // Blinking red dot
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 700),
        builder: (_, v, __) => Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: _red.withOpacity(v), shape: BoxShape.circle)),
        onEnd: () => setState(() {})),
      const SizedBox(width: 10),
      // Timer
      Text(
        _fmtDuration(_recSeconds),
        style: const TextStyle(color: _red, fontWeight: FontWeight.bold, fontSize: 15)),
      const SizedBox(width: 10),
      // Animated waveform preview
      Expanded(child: Row(
        children: List.generate(24, (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 3,
          height: (4 + ((_recSeconds + i) % 5) * 3.5),
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: _red.withAlpha(180),
            borderRadius: BorderRadius.circular(2)))),
      )),
      // Cancel
      GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          _cancelRecording();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10)),
          child: const Text('Cancel', style: TextStyle(color: _textMuted, fontSize: 12)))),
      const SizedBox(width: 8),
      // Send voice
      GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _stopAndSend();
        },
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: _green,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(
              color: _green.withAlpha(77), blurRadius: 8, offset: const Offset(0, 3))]),
          child: const Icon(Icons.send_rounded, color: Colors.white, size: 20))),
    ]),
  );
}

// ── Typing dots (Care Coach) ─────────────────────────────────────────────────
class _CoachTypingDots extends StatefulWidget {
  const _CoachTypingDots();

  @override
  State<_CoachTypingDots> createState() => _CoachTypingDotsState();
}

class _CoachTypingDotsState extends State<_CoachTypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dot = Color(0xFF7C3AED);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        double phase(int i) => ((_c.value + i / 3) % 1.0);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final o = (0.35 + 0.65 * phase(i)).clamp(0.25, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: o,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: dot,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ── Message model ────────────────────────────────────────────────────────────
class _ChatMessage {
  final String  id;
  final String  senderId;
  final String  text;
  final bool    isVoice;
  final int?    voiceDuration;
  final String? voiceUrl;
  final String? voiceLocalPath;
  final DateTime timestamp;
  final bool    isPending;
  final bool    isAiCoach;

  const _ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    this.isVoice        = false,
    this.voiceDuration,
    this.voiceUrl,
    this.voiceLocalPath,
    required this.timestamp,
    this.isPending = false,
    this.isAiCoach = false,
  });
}
