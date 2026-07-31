import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

/// Care Coach: contextual chat replies for the family dashboard.
///
/// - **Offline / no key:** rule-based “AI style” answers tuned for caregiving.
/// - **With API key:** pass at build time
///   `flutter run --dart-define=OPENAI_API_KEY=sk-...`
///   optional `--dart-define=OPENAI_MODEL=gpt-4o-mini`
class CareCoachChatAssistant {
  CareCoachChatAssistant._();

  /// Messages from the coach use this synthetic id (never a real Supabase user).
  static const String syntheticSenderId = '__care_bridge_coach__';

  static String recipientFirstName(String fullName) {
    final t = fullName.trim();
    if (t.isEmpty) return 'your loved one';
    final sp = t.split(RegExp(r'\s+'));
    return sp.first;
  }

  static Future<String> composeReplyAsync({
    required String message,
    required String recipientName,
    bool voiceNote = false,
    int conversationTurn = 0,
  }) async {
    const apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
    if (apiKey.isEmpty) {
      return composeReply(
        message: message,
        recipientName: recipientName,
        voiceNote: voiceNote,
        conversationTurn: conversationTurn,
      );
    }

    final model = const String.fromEnvironment(
      'OPENAI_MODEL',
      defaultValue: 'gpt-4o-mini',
    );
    final userContent = voiceNote
        ? 'The family member sent a voice note (you cannot hear audio). '
            'Reply with a short, warm follow-up they could send or say next, '
            'and one gentle check-in question about $recipientName.'
        : message;

    try {
      final res = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are BridgeCare Care Coach, a caring assistant for '
                      'family caregivers. Their care recipient is named $recipientName. '
                      'Reply in at most 3 short sentences. No medical diagnosis; '
                      'encourage professional care when needed. Be warm and practical.',
                },
                {'role': 'user', 'content': userContent},
              ],
              'max_tokens': 220,
            }),
          )
          .timeout(const Duration(seconds: 28));

      if (res.statusCode == 200) {
        final text = _extractChatCompletionContent(res.body);
        if (text != null && text.trim().isNotEmpty) return text.trim();
      }
    } catch (_) {
      // fall through to local engine
    }

    return composeReply(
      message: message,
      recipientName: recipientName,
      voiceNote: voiceNote,
      conversationTurn: conversationTurn,
    );
  }

  static String? _extractChatCompletionContent(String body) {
    try {
      final map = jsonDecode(body) as Map<String, dynamic>;
      final choices = map['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) return null;
      final first = choices[0] as Map<String, dynamic>?;
      final msg = first?['message'] as Map<String, dynamic>?;
      return msg?['content'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Local, contextual reply (no network).
  static String composeReply({
    required String message,
    required String recipientName,
    bool voiceNote = false,
    int conversationTurn = 0,
  }) {
    final rnd = Random(
      message.hashCode ^ conversationTurn ^ DateTime.now().minute,
    );
    String pick(List<String> xs) =>
        xs.isEmpty ? '' : xs[rnd.nextInt(xs.length)];

    final name = recipientName.isEmpty ? 'your loved one' : recipientName;

    if (voiceNote) {
      return pick([
        'I “heard” your voice note—thank you for taking a moment to connect. '
            'You could follow up by asking $name how their energy is today, or if anything felt confusing with meds or meals.',
        'Voice notes are great for warmth. Next, try one clear question—like whether $name slept well or needs anything from the pharmacy.',
        'Thanks for the voice message. A simple next step: reassure $name you are a call away, and ask if there is one small thing that would make today easier.',
      ]);
    }

    final raw = message.trim().toLowerCase();
    if (raw.isEmpty) {
      return pick([
        'I am here to help you think through what to say or do next. '
            'What is on your mind about $name today?',
        'Tell me a bit more—are you checking in, worried about something, or planning a visit?',
      ]);
    }

    final norm = raw
        .replaceAll(RegExp(r"[^a-z0-9?\s']"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    bool has(String token) {
      final w = RegExp(r'\b' + RegExp.escape(token) + r'\b');
      return w.hasMatch(norm) || norm.contains(token);
    }

    // Order: most specific / safety-first first.
    if (has('911') ||
        has('emergency') ||
        has('ambulance') ||
        norm.contains('chest pain') ||
        norm.contains('cannot breathe') ||
        norm.contains('cant breathe') ||
        has('fall') ||
        has('fell')) {
      return pick([
        'If $name may be in danger or has new severe symptoms, please use your local '
            'emergency number right away—I can still help with what to tell dispatch. '
            'Are they awake and breathing normally right now?',
        'Safety comes first: if this feels urgent (fall, confusion, breathing trouble), '
            'call emergency services now. Afterwards, note the time and what changed so the doctor has details.',
      ]);
    }

    if (has('help') &&
        (has('need') ||
            has('please') ||
            has('stress') ||
            has('worried'))) {
      return pick([
        'It is okay that this weighs on you. A simple plan: pause, breathe, '
            'then pick one doable step—calling $name check-in text, meds review, '
            'or scheduling a clinician call. Which feels most pressing?',
        'You are doing more than you think. For today, choose one kindness for yourself '
            'and one for $name (even five minutes counts). Want ideas for wording a gentle text?',
      ]);
    }

    if (has('medic') ||
        has('pill') ||
        has('tablet') ||
        has('prescription') ||
        has('dose')) {
      return pick([
        'Med routines are easier with the same cues every day—a meal anchor, alarms, '
            'or pill boxes labeled by time. If doses were missed or doubled, nurse/doctor lines can advise quickly.'
            '\nWould you like a short script to ask $name if they felt any side effects?',
        'Rather than debating from memory, a written list dated today helps clinicians. '
            'If $name sounded unsure, calmly review name, dose time, one question at a time.',
      ]);
    }

    if (has('doctor') ||
        has('clinic') ||
        has('hospital') ||
        has('appointment')) {
      return pick([
        'Before the visit jot 3 bullets: symptoms, meds list, questions. Offer to join $name virtually or speakerphone if they forget details.'
            '\nAnything you want role-played beforehand?',
        'Transitions after appointments confuse many families. Plan a snack, rest, '
            'and one follow-up note with next steps—for $name and for you.',
      ]);
    }

    if (norm.contains('how are') && has('feel')) {
      return pick([
        '$name might answer with mood, sleep, appetite, energy, worry—listening matters more than solving. '
            'You could mirror: “That sounds tiring—what would feel a little lighter today?”',
        'Feelings fluctuate near older age; validate first. Invite specifics gently: pains, dizziness, loneliness, joy moments.',
      ]);
    }

    if (has('lonely') ||
        has('sad') ||
        has('depress') ||
        has('anxious') ||
        has('scared')) {
      return pick([
        'When someone sounds low stay curious, not corrective. Quiet company, rituals, daylight, walks if safe help mood.'
            '\nPersistent hopelessness warrants a clinician—for $name and for caregiver burnout too.',
        '$name deserves patience. Small routines (tea at three, weekly call) reassure nervous systems.'
            '\nWould a short voicemail script cheer them without sounding pushy?',
      ]);
    }

    if (has('sleep') ||
        has('tired') ||
        has('exhaust')) {
      return pick([
        'Sleep troubles often ripple from meds, fluids after dinner, caffeine, aches, worries. Gentle wind-down rhythms help.'
            '\nNotice pattern three nights vs one night?',
        'If $name wakes often, jot times for the doctor—not to fix blame. Daytime light walks can deepen night sleep safely.',
      ]);
    }

    if (has('eat') ||
        has('food') ||
        has('meal') ||
        has('hungry') ||
        has('appetite')) {
      return pick([
        'Appetite shifts are common; hydration first. Colorful small plates less overwhelming than big meals.'
            '\nAny swallowing changes or weight loss recently?',
        'Pair eating with social anchor—video call, favorite music. If skips stack, clinician can screen simple causes.',
      ]);
    }

    if (has('pain') ||
        has('hurt') ||
        has('ache')) {
      return pick([
        'Note location intensity 1–10 rhythm (constant vs intermittent). OTC advice needs clinician if new or sharp.'
            '\nComfort measures: repositioning warmth timed breathing.',
        'Pain can mask mood dips. Invite $name narrate calmly; escalate red flags urgently.',
      ]);
    }

    if (has('love') ||
        has('miss') ||
        has('hug') ||
        has('thinking')) {
      return pick([
        'Warm connection protects health. Mention a shared memory—you light up theirs without pressure.',
        'Simple language lands: “I love you—I am proud of how you handled today.”',
      ]);
    }

    if (has('thank')) {
      return pick([
        'You are welcome. Care loops need gentleness—for $name toward you too.',
        'Gratitude resets stress—keep savoring wins even tiny hydration walk humor.',
      ]);
    }

    if (has('hi') ||
        has('hello') ||
        has('hey') ||
        has('good morning') ||
        has('good afternoon') ||
        has('good evening')) {
      return pick([
        'Hey—thanks for popping in here. Shall we brainstorm a thoughtful check-in for $name?',
        'Hello—I am tuned for caregiver micro-decisions errands wording boundary setting—what fits now?',
      ]);
    }

    if (norm.contains('?')) {
      return pick([
        'Good question. If you share a bit more context about $name’s day I can suggest phrasing or next steps without overstepping medical lines.',
        'I want to be precise—are you asking about safety mood logistics or something medical-adjacent?',
      ]);
    }

    // Default: acknowledge + invite depth (turn-based variety)
    return pick([
      'I am with you. For $name, consistency beats intensity—short daily touchpoints add up.'
          '\nWhat did you notice in their voice or energy last time you connected?',
      'Thanks for sharing that. Reframe one worry into one experiment for the week—hydration walk med-time photo—then review.'
          '\nWhich feels realistic?',
      'Caregiving language benefits from calm curiosity. Try open prompts: “What felt easiest today? What would help tomorrow?”'
          '\nWant me to tailor lines to $name’s personality?',
      if (conversationTurn > 2)
        'We have been going back and forth—if fatigued micro-pause still counts. '
            'What single sentence would reassure $name tonight?',
    ]);
  }
}
