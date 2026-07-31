import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:care_bridge/features/family/job_list_page.dart';
import '../../../core/app_theme.dart';
import '../../../core/i18n/app_i18n.dart';

/// BridgeCare entry screen: logo, value proposition, Log In + Create Account.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    'assets/bridgecare_logo.png',
                    width: 220,
                    fit: BoxFit.contain,
                    color: AppColors.background,
                    colorBlendMode: BlendMode.multiply,
                    semanticLabel: 'BridgeCare logo',
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.favorite_rounded,
                      size: 88,
                      color: AppColors.primary,
                      semanticLabel: 'BridgeCare',
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'BridgeCare',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.6,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Welcome to BridgeCare'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    context.tr(
                      'Real-time health monitoring, instant assistance, and community support.',
                    ),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/login'),
                      child: Text(
                        context.tr('Log In'),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        context.tr('Create Account'),
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                 const SizedBox(height: 20),

GestureDetector(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const JobsListPage(),
      ),
    );
  },
  child: Text(
    'Looking for a job?',
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      decoration: TextDecoration.underline,
    ),
  ),
),

const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
