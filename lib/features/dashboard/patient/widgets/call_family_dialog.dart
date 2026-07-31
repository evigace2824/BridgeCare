import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';

/// Confirmation dialog for "Call Family" (Spec §8.4).
/// Shows "Call [name]?" with Call Now + Cancel.
Future<void> showCallFamilyDialog({
  required BuildContext context,
  required String familyName,
  required VoidCallback onCallNow,
}) {
  return showDialog(
    context: context,
    builder: (_) => _CallFamilyDialog(
      familyName: familyName,
      onCallNow: onCallNow,
    ),
  );
}

class _CallFamilyDialog extends StatelessWidget {
  const _CallFamilyDialog({
    required this.familyName,
    required this.onCallNow,
  });

  final String familyName;
  final VoidCallback onCallNow;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              context.tr('Call {name}?', {'name': familyName}),
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr(
                'You are about to call your connected family member.',
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onCallNow();
                },
                icon: const Icon(Icons.call_rounded, size: 22),
                label: Text(context.tr('Call now')),
                style: ElevatedButton.styleFrom(
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                    context.tr('Cancel'),
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
