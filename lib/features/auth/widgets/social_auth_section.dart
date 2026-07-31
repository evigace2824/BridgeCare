import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// BridgeCare-styled Google button with optional “or” divider.
///
/// Use [dividerAboveButtons]: `true` when this block sits **below** email/password
/// (divider reads e.g. “Or continue with”).
class SocialAuthSection extends StatelessWidget {
  const SocialAuthSection({
    super.key,
    required this.isBusy,
    required this.onGoogle,
    this.dividerLabel,
    this.dividerAboveButtons = true,
  });

  final bool isBusy;
  final VoidCallback onGoogle;

  /// When non-null, shows a horizontal rule with this label.
  final String? dividerLabel;

  /// `true`: divider → Google. `false`: Google only.
  final bool dividerAboveButtons;

  static const _googleBorder = Color(0xFFDADCE0);
  static const _googleFg = Color(0xFF1F1F1F);

  @override
  Widget build(BuildContext context) {
    final buttons = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SocialButton(
          onPressed: isBusy ? null : onGoogle,
          backgroundColor: Colors.white,
          borderColor: _googleBorder,
          foregroundColor: _googleFg,
          icon: FaIcon(
            FontAwesomeIcons.google,
            size: 22,
            color: const Color(0xFF4285F4),
          ),
          label: 'Continue with Google',
          elevation: 0,
          shadowColor: Colors.black26,
        ),
      ],
    );

    if (dividerLabel == null || dividerLabel!.isEmpty) {
      return buttons;
    }

    if (dividerAboveButtons) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _OrDivider(label: dividerLabel!),
          const SizedBox(height: 18),
          buttons,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        buttons,
        const SizedBox(height: 18),
        _OrDivider(label: dividerLabel!),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.icon,
    required this.label,
    this.elevation = 1,
    this.shadowColor,
  });

  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final Widget icon;
  final String label;
  final double elevation;
  final Color? shadowColor;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return AnimatedOpacity(
      opacity: disabled ? 0.55 : 1,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: backgroundColor,
        elevation: elevation,
        shadowColor: shadowColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: foregroundColor,
                    letterSpacing: 0.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
