import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

/// Shown when [UserModel.isProfileComplete] is false (e.g. first Google sign-in).
class RoleOnboardingScreen extends StatefulWidget {
  const RoleOnboardingScreen({super.key});

  @override
  State<RoleOnboardingScreen> createState() => _RoleOnboardingScreenState();
}

class _RoleOnboardingScreenState extends State<RoleOnboardingScreen> {
  final _nameController = TextEditingController();
  UserRole _role = UserRole.elderly;
  bool _loading = true;
  bool _saving = false;

  static const Color _primary = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await AuthService.instance.getCurrentUserProfile();
    if (!mounted) return;
    if (p == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    if (p.isProfileComplete) {
      Navigator.pushNamedAndRemoveUntil(context, p.homeRoute, (_) => false);
      return;
    }
    setState(() {
      _role = p.role;
      if (p.fullName != null && p.fullName!.isNotEmpty) {
        _nameController.text = p.fullName!;
      }
      _loading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Widget _roleChip(BuildContext context, UserRole role, String label) {
    final selected = _role == role;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _role = role),
      selectedColor: _primary.withValues(alpha: 0.2),
      checkmarkColor: _primary,
    );
  }

  static String _roleHint(UserRole r) {
    switch (r) {
      case UserRole.elderly:
        return 'Receiving or managing my own care.';
      case UserRole.family:
        return 'Helping a relative.';
      case UserRole.volunteer:
        return 'Offering time and support.';
      case UserRole.admin:
        return '';
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      final profile = await AuthService.instance.completeRoleOnboarding(
        role: _role,
        displayName: _nameController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        profile.homeRoute,
        (_) => false,
      );
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('How will you use BridgeCare?'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Choose your role so we can show the right home screen. '
            'You can keep the name from Google or enter how you want to be called.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Your name',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          Text(
            'I am signing up as',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _roleChip(
                context,
                UserRole.elderly,
                'Elderly / member',
              ),
              _roleChip(
                context,
                UserRole.family,
                'Family / caregiver',
              ),
              _roleChip(
                context,
                UserRole.volunteer,
                'Volunteer',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _roleHint(_role),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
