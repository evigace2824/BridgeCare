import 'package:flutter/material.dart';

import '../../../../core/i18n/app_i18n.dart';
import '../../../../widgets/carebridge/care_bridge_emergency_button.dart';

/// Large red emergency CTA. [onPressed] should open confirm + send flow.
class SosButton extends StatelessWidget {
  const SosButton({
    super.key,
    required this.onPressed,
    required this.onLongPressConfirmed,
    this.isEmergencyActive = false,
  });

  final VoidCallback onPressed;
  final VoidCallback onLongPressConfirmed;
  final bool isEmergencyActive;

  @override
  Widget build(BuildContext context) {
    return CareBridgeEmergencyButton(
      title: context.tr('I NEED HELP'),
      subtitle: context.tr('Tap to call family + volunteers'),
      semanticsLabel: context.tr('I NEED HELP'),
      semanticsHint: context.tr('Tap to call family + volunteers'),
      onPressed: onPressed,
      onLongPressConfirmed: onLongPressConfirmed,
      isEmergencyActive: isEmergencyActive,
    );
  }
}
