import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../services/reminder_sync_service.dart';
import '../../../../utils/user_feedback.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';

/// Full-screen form: title, type, date, time, notes, repeat, save.
class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  ReminderKind _kind = ReminderKind.medication;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  ReminderRepeat _repeat = ReminderRepeat.none;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter a reminder title.'))),
      );
      return;
    }
    final at = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    final addedMsg = context.tr('Reminder added.');
    final syncMsg = context.tr(
      'Saved on this device. Could not sync to the cloud.',
    );
    final created = PatientStore.instance.addReminder(
      kind: _kind,
      title: title,
      scheduledAt: at,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      repeat: _repeat,
    );
    final synced = await ReminderSyncService.instance.tryInsert(created);
    if (!mounted) return;
    UserFeedback.showSuccess(context, addedMsg);
    final loggedIn = Supabase.instance.client.auth.currentUser != null;
    if (!synced && loggedIn) {
      UserFeedback.showWarning(context, syncMsg);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr('Add reminder'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: context.tr('Reminder title'),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Reminder type'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReminderKind>(
              segments: [
                ButtonSegment(
                  value: ReminderKind.medication,
                  label: Text(context.tr('Medication')),
                  icon: const Icon(Icons.medication_rounded),
                ),
                ButtonSegment(
                  value: ReminderKind.appointment,
                  label: Text(context.tr('Appointment')),
                  icon: const Icon(Icons.event_rounded),
                ),
                ButtonSegment(
                  value: ReminderKind.dailyTask,
                  label: Text(context.tr('Daily task')),
                  icon: const Icon(Icons.task_alt_rounded),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Date')),
              subtitle: Text(
                '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.calendar_today_rounded),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('Time')),
              subtitle: Text(
                _time.format(context),
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              trailing: const Icon(Icons.access_time_rounded),
              onTap: _pickTime,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.tr('Notes (optional)'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Repeat'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReminderRepeat>(
              value: _repeat,
              decoration: const InputDecoration(),
              items: [
                DropdownMenuItem(
                  value: ReminderRepeat.none,
                  child: Text(context.tr('Does not repeat')),
                ),
                DropdownMenuItem(
                  value: ReminderRepeat.daily,
                  child: Text(context.tr('Every day')),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _repeat = v ?? ReminderRepeat.none),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 54,
              child: ElevatedButton(
                onPressed: _save,
                child: Text(context.tr('Save reminder')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
