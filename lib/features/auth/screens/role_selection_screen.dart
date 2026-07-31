import 'package:flutter/material.dart';
import 'signup_basic_screen.dart';
import 'role_details_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final SignupBasicData data;

  const RoleSelectionScreen({super.key, required this.data});

  @override
  State<RoleSelectionScreen> createState() =>
      _RoleSelectionScreenState();
}

class _RoleSelectionScreenState
    extends State<RoleSelectionScreen> {
  String _selectedRole = '';

  static const Color _primary = Color(0xFF1976D2);

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    Navigator.pushNamedAndRemoveUntil(context, '/signup', (route) => false);
  }

  Widget _roleButton(String role, IconData icon) {
    final isSelected = _selectedRole == role;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected ? _primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(60),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(height: 8),
              Text(
                role,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (_selectedRole.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleDetailsScreen(
          role: _selectedRole,
          data: widget.data,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _selectedRole.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FB),
      body: Center(
        child: Container(
          width: 430,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: _goBack,
                  tooltip: 'Back',
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const Text(
                'Select Your Role',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose how you will use BridgeCare',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              if (_selectedRole.isNotEmpty)
                Text(
                  "You're signing up as a $_selectedRole",
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const SizedBox(height: 16),

              Row(
                children: [
                  _roleButton('Patient', Icons.favorite),
                  _roleButton('Volunteer', Icons.volunteer_activism),
                  _roleButton('Family', Icons.family_restroom),
                ],
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isActive ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.black38,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}