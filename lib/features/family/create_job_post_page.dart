import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/family_models.dart';
import '../../models/job_post_model.dart';
import '../../models/user_model.dart';
import '../../services/job_post_service.dart';
import '../premium/premium_gate.dart';
import 'family_plan_store.dart';

/// Premium-only form: post a care job active for 48 hours for a linked elderly user.
class CreateJobPostPage extends StatefulWidget {
  const CreateJobPostPage({super.key, this.linkedUser});

  final LinkedUser? linkedUser;

  @override
  State<CreateJobPostPage> createState() => _CreateJobPostPageState();
}

class _CreateJobPostPageState extends State<CreateJobPostPage> {
  static const _purple = Color(0xFF7C3AED);
  static const _bg = Color(0xFFF5F8FC);

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: '4 hours');
  final _budgetCtrl = TextEditingController();

  String _careType = JobPostCareTypes.elderlyCare;
  JobUrgency _urgency = JobUrgency.medium;
  DateTime _preferredAt = DateTime.now().add(const Duration(hours: 4));
  bool _submitting = false;

  static const _durations = ['2 hours', '4 hours', '6 hours', '8 hours', 'Full day'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _durationCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _preferredAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_preferredAt),
    );
    if (time == null) return;
    setState(() {
      _preferredAt = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _descCtrl.text.trim().isEmpty ||
        _locationCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all required fields')),
      );
      return;
    }
    if (widget.linkedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link an elderly user before posting a job')),
      );
      return;
    }

    setState(() => _submitting = true);
    final userId =
        Supabase.instance.client.auth.currentUser?.id ?? 'family_local';
    final meta = Supabase.instance.client.auth.currentUser?.userMetadata;
    final familyName = meta?['full_name']?.toString() ?? 'Family';

    await JobPostService.instance.createPost(
      title: _titleCtrl.text.trim(),
      careType: _careType,
      description: _descCtrl.text.trim(),
      location: _locationCtrl.text.trim(),
      preferredAt: _preferredAt,
      durationLabel: _durationCtrl.text.trim(),
      urgency: _urgency,
      budget: _budgetCtrl.text.trim().isEmpty ? null : _budgetCtrl.text.trim(),
      createdBy: userId,
      linkedElderlyUserId: widget.linkedUser!.uid,
      linkedElderlyName: widget.linkedUser!.fullName,
      familyDisplayName: familyName,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    HapticFeedback.mediumImpact();
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (!FamilyPlanStore.instance.plan.familyJobPostingUnlocked) {
      return _lockedView(context);
    }

    final linked = widget.linkedUser;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Post care job'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _banner(),
          if (linked != null) _linkedUserCard(linked),
          const SizedBox(height: 16),
          _section('Job title *', _field(_titleCtrl, 'e.g. Afternoon companion visit', Icons.title_rounded)),
          const SizedBox(height: 14),
          _section('Care type *', _careTypeDropdown()),
          const SizedBox(height: 14),
          _section('Description *', _field(_descCtrl, 'What help is needed?', Icons.notes_rounded, maxLines: 4)),
          const SizedBox(height: 14),
          _section('Location / address *', _field(_locationCtrl, 'Street, city', Icons.place_rounded)),
          const SizedBox(height: 14),
          _dateTimeRow(),
          const SizedBox(height: 14),
          _section('Duration', _durationChips()),
          const SizedBox(height: 14),
          _section('Urgency', _urgencyChips()),
          const SizedBox(height: 14),
          _section('Budget (optional)', _field(_budgetCtrl, 'e.g. €50 or negotiable', Icons.payments_outlined)),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_submitting ? 'Posting…' : 'Post job — active 48 hours'),
              style: FilledButton.styleFrom(
                backgroundColor: _purple,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lockedView(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post care job')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_rounded, size: 56, color: _purple),
              const SizedBox(height: 16),
              const Text('Premium feature',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text(
                '48-hour job posting lets verified volunteers apply for care help '
                'for your linked loved one. You review applications and choose who to accept.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () =>
                    PremiumGate.openPlans(context, UserRole.family),
                style: FilledButton.styleFrom(backgroundColor: _purple),
                child: const Text('Upgrade to Premium'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.timer_rounded, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Volunteers are notified immediately. Your post stays live for 48 hours.',
              style: TextStyle(color: Colors.white, fontSize: 12, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkedUserCard(LinkedUser user) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: _purple.withValues(alpha: 0.12),
            child: Text(
              user.fullName.isNotEmpty ? user.fullName[0] : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: _purple),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Linked care recipient',
                    style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w600)),
                Text(user.fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
          ),
          const Icon(Icons.link_rounded, color: _purple, size: 20),
        ],
      ),
    );
  }

  Widget _section(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _field(TextEditingController c, String hint, IconData icon,
      {int maxLines = 1}) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: _purple),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _careTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _careType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      items: JobPostCareTypes.all
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => setState(() => _careType = v ?? _careType),
    );
  }

  Widget _dateTimeRow() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: const Icon(Icons.event_rounded, color: _purple),
        title: const Text('Preferred date & time',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${_preferredAt.day}/${_preferredAt.month}/${_preferredAt.year} '
          '${_preferredAt.hour.toString().padLeft(2, '0')}:'
          '${_preferredAt.minute.toString().padLeft(2, '0')}',
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: _pickDateTime,
      ),
    );
  }

  Widget _durationChips() {
    return Wrap(
      spacing: 8,
      children: _durations.map((d) {
        final sel = _durationCtrl.text == d;
        return ChoiceChip(
          label: Text(d),
          selected: sel,
          onSelected: (_) => setState(() => _durationCtrl.text = d),
          selectedColor: _purple.withValues(alpha: 0.2),
        );
      }).toList(),
    );
  }

  Widget _urgencyChips() {
    return Wrap(
      spacing: 8,
      children: [
        (JobUrgency.low, 'Low'),
        (JobUrgency.medium, 'Medium'),
        (JobUrgency.high, 'High'),
        (JobUrgency.urgent, 'Urgent'),
      ].map((e) {
        return ChoiceChip(
          label: Text(e.$2),
          selected: _urgency == e.$1,
          onSelected: (_) => setState(() => _urgency = e.$1),
          selectedColor: _purple.withValues(alpha: 0.2),
        );
      }).toList(),
    );
  }
}
