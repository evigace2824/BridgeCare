import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/family_models.dart';
import '../../models/user_model.dart';
import '../../widgets/premium_status_card.dart';
import '../premium/premium_gate.dart';
import 'family_job_posts_page.dart';
import 'family_plan_store.dart';
import 'create_job_post_page.dart';
import 'premium_spotlight.dart';

class AddAssistanceRequestDialog extends StatefulWidget {
  final void Function(AssistanceRequest) onSubmit;

  const AddAssistanceRequestDialog({super.key, required this.onSubmit});

  @override
  State<AddAssistanceRequestDialog> createState() => _AddAssistanceRequestDialogState();
}

class _AddAssistanceRequestDialogState extends State<AddAssistanceRequestDialog> {
  RequestType _selectedType = RequestType.groceryShopping;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _scheduledDate = DateTime.now().add(const Duration(days: 1));
  bool _urgent = false;

  static const _primary = Color(0xFF1976D2);

  String _hintForType(RequestType t) {
    switch (t) {
      case RequestType.groceryShopping: return 'e.g. Buy groceries from Conad market';
      case RequestType.medicalVisit: return 'e.g. Cardiology appointment at City Hospital';
      case RequestType.collectPension: return 'e.g. Collect pension from Post Office';
      case RequestType.other: return 'Describe the assistance needed...';
    }
  }

  String _descForType(RequestType t) {
    switch (t) {
      case RequestType.groceryShopping: return 'Volunteer will buy groceries and deliver them';
      case RequestType.medicalVisit: return 'Accompaniment to a medical appointment';
      case RequestType.collectPension: return 'Collect pension from bank or post office';
      case RequestType.other: return 'Any other type of assistance needed';
    }
  }

  IconData _iconForType(RequestType t) {
    switch (t) {
      case RequestType.groceryShopping: return Icons.shopping_cart_rounded;
      case RequestType.medicalVisit: return Icons.local_hospital_rounded;
      case RequestType.collectPension: return Icons.account_balance_rounded;
      case RequestType.other: return Icons.help_outline_rounded;
    }
  }

  Color _colorForType(RequestType t) {
    switch (t) {
      case RequestType.groceryShopping: return const Color(0xFF4CAF50);
      case RequestType.medicalVisit: return const Color(0xFFE53935);
      case RequestType.collectPension: return const Color(0xFF1976D2);
      case RequestType.other: return const Color(0xFF9C27B0);
    }
  }

  String _labelForType(RequestType t) {
    switch (t) {
      case RequestType.groceryShopping: return 'Grocery Shopping';
      case RequestType.medicalVisit: return 'Medical Visit';
      case RequestType.collectPension: return 'Collect Pension';
      case RequestType.other: return 'Other Help';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title for this request.'), backgroundColor: Colors.red),
      );
      return;
    }
    final req = AssistanceRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      title: _urgent ? '🚨 URGENT: $title' : title,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      createdAt: DateTime.now(),
      status: RequestStatus.pending,
    );
    widget.onSubmit(req);
    Navigator.of(context).pop();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _primary)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.volunteer_activism_rounded, color: _primary, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('New Assistance Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
              Text('A volunteer will be assigned to help', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
            ])),
            IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280))),
          ]),
          const SizedBox(height: 20),
          const Text('Type of Help Needed', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: RequestType.values.map((type) {
              final isSelected = _selectedType == type;
              final color = _colorForType(type);
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withAlpha(25) : const Color(0xFFF5F8FB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? color : const Color(0xFFE9ECEF), width: isSelected ? 2 : 1),
                  ),
                  child: Row(children: [
                    Icon(_iconForType(type), color: isSelected ? color : const Color(0xFF9E9E9E), size: 16),
                    const SizedBox(width: 6),
                    Expanded(child: Text(_labelForType(type),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: isSelected ? color : const Color(0xFF6B7280)),
                      overflow: TextOverflow.ellipsis)),
                  ]),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(_descForType(_selectedType),
            style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          const Text('Title *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: _hintForType(_selectedType),
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF5F8FB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          const Text('Notes for the Volunteer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Special instructions, address, preferences...',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF5F8FB),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9ECEF))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primary, width: 2)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          const Text('Preferred Date', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE9ECEF)),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded, color: _primary, size: 16),
                const SizedBox(width: 10),
                Text(DateFormat('EEEE, MMM d, yyyy').format(_scheduledDate),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFADB5BD), size: 18),
              ]),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _urgent ? const Color(0xFFFFEBEE) : const Color(0xFFF5F8FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _urgent ? const Color(0xFFE53935).withAlpha(100) : const Color(0xFFE9ECEF)),
            ),
            child: Row(children: [
              const Icon(Icons.priority_high_rounded, color: Color(0xFFE53935), size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Mark as Urgent', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                Text('Volunteers will be notified immediately', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
              ])),
              Switch(value: _urgent, onChanged: (v) => setState(() => _urgent = v), activeColor: const Color(0xFFE53935)),
            ]),
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.send_rounded, size: 16),
              SizedBox(width: 8),
              Text('Send to Volunteers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ]),
          )),
          const SizedBox(height: 6),
          const Center(child: Text('Visible to all available volunteers in your area', style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)))),
        ]),
      ),
    );
  }
}

