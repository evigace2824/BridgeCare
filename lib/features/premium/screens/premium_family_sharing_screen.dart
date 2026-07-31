import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../family/family_plan_store.dart';

/// Premium multi-caregiver family sharing.
class PremiumFamilySharingScreen extends StatefulWidget {
  const PremiumFamilySharingScreen({super.key});

  @override
  State<PremiumFamilySharingScreen> createState() =>
      _PremiumFamilySharingScreenState();
}

class _PremiumFamilySharingScreenState extends State<PremiumFamilySharingScreen> {
  final _inviteEmailCtrl = TextEditingController();
  final List<_Caregiver> _caregivers = [
    const _Caregiver('You', 'Primary caregiver', true, 'owner@family.com'),
    const _Caregiver('Sarah M.', 'Sister · Health alerts', true, 'sarah@email.com'),
    const _Caregiver('Dr. Kola', 'Physician · Read-only', false, 'dr@clinic.com'),
  ];

  @override
  void dispose() {
    _inviteEmailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final max = FamilyPlanStore.instance.plan.familyMaxLinkedProfilesHint;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        title: const Text('Family sharing'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFFA855F7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Premium allows up to $max caregivers to monitor, receive alerts, and coordinate care.',
              style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          ..._caregivers.map(_tile),
          const SizedBox(height: 16),
          const Text('Invite caregiver',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 8),
          TextField(
            controller: _inviteEmailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'email@example.com',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.mail_outline_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _invite,
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Send invite'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _invite() {
    final email = _inviteEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() {
      _caregivers.add(_Caregiver(email.split('@').first, 'Pending invite', false, email));
      _inviteEmailCtrl.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite sent to $email'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _tile(_Caregiver c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
            child: Text(c.name[0],
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF7C3AED))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(c.role,
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF6B7280))),
              ],
            ),
          ),
          if (c.active)
            const Icon(Icons.verified_rounded, color: Color(0xFF10B981))
          else
            TextButton(
              onPressed: () {},
              child: const Text('Resend'),
            ),
        ],
      ),
    );
  }
}

class _Caregiver {
  const _Caregiver(this.name, this.role, this.active, this.email);
  final String name;
  final String role;
  final bool active;
  final String email;
}
