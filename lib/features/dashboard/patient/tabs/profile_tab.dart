import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/app_theme.dart';
import '../../../../core/i18n/app_i18n.dart';
import '../../../../core/i18n/locale_controller.dart';
import '../../../../models/user_model.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/audio_service.dart';
import '../data/patient_store.dart';
import '../../../../screens/user/patient_nav.dart';
import '../../../../utils/care_bridge_layout.dart';
import '../../../../widgets/carebridge/care_bridge_settings_tile.dart';
import '../data/patient_models.dart';
import '../screens/daily_content_screen.dart';
import '../screens/emergency_contacts_screen.dart';

/// Profile tab — settings and personalization.
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key, required this.profile});

  final UserModel? profile;

  Future<void> _signOut(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(context.tr('Sign out?')),
        content: Text(
          context.tr("You'll need your email and password to sign back in."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emergency,
            ),
            child: Text(context.tr('Sign out')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await AuthService.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/welcome', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?.fullName?.trim().isNotEmpty == true
        ? profile!.fullName!
        : context.tr('Welcome');
    final email = profile?.email ?? '';
    final initials = _initials(name);

    return ListenableBuilder(
      listenable: PatientStore.instance,
      builder: (context, _) {
        final store = PatientStore.instance;
        return SafeArea(
          bottom: false,
          child: ListView(
            padding: CareBridgeLayout.tabScreenPadding(context),
            children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: PatientText.bodyL,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: PatientText.bodyM,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _FamilyCodeCard(
            code: profile?.familyVerificationCode ?? 'CB-2026-A4F8',
          ),
          const SizedBox(height: 18),
          _SettingsGroup(
            children: [
              CareBridgeSettingsTile(
                icon: Icons.contacts_rounded,
                iconColor: AppColors.accentTeal,
                softColor: AppColors.accentTealSoft,
                title: context.tr('Emergency contacts'),
                subtitle: context.tr('Manage who is called first'),
                onTap: () => PatientNav.push(
                  context,
                  const EmergencyContactsScreen(),
                ),
              ),
              CareBridgeSettingsTile(
                icon: Icons.newspaper_rounded,
                iconColor: AppColors.accentPurple,
                softColor: AppColors.accentPurpleSoft,
                title: context.tr('News & daily content'),
                subtitle: context.tr('Read'),
                onTap: () =>
                    PatientNav.push(context, const DailyContentScreen()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              CareBridgeSettingsTile(
                icon: Icons.headphones_rounded,
                iconColor: AppColors.accentPurple,
                softColor: AppColors.accentPurpleSoft,
                title: context.tr('Audio mode'),
                subtitle: store.audioModeEnabled
                    ? context.tr('Audio mode enabled.')
                    : context.tr('Audio mode disabled.'),
                onTap: () async {
                  store.toggleAudioMode();
                  final msg = store.audioModeEnabled
                      ? context.tr('Audio mode enabled.')
                      : context.tr('Audio mode disabled.');
                  if (store.audioModeEnabled) {
                    AudioService.instance.speak(msg);
                  } else {
                    AudioService.instance.stop();
                  }
                  _toast(
                    context,
                    msg,
                  );
                },
              ),
              CareBridgeSettingsTile(
                icon: Icons.translate_rounded,
                iconColor: AppColors.success,
                softColor: AppColors.successSoft,
                title: context.tr('Language'),
                subtitle:
                    store.language == 'sq' ? context.tr('Albanian') : context.tr('English'),
                onTap: () => _pickLanguage(context),
              ),
              CareBridgeSettingsTile(
                icon: Icons.text_fields_rounded,
                iconColor: AppColors.warning,
                softColor: AppColors.warningSoft,
                title: context.tr('Text size'),
                subtitle: '${(store.textScale * 100).round()}%',
                onTap: () => _pickTextSize(context),
              ),
              CareBridgeSettingsTile(
                icon: Icons.text_increase_rounded,
                iconColor: AppColors.primary,
                softColor: AppColors.primarySoft,
                title: context.tr('Bigger text mode'),
                subtitle: store.biggerTextMode
                    ? context.tr('Enabled')
                    : context.tr('Disabled'),
                onTap: () {
                  store.toggleBiggerTextMode();
                  _toast(
                    context,
                    store.biggerTextMode
                        ? context.tr('Bigger text mode enabled.')
                        : context.tr('Bigger text mode disabled.'),
                  );
                },
              ),
              CareBridgeSettingsTile(
                icon: Icons.contrast_rounded,
                iconColor: AppColors.textPrimary,
                softColor: AppColors.border,
                title: context.tr('High contrast mode'),
                subtitle: store.highContrastMode
                    ? context.tr('Enabled')
                    : context.tr('Disabled'),
                onTap: () {
                  store.toggleHighContrastMode();
                  _toast(
                    context,
                    store.highContrastMode
                        ? context.tr('High contrast mode enabled.')
                        : context.tr('High contrast mode disabled.'),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsGroup(
            children: [
              CareBridgeSettingsTile(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.primary,
                softColor: AppColors.primarySoft,
                title: context.tr('Notification settings'),
                subtitle: context.tr('Manage alerts and reminders'),
                onTap: () => _showNotificationSettings(context),
              ),
              CareBridgeSettingsTile(
                icon: Icons.support_agent_rounded,
                iconColor: AppColors.accentTeal,
                softColor: AppColors.accentTealSoft,
                title: context.tr('Help and support'),
                subtitle: context.tr('Get assistance'),
                onTap: () => _openSupportMail(context),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _RecentActivityMiniList(activities: store.recentActivities.take(5).toList()),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _signOut(context),
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.emergency,
                size: 20,
              ),
              label: Text(
                context.tr('Sign out'),
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emergency,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: AppColors.emergency.withValues(alpha: 0.4),
                  width: 1.4,
                ),
              ),
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _pickLanguage(BuildContext context) async {
    final store = PatientStore.instance;
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(context.tr('Choose language')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'en'),
            child: Text(
              '${store.language == 'en' ? '✓ ' : ''}${context.tr('English')}',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'sq'),
            child: Text(
              '${store.language == 'sq' ? '✓ ' : ''}${context.tr('Albanian')}',
            ),
          ),
        ],
      ),
    );
    if (selected == null) return;
    if (!context.mounted) return;
    store.setLanguage(selected);
    LocaleController.instance.setCode(selected);
    final langWord =
        selected == 'sq' ? context.tr('Albanian') : context.tr('English');
    _toast(
      context,
      context.tr(
        'Language set to {lang}.',
        {'lang': langWord},
      ),
    );
  }

  Future<void> _pickTextSize(BuildContext context) async {
    final store = PatientStore.instance;
    final pct = (store.textScale * 100).round();
    final nearest = [100, 120, 140].reduce(
      (a, b) => (pct - a).abs() <= (pct - b).abs() ? a : b,
    );
    final picked = await showDialog<int>(
      context: context,
      builder: (_) => SimpleDialog(
        title: Text(context.tr('Text size')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 100),
            child: Text(
              '${nearest == 100 ? '✓ ' : ''}${context.tr('100%')}',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 120),
            child: Text(
              '${nearest == 120 ? '✓ ' : ''}${context.tr('120%')}',
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 140),
            child: Text(
              '${nearest == 140 ? '✓ ' : ''}${context.tr('140%')}',
            ),
          ),
        ],
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    store.setTextScalePreset(picked);
    _toast(context, context.tr('Text size updated.'));
  }

  Future<void> _showNotificationSettings(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Notification settings')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: Text(context.tr('Reminder alerts')),
            ),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: Text(context.tr('Health alerts')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('Done')),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupportMail(BuildContext context) async {
    const supportEmail = 'support@carebridge.app';
    final openMail = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('Help and support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Contact our support team at:')),
            const SizedBox(height: 8),
            SelectableText(
              supportEmail,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(const ClipboardData(text: supportEmail));
              if (!ctx.mounted) return;
              Navigator.pop(ctx, false);
              _toast(context, context.tr('Support email copied.'));
            },
            child: Text(context.tr('Copy email')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('Open email app')),
          ),
        ],
      ),
    );
    if (openMail != true) return;
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      queryParameters: {'subject': 'BridgeCare support request'},
    );
    final ok = await launchUrl(uri);
    if (!context.mounted) return;
    if (!ok) _toast(context, context.tr('Could not open email app.'));
  }
}

/// Card showing the patient's unique family-link code (Spec §6.3). Family
/// members enter this exact code on their signup screen to bind their account
/// to this patient. Tapping copies it to clipboard for easy sharing.
class _FamilyCodeCard extends StatelessWidget {
  const _FamilyCodeCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.family_restroom_rounded,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('My family link code'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.95),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Share this code with your family so they can connect to you.',
            ),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: GoogleFonts.robotoMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: code));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.tr('Family link code copied'),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Icon(
                      Icons.copy_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(
                height: 1,
                color: AppColors.border,
                indent: 80,
              ),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityMiniList extends StatelessWidget {
  const _RecentActivityMiniList({required this.activities});
  final List<PatientActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          context.tr('No recent activity yet.'),
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('Recent activity'),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final item in activities)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.history_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      context.tr(item.title),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

