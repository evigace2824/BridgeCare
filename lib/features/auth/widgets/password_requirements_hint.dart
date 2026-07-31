import 'package:flutter/material.dart';

import '../../../core/password_policy.dart';

class PasswordRequirementsHint extends StatelessWidget {
  const PasswordRequirementsHint({
    super.key,
    required this.password,
    this.showTitle = true,
  });

  final String password;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle)
            Text(
              'Password must include:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade800,
              ),
            ),

          if (showTitle) const SizedBox(height: 8),

          _row(
            met: PasswordPolicy.hasMinLength(password),
            text: 'At least ${PasswordPolicy.minLength} characters',
          ),
          _row(
            met: PasswordPolicy.hasUppercase(password),
            text: 'One uppercase letter (A–Z)',
          ),
          _row(
            met: PasswordPolicy.hasDigit(password),
            text: 'One number (0–9)',
          ),
          _row(
            met: PasswordPolicy.hasSymbol(password),
            text: 'One symbol (! @ # \$ % …)',
          ),
        ],
      ),
    );
  }

  Widget _row({required bool met, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: met ? const Color(0xFF2E7D32) : Colors.grey.shade400,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.25,
                color: met ? const Color(0xFF1B5E20) : Colors.grey.shade700,
                fontWeight: met ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}