class FamilyHomePage extends StatefulWidget {
  final LinkedUser? linkedUser;
  final List<AppAlert> alerts;
  final VoidCallback onCallTap;
  final VoidCallback onLocationTap;
  final VoidCallback onReportTap;
  final VoidCallback onChatTap;
  final void Function(AppAlert) onAlertTap;
  final void Function(Reminder, ReminderStatus) onReminderAction;
  final void Function(int tabIndex)? onFamilyTab;

  const FamilyHomePage({
    super.key,
    required this.linkedUser,
    required this.alerts,
    required this.onCallTap,
    required this.onLocationTap,
    required this.onReportTap,
    required this.onChatTap,
    required this.onAlertTap,
    required this.onReminderAction,
    this.onFamilyTab,
  });

  @override
  State<FamilyHomePage> createState() => _FamilyHomePageState();
}

class _FamilyHomePageState extends State<FamilyHomePage>
    with SingleTickerProviderStateMixin {
  static const _primary = Color(0xFF1976D2);
  static const _green = Color(0xFF4CAF50);
  static const _orange = Color(0xFFFF9800);
  static const _red = Color(0xFFE53935);
  static const _purple = Color(0xFF9C27B0);
  static const _cardColor = Colors.white;
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _textSecondary = Color(0xFF6B7280);
  static const _divider = Color(0xFFE9ECEF);
  static const _shadow = Color(0x121976D2);

  late List<AssistanceRequest> _localRequests;
  late AnimationController _accentPulse;

  @override
  void initState() {
    super.initState();
    _localRequests = List.from(widget.linkedUser?.assistanceRequests ?? []);
    _accentPulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _accentPulse.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FamilyHomePage old) {
    super.didUpdateWidget(old);
    if (old.linkedUser != widget.linkedUser) {
      _localRequests = List.from(widget.linkedUser?.assistanceRequests ?? []);
    }
  }

  String _relativeTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  List<Reminder> get _todayReminders {
    if (widget.linkedUser == null) return [];
    final now = DateTime.now();
    final list = widget.linkedUser!.reminders.where((r) {
      final d = r.scheduledAt;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
    list.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return list;
  }

  void _showAddRequestDialog() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AddAssistanceRequestDialog(
        onSubmit: (req) {
          setState(() => _localRequests.insert(0, req));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Request sent to volunteers!', style: TextStyle(fontWeight: FontWeight.w600)),
              ]),
              backgroundColor: _green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        },
      ),
    );
  }

  void _cancelRequest(AssistanceRequest req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Request?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to cancel "${req.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _localRequests.removeWhere((r) => r.id == req.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Request cancelled'),
                  backgroundColor: _red, behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.linkedUser;
    final unread = widget.alerts.where((a) => !a.isRead).length;
    final activeRequests = _localRequests
        .where((r) => r.status == RequestStatus.pending || r.status == RequestStatus.accepted)
        .toList();
    final doneRequests = _localRequests
        .where((r) => r.status == RequestStatus.completed || r.status == RequestStatus.rejected)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _dashboardHeroAccent(),
        if (user != null && user.healthStatus.type != HealthStatusType.normal)
          _buildStatusBanner(user.healthStatus),
        _buildGreetingCard(user),
        const SizedBox(height: 10),
        _freshnessHintCard(),
        const SizedBox(height: 12),
        const FamilyPremiumSpotlight(angle: SpotlightAngle.alerts),
        const SizedBox(height: 8),
        PremiumStatusCard(
          role: UserRole.family,
          summary: 'Reports · Safe zones · 48h jobs · Priority alerts',
          linkedUser: user,
          onFamilyTab: widget.onFamilyTab,
        ),
        const SizedBox(height: 14),
        if (user != null && (user.heartRateHistory.isNotEmpty || user.bloodPressureHistory.isNotEmpty)) ...[
          _sectionLabel('Latest Vitals'),
          _buildVitalSnapshot(user),
          const SizedBox(height: 14),
        ],
        if (widget.alerts.isNotEmpty) ...[
          _sectionLabel('Alerts', trailing: unread > 0 ? _badge('$unread unread', _red) : null),
          ...widget.alerts.take(3).map((a) => _alertTile(a)),
          const SizedBox(height: 6),
        ],
        _sectionLabel('Quick Actions'),
        Row(children: [
          _quickBtn('Call', Icons.phone_rounded, _green, widget.onCallTap),
          const SizedBox(width: 10),
          _quickBtn('Location', Icons.location_on_rounded, _primary, widget.onLocationTap),
          const SizedBox(width: 10),
          _quickBtn('Chat', Icons.chat_bubble_rounded, _purple, widget.onChatTap),
          const SizedBox(width: 10),
          _quickBtn('Reports', Icons.bar_chart_rounded, _orange, widget.onReportTap),
        ]),
        const SizedBox(height: 14),
        _sectionLabel('Smart Actions'),
        _card(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _smartActionChip(
                label: 'Request check-in',
                icon: Icons.waving_hand_rounded,
                color: _primary,
                onTap: () => _showSmartActionDialog(
                  title: 'Check-in scheduled',
                  message: 'A friendly check-in prompt was sent to ${user?.fullName ?? 'the patient'}.',
                ),
              ),
              _smartActionChip(
                label: 'Medication nudge',
                icon: Icons.medication_rounded,
                color: _orange,
                onTap: () => _showSmartActionDialog(
                  title: 'Reminder sent',
                  message: 'Medication reminder was prioritized for the next 15 minutes.',
                ),
              ),
              _smartActionChip(
                label: 'Wellness tip',
                icon: Icons.lightbulb_rounded,
                color: _green,
                onTap: () => _showSmartActionDialog(
                  title: 'Tip delivered',
                  message: 'A hydration and movement tip was pushed to the patient app.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _sectionLabel('Activity'),
        _card(child: Column(children: [
          _activityRow(Icons.access_time_rounded, 'Last Seen', _relativeTime(user?.lastSeen), _primary),
          const Divider(height: 16, color: _divider),
          _activityRow(Icons.phone_rounded, 'Last Call', _relativeTime(user?.lastCall), _green),
          const Divider(height: 16, color: _divider),
          _activityRow(Icons.location_on_rounded, 'Location',
            user?.currentLocation != null ? 'Live position active' : 'Not sharing', _orange),
        ])),
        const SizedBox(height: 14),
        _sectionLabel("Today's Reminders",
          trailing: _todayReminders.isNotEmpty ? _badge('${_todayReminders.length} today', _primary) : null),
        _todayReminders.isEmpty
            ? _emptyState(Icons.alarm_off_rounded, 'No reminders for today')
            : Column(children: _todayReminders.map(_reminderTile).toList()),
        const SizedBox(height: 14),
        _sectionLabel('Assistance Requests',
  trailing: GestureDetector(
    onTap: _showAddRequestDialog,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_rounded, color: Colors.white, size: 14),
          SizedBox(width: 4),
          Text(
            'Add Request',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    ),
  ),
),

activeRequests.isEmpty
    ? SizedBox(
        width: double.infinity,
        child: _emptyState(
          Icons.volunteer_activism_rounded,
          'No active requests\nTap "Add Request" to ask for volunteer help',
        ),
      )
    : Column(
        mainAxisSize: MainAxisSize.min,
        children: activeRequests.map(_requestTile).toList(),
      ),

const SizedBox(height: 10),
_postJobCTA(context),
const SizedBox(height: 10),

ListenableBuilder(
  listenable: FamilyPlanStore.instance,
  builder: (context, _) {
    final premium = FamilyPlanStore.instance.plan.familyJobPostingUnlocked;
    return ElevatedButton.icon(
      onPressed: () {
        if (premium) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FamilyJobPostsPage()),
          );
        } else {
          PremiumGate.requirePremium(
            context,
            role: UserRole.family,
            featureName: '48-hour job posting',
            onUnlocked: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FamilyJobPostsPage()),
            ),
          );
        }
      },
      icon: Icon(premium ? Icons.work_history_rounded : Icons.lock_outline_rounded),
      label: Text(premium ? 'My job posts' : 'My job posts (Premium)'),
    );
  },
),
if (doneRequests.isNotEmpty) ...[
  const SizedBox(height: 14),
  _sectionLabel('Past Requests'),
  Column(
    mainAxisSize: MainAxisSize.min,
    children: doneRequests
        .take(3)
        .map(_requestTileCompleted)
        .toList(),
  ),
],]),
    );
  }

  Widget _buildStatusBanner(HealthStatus s) {
    final isEmergency = s.type == HealthStatusType.emergency;
    final color = isEmergency ? _red : _orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(30), shape: BoxShape.circle),
          child: Icon(isEmergency ? Icons.emergency_rounded : Icons.warning_amber_rounded, color: color, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isEmergency ? '🚨 Emergency Alert' : '⚠️ Health Warning',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(s.description, style: const TextStyle(fontSize: 12, color: _textSecondary)),
        ])),
        if (isEmergency)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _red, borderRadius: BorderRadius.circular(8)),
            child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ),
      ]),
    );
  }

  Widget _dashboardHeroAccent() {
    return AnimatedBuilder(
      animation: _accentPulse,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_accentPulse.value);
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: const [
                      Color(0xFF133A63),
                      Color(0xFF1976D2),
                      Color(0xFF24B6A8),
                      Color(0xFFB39DDB),
                    ],
                    stops: [
                      (0.05 + t * 0.12).clamp(0.0, 0.95),
                      (0.32 + t * 0.08).clamp(0.0, 0.98),
                      (0.58 + t * 0.1).clamp(0.0, 1.0),
                      1.0,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF24B6A8).withValues(alpha: 0.38),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF24B6A8).withValues(alpha: 0.2),
                          const Color(0xFF1976D2).withValues(alpha: 0.15),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF24B6A8).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF133A63),
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your live care hub — vitals, alerts & actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F2A4D),
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _freshnessHintCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            const Color(0xFFEAF4FF).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: const Color(0xFFC5DDF0).withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF133A63).withValues(alpha: 0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: _primary.withValues(alpha: 0.9),
            size: 22,
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Swipe down anywhere on this screen to refresh.',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3D5A73),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Volunteer-style hero card: deep navy → teal gradient with a verified
  /// pill, brand-accent halo around the avatar, and a clean two-line stat row.
  Widget _buildGreetingCard(LinkedUser? user) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2A4D), Color(0xFF1F5DA0), Color(0xFF24B6A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF24B6A8).withValues(alpha: 0.25),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with brand-accent halo
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF24B6A8).withValues(alpha: 0.45),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _avatar(user?.fullName ?? '?', size: 54),
                  ),
                  if (user != null)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2A4D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.favorite_rounded,
                          color: Color(0xFFFF8AB1),
                          size: 11,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.30),
                        ),
                      ),
                      child: const Text(
                        'CARE TEAM',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user?.fullName ?? 'No patient linked',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'You are connected as their family caregiver',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    if (user != null) _statusBadgeOnDark(user.healthStatus),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      DateFormat('EEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        color: Color(0xFF0F2A4D),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (user?.phoneNumber.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phone_rounded,
                            color: Colors.white70, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          user!.phoneNumber,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniStatCard(Icons.phone_rounded, 'Last Call',
                  _relativeTime(user?.lastCall)),
              const SizedBox(width: 10),
              _miniStatCard(Icons.visibility_rounded, 'Last Seen',
                  _relativeTime(user?.lastSeen)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(IconData icon, String label, String value) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 14),
        const SizedBox(width: 6),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: Colors.white.withAlpha(160), fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis),
        ])),
      ]),
    ),
  );

  Widget _buildVitalSnapshot(LinkedUser user) => _card(
    child: Column(children: [
      if (user.heartRateHistory.isNotEmpty) ...[
        _vitalRow(Icons.favorite_rounded, 'Heart Rate',
          '${user.heartRateHistory.last.value.round()} bpm', _red,
          _heartRateStatus(user.heartRateHistory.last.value)),
      ],
    ]),
  );

  String _heartRateStatus(double bpm) {
    if (bpm < 60) return 'Low';
    if (bpm > 100) return 'High';
    return 'Normal';
  }

  Widget _vitalRow(IconData icon, String label, String value, Color color, String status) {
    final statusColor = status == 'Normal' ? _green : _orange;
    return Row(children: [
      Container(width: 36, height: 36,
        decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: _textSecondary)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textPrimary)),
      ])),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: statusColor.withAlpha(25), borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withAlpha(80))),
        child: Text(status, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold)),
      ),
    ]);
  }

  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.97),
              const Color(0xFFF3F8FD),
            ],
          ),
          border: Border.all(
            color: const Color(0xFFD8E6F2).withValues(alpha: 0.9),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF133A63).withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.9),
              blurRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      );

  Widget _smartActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _TapScale(
      onTapDown: HapticFeedback.lightImpact,
      child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withAlpha(40), color.withAlpha(20)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: color.withAlpha(110), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: color.withAlpha(110),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 14, color: Colors.white),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showSmartActionDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Great'),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String msg) => _card(
    child: Center(child: Padding(padding: const EdgeInsets.all(12),
      child: Column(children: [
        Icon(icon, color: const Color(0xFFD1D5DB), size: 32),
        const SizedBox(height: 8),
        Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: _textSecondary, fontSize: 12)),
      ]))));

  Widget _avatar(String name, {double size = 40}) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: Colors.white.withAlpha(40),
      border: Border.all(color: Colors.white.withAlpha(100), width: 2),
      shape: BoxShape.circle),
    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: TextStyle(color: Colors.white, fontSize: size * 0.4, fontWeight: FontWeight.bold))));

  Widget _statusBadgeOnDark(HealthStatus s) {
    final color = s.type == HealthStatusType.emergency ? _red
        : s.type == HealthStatusType.warning ? _orange : _green;
    final icon = s.type == HealthStatusType.emergency ? Icons.emergency_rounded
        : s.type == HealthStatusType.warning ? Icons.warning_amber_rounded
        : Icons.check_circle_rounded;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(s.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
      ]));
  }

  Widget _sectionLabel(String text, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(children: [
      Container(
        width: 5,
        height: 20,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF24B6A8), Color(0xFF1FA59A)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF24B6A8).withValues(alpha: 0.30),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F2A4D),
            letterSpacing: -0.2,
          ),
        ),
      ),
      ?trailing,
    ]));

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color.withAlpha(80))),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)));

  Widget _alertTile(AppAlert a) {
    final color = a.severity == AlertSeverity.critical ? _red
        : a.severity == AlertSeverity.warning ? _orange : _primary;
    return GestureDetector(
      onTap: () => widget.onAlertTap(a),
      child: AnimatedOpacity(
        opacity: a.isRead ? 0.55 : 1.0, duration: const Duration(milliseconds: 250),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withAlpha(12), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(50))),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withAlpha(25), shape: BoxShape.circle),
              child: Icon(a.severity == AlertSeverity.critical ? Icons.emergency_rounded
                  : a.severity == AlertSeverity.warning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                color: color, size: 16)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: color)),
              const SizedBox(height: 2),
              Text(a.message, style: const TextStyle(fontSize: 12, color: _textSecondary)),
              const SizedBox(height: 2),
              Text(_relativeTime(a.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFFADB5BD))),
            ])),
            if (!a.isRead) Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          ]),
        ),
      ),
    );
  }

  Widget _quickBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [color, Color.lerp(color, Colors.white, 0.18)!],
    );
    return Expanded(
      child: _TapScale(
        onTapDown: HapticFeedback.selectionClick,
        child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withAlpha(80),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(60),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _activityRow(IconData icon, String label, String value, Color color) => Row(children: [
    Container(width: 32, height: 32,
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: color, size: 16)),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: _textSecondary))),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
  ]);

  Widget _reminderTile(Reminder r) {
    final isDone = r.status == ReminderStatus.done;
    final isMissed = r.status == ReminderStatus.missed;
    final color = isDone ? _green : isMissed ? _red : _primary;
    final icon = r.type == ReminderType.medication ? Icons.medication_rounded
        : r.type == ReminderType.appointment ? Icons.calendar_today_rounded
        : Icons.notifications_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, 3))]),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
            color: isDone ? _textSecondary : _textPrimary,
            decoration: isDone ? TextDecoration.lineThrough : null)),
          Row(children: [
            Icon(Icons.schedule_rounded, size: 11, color: _textSecondary),
            const SizedBox(width: 3),
            Text(DateFormat('h:mm a').format(r.scheduledAt), style: const TextStyle(fontSize: 11, color: _textSecondary)),
            if (r.description != null) ...[
              const SizedBox(width: 6),
              Expanded(child: Text('· ${r.description!}', style: const TextStyle(fontSize: 11, color: _textSecondary),
                overflow: TextOverflow.ellipsis)),
            ],
          ]),
        ])),
        const SizedBox(width: 8),
        if (!isDone && !isMissed)
          Row(children: [
            _miniBtn('Done', _green, () => widget.onReminderAction(r, ReminderStatus.done)),
            const SizedBox(width: 6),
            _miniBtn('Skip', _orange, () => widget.onReminderAction(r, ReminderStatus.missed)),
          ])
        else
          _badge(isDone ? '✓ Done' : '✗ Missed', color),
      ]),
    );
  }

  Widget _miniBtn(String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(60))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))));

  Widget _requestTile(AssistanceRequest req) {
    final isPending = req.status == RequestStatus.pending;
    final color = req.status == RequestStatus.accepted ? _green : _orange;
    final icon = _iconForType(req.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(40)),
        boxShadow: const [BoxShadow(color: _shadow, blurRadius: 10, offset: Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(req.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _textPrimary)),
            Text(_labelForType(req.type), style: const TextStyle(fontSize: 11, color: _textSecondary)),
          ])),
          _statusChip(req.status),
        ]),
        if (req.notes != null) ...[
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFF5F8FB), borderRadius: BorderRadius.circular(8)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.notes_rounded, size: 12, color: _textSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(req.notes!, style: const TextStyle(fontSize: 12, color: _textSecondary))),
            ])),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Icon(Icons.schedule_rounded, size: 11, color: _textSecondary),
          const SizedBox(width: 4),
          Text(_relativeTime(req.createdAt), style: const TextStyle(fontSize: 11, color: _textSecondary)),
          const Spacer(),
          if (req.assignedVolunteerName != null) ...[
            const Icon(Icons.person_rounded, size: 12, color: _green),
            const SizedBox(width: 4),
            Text(req.assignedVolunteerName!, style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
          ],
          if (isPending)
            GestureDetector(
              onTap: () => _cancelRequest(req),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _red.withAlpha(15), borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _red.withAlpha(60))),
                child: const Text('Cancel', style: TextStyle(fontSize: 11, color: _red, fontWeight: FontWeight.bold)),
              ),
            ),
        ]),
      ]),
    );
  }

  Widget _requestTileCompleted(AssistanceRequest req) {
    final isDone = req.status == RequestStatus.completed;
    final color = isDone ? _green : _red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: color.withAlpha(8), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(30))),
      child: Row(children: [
        Icon(_iconForType(req.type), color: color.withAlpha(150), size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(req.title, style: TextStyle(fontSize: 13, color: _textSecondary,
            decoration: isDone ? TextDecoration.lineThrough : null)),
          Text(_relativeTime(req.createdAt), style: const TextStyle(fontSize: 10, color: Color(0xFFADB5BD))),
        ])),
        _statusChip(req.status),
      ]),
    );
  }

  Widget _statusChip(RequestStatus status) {
    final label = switch (status) {
      RequestStatus.pending => 'Pending',
      RequestStatus.accepted => 'Accepted',
      RequestStatus.completed => '✓ Done',
      RequestStatus.rejected => 'Rejected',
    };
    final color = switch (status) {
      RequestStatus.pending => _orange,
      RequestStatus.accepted => _green,
      RequestStatus.completed => _green,
      RequestStatus.rejected => _red,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(80))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)));
  }

  IconData _iconForType(RequestType type) => switch (type) {
    RequestType.groceryShopping => Icons.shopping_cart_rounded,
    RequestType.medicalVisit => Icons.local_hospital_rounded,
    RequestType.collectPension => Icons.account_balance_rounded,
    RequestType.other => Icons.help_outline_rounded,
  };

  String _labelForType(RequestType type) => switch (type) {
    RequestType.groceryShopping => 'Grocery Shopping',
    RequestType.medicalVisit => 'Medical Visit',
    RequestType.collectPension => 'Collect Pension',
    RequestType.other => 'Other Help',
  };

  Widget _postJobCTA(BuildContext context) {
    return ListenableBuilder(
      listenable: FamilyPlanStore.instance,
      builder: (context, _) {
        final premium =
            FamilyPlanStore.instance.plan.familyJobPostingUnlocked;
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: premium
                  ? const [Color(0xFF5B21B6), Color(0xFF7C3AED)]
                  : const [Color(0xFF1976D2), Color(0xFF1565C0)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    premium
                        ? Icons.workspace_premium_rounded
                        : Icons.lock_rounded,
                    color: const Color(0xFFFFB300),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      premium
                          ? 'Post a care job (48h)'
                          : 'Premium: 48-hour job posting',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                premium
                    ? 'Reach qualified volunteers — your post stays active for 48 hours.'
                    : 'Unlock to post jobs that alert nearby volunteers for 48 hours.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (premium) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateJobPostPage(
                            linkedUser: widget.linkedUser,
                          ),
                        ),
                      );
                    } else {
                      PremiumGate.requirePremium(
                        context,
                        role: UserRole.family,
                        featureName: '48-hour job posting',
                        onUnlocked: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CreateJobPostPage(
                            linkedUser: widget.linkedUser,
                          ),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor:
                        premium ? const Color(0xFF5B21B6) : Colors.black87,
                  ),
                  child: Text(premium ? 'Create job post' : 'Upgrade to post'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
    }
    class _TapScale extends StatefulWidget {
  const _TapScale({
    required this.child,
    this.onTapDown,
  });

  final Widget child;
  final VoidCallback? onTapDown;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) {
        widget.onTapDown?.call();
        setState(() => _pressed = true);
      },
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}