import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../services/audio_service.dart';
import '../../../../utils/care_bridge_layout.dart';
import '../../../../widgets/carebridge/care_bridge_card.dart';
import '../data/patient_store.dart';

/// Daily tips — large type, calm layout, strong tap targets (elderly-first).
class DailyContentScreen extends StatelessWidget {
  const DailyContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final h = CareBridgeLayout.horizontalPadding(context);

    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final store = PatientStore.instance;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              context.tr('Daily Content'),
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: PatientText.titleS,
              ),
            ),
            actions: [
              IconButton(
                tooltip: context.tr('Audio mode'),
                iconSize: 26,
                constraints: const BoxConstraints(
                  minWidth: CareBridgeLayout.minTouchTarget,
                  minHeight: CareBridgeLayout.minTouchTarget,
                ),
                onPressed: () {
                  store.toggleAudioMode();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      content: Text(
                        store.audioModeEnabled
                            ? context.tr('Audio mode enabled.')
                            : context.tr('Audio mode disabled.'),
                      ),
                    ),
                  );
                },
                icon: Icon(
                  store.audioModeEnabled
                      ? Icons.headphones_rounded
                      : Icons.headphones_outlined,
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: EdgeInsets.fromLTRB(h, 12, h, 28 + bottom),
              children: [
                Text(
                  context.tr('Easy tips for your wellbeing.'),
                  style: GoogleFonts.inter(
                    fontSize: PatientText.bodyM,
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 18),
                CareBridgeCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('Today\'s Health Tip'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted,
                                    letterSpacing: 0.35,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  store.dailyTip,
                                  style: GoogleFonts.inter(
                                    fontSize: PatientText.titleS,
                                    fontWeight: FontWeight.w800,
                                    height: 1.35,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: context.tr('Listen'),
                            iconSize: 28,
                            constraints: const BoxConstraints(
                              minWidth: CareBridgeLayout.minTouchTarget,
                              minHeight: CareBridgeLayout.minTouchTarget,
                            ),
                            onPressed: () async {
                              await AudioService.instance.speak(store.dailyTip);
                            },
                            icon: Icon(
                              store.audioModeEnabled
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_off_rounded,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _TipCategoryCard(
                  title: context.tr('Health tip of the day'),
                  tip: store.dailyTip,
                ),
                const SizedBox(height: 12),
                _TipCategoryCard(
                  title: context.tr('Safety tip'),
                  tip: context.tr('Keep your phone nearby in case you need help.'),
                ),
                const SizedBox(height: 12),
                _TipCategoryCard(
                  title: context.tr('Mental wellbeing tip'),
                  tip: context.tr('Take five slow breaths and relax your shoulders.'),
                ),
                const SizedBox(height: 12),
                _TipCategoryCard(
                  title: context.tr('Hydration reminder'),
                  tip: context.tr('Drink a glass of water now.'),
                ),
                const SizedBox(height: 12),
                _TipCategoryCard(
                  title: context.tr('Family connection suggestion'),
                  tip: context.tr('Send a short message to your family today.'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TipCategoryCard extends StatelessWidget {
  const _TipCategoryCard({required this.title, required this.tip});
  final String title;
  final String tip;

  @override
  Widget build(BuildContext context) {
    return CareBridgeCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      borderRadius: 16,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tip,
                  style: GoogleFonts.inter(
                    fontSize: PatientText.bodyM,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            tooltip: context.tr('Read aloud'),
            onPressed: () => AudioService.instance.speak(tip),
            icon: const Icon(Icons.volume_up_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
