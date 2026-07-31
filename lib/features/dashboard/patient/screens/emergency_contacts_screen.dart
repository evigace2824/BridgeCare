import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../utils/user_feedback.dart';
import '../data/patient_models.dart';
import '../data/patient_store.dart';

/// Full-screen emergency contacts: list by priority, add contact.
class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          context.tr('Emergency contacts'),
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListenableBuilder(
        listenable: PatientStore.instance,
        builder: (context, _) {
          final store = PatientStore.instance;
          final list = List<EmergencyContact>.from(store.contacts)
            ..sort((a, b) => a.priority.compareTo(b.priority));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                context.tr('Manage who is called first'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              for (final c in list)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primarySoft,
                        child: Text(
                          '${c.priority}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              c.relationship,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              c.phone,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              _AddContactForm(store: store),
            ],
          );
        },
      ),
    );
  }
}

class _AddContactForm extends StatefulWidget {
  const _AddContactForm({required this.store});
  final PatientStore store;

  @override
  State<_AddContactForm> createState() => _AddContactFormState();
}

class _AddContactFormState extends State<_AddContactForm> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _relCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _relCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr('Add contact'),
            style: GoogleFonts.inter(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: context.tr('Name'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: context.tr('Phone'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _relCtrl,
            decoration: InputDecoration(
              hintText: context.tr('Relationship'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                final n = _nameCtrl.text.trim();
                final p = _phoneCtrl.text.trim();
                final r = _relCtrl.text.trim();
                if (n.isEmpty || p.isEmpty) return;
                final relationshipFallback = context.tr('Contact');
                final addedMsg = context.tr('Contact added.');
                final syncMsg = context.tr(
                  'Saved on this device. Could not sync to the cloud.',
                );
                final nextPrio = widget.store.contacts.isEmpty
                    ? 1
                    : widget.store.contacts
                            .map((c) => c.priority)
                            .reduce((a, b) => a > b ? a : b) +
                        1;
                final synced = await widget.store.addContact(
                  EmergencyContact(
                    id: 'ec-${DateTime.now().microsecondsSinceEpoch}',
                    name: n,
                    phone: p,
                    relationship: r.isEmpty ? relationshipFallback : r,
                    priority: nextPrio,
                  ),
                );
                if (!context.mounted) return;
                _nameCtrl.clear();
                _phoneCtrl.clear();
                _relCtrl.clear();
                FocusScope.of(context).unfocus();
                UserFeedback.showSuccess(context, addedMsg);
                final loggedIn =
                    Supabase.instance.client.auth.currentUser != null;
                if (!synced && loggedIn && context.mounted) {
                  UserFeedback.showWarning(context, syncMsg);
                }
              },
              child: Text(context.tr('Add contact')),
            ),
          ),
        ],
      ),
    );
  }
}
