import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../models/job_post_model.dart';
import '../../../models/volunteer_care_profile.dart';
import '../../../services/job_post_service.dart';
import '../data/volunteer_store.dart';
import 'volunteer_care_profile_card.dart';
import 'volunteer_theme.dart';

/// Short application form — care profile + message (no CV upload).
class JobApplySheet extends StatefulWidget {
  const JobApplySheet({super.key, required this.job});

  final JobPostModel job;

  static Future<bool?> show(BuildContext context, JobPostModel job) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobApplySheet(job: job),
    );
  }

  @override
  State<JobApplySheet> createState() => _JobApplySheetState();
}

class _JobApplySheetState extends State<JobApplySheet> {
  final _messageCtrl = TextEditingController();
  bool _availabilityConfirmed = false;
  bool _submitting = false;
  late String _transport;

  String get _volunteerId =>
      Supabase.instance.client.auth.currentUser?.id ?? 'volunteer_local';

  @override
  void initState() {
    super.initState();
    _transport = VolunteerStore.instance.transport;
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageCtrl.text.trim().length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a short message (at least 12 characters)'),
        ),
      );
      return;
    }
    if (!_availabilityConfirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm you are available for this job'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final store = VolunteerStore.instance;
    final profile = VolunteerCareProfile.fromStore(
      store,
      volunteerId: _volunteerId,
    );

    await JobPostService.instance.applyForJob(
      postId: widget.job.id,
      careProfile: profile,
      suitabilityMessage: _messageCtrl.text.trim(),
      availabilityConfirmed: _availabilityConfirmed,
      transportMethod: _transport,
    );

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final store = VolunteerStore.instance;
    final profile = VolunteerCareProfile.fromStore(
      store,
      volunteerId: _volunteerId,
    );
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FB),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Apply for Job',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                shrinkWrap: true,
                children: [
                  Text(
                    widget.job.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: VolunteerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your Care Profile',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: VolunteerTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  VolunteerCareProfileCard(profile: profile, compact: true),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Why are you suitable?',
                      hintText:
                          'Brief experience with this type of care, languages, etc.',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _transport,
                    decoration: InputDecoration(
                      labelText: 'Transport method',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: const [
                      'On foot',
                      'Bicycle',
                      'Public transit',
                      'Car',
                      'Scooter',
                    ]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => _transport = v ?? _transport),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    value: _availabilityConfirmed,
                    onChanged: (v) =>
                        setState(() => _availabilityConfirmed = v == true),
                    title: const Text(
                      'I confirm I am available for the preferred time',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Sending…' : 'Submit application'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
