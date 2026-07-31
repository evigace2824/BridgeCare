import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../core/auth_remember_prefs.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/two_factor_auth_service.dart';
import '../../family/widgets/two_factor_otp_dialog.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

/// Modern sign-in screen — inline brand mark in the top-left, bold hero copy,
/// rounded fields, and a single primary action.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _clearRememberedEmail();
  }

  Future<void> _clearRememberedEmail() async {
    await AuthRememberPrefs.applyRememberChoice(email: '', rememberMe: false);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _displayName(String? fullName, String? email) {
    final name = fullName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final mail = email?.trim() ?? '';
    if (mail.isEmpty) return '';
    return mail.split('@').first;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final profile = await AuthService.instance.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;

      if (profile.role == UserRole.family &&
          await TwoFactorAuthService.instance.isEnabled(userId: profile.id)) {
        final email = TwoFactorAuthService.instance.resolveEmail(
          hintEmail: profile.email ?? _emailController.text.trim(),
        );
        try {
          await TwoFactorAuthService.instance.sendEmailOtp(email: email);
        } catch (e) {
          await AuthService.instance.signOut();
          if (!mounted) return;
          _showError(
            e is AuthException
                ? e.message
                : 'Could not send two-step verification code.',
          );
          return;
        }
        if (!mounted) return;
        final verified = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => TwoFactorOtpDialog(
            displayEmail: email,
            stepUpOnly: true,
          ),
        );
        if (verified != true) {
          await AuthService.instance.signOut();
          if (!mounted) return;
          _showError('Two-step verification is required to sign in.');
          return;
        }
      }

      if (!mounted) return;
      final displayName = _displayName(profile.fullName, profile.email);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            displayName.isNotEmpty
                ? 'Welcome back, $displayName!'
                : 'Welcome back!',
          ),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        profile.postAuthRoute,
        (route) => false,
      );
    } on AuthException catch (e) {
      _handleAuthError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleAuthError(String message) {
    final lower = message.toLowerCase();
    final notConfirmed = lower.contains('confirm') && lower.contains('email');

    if (notConfirmed && _emailController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: const Text('Please confirm your email to continue.'),
          action: SnackBarAction(
            label: 'Verify',
            textColor: Colors.white,
            onPressed: _openVerifyEmail,
          ),
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    _showError(message);
  }

  void _openVerifyEmail() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyEmailScreen(
          email: _emailController.text.trim(),
          alreadyRegistered: true,
        ),
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/welcome', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned.fill(child: _AuroraBackdrop()),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _topBar(),
                        const SizedBox(height: 12),
                        _logoHero(),
                        const SizedBox(height: 18),
                        _heroBlock(),
                        const SizedBox(height: 26),
                        _FieldLabel('Email'),
                        const SizedBox(height: 8),
                        _emailField(),
                        const SizedBox(height: 16),
                        _FieldLabel('Password'),
                        const SizedBox(height: 8),
                        _passwordField(),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _openForgotPassword,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot password?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _primaryButton(),
                        const SizedBox(height: 16),
                        _secureNote(),
                        const SizedBox(height: 22),
                        _manifestoStrip(),
                        const SizedBox(height: 14),
                        _signupRow(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────── Header ───────────────────────

  Widget _topBar() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 0,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _goBack,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _logoHero() {
    return SizedBox(
      width: double.infinity,
      child: Center(
        child: Image.asset(
          'assets/bridgecare_logo.png',
          height: 120,
          fit: BoxFit.contain,
          semanticLabel: 'BridgeCare',
          color: AppColors.background,
          colorBlendMode: BlendMode.multiply,
        ),
      ),
    );
  }

  // ─────────────────────── Hero ───────────────────────

  Widget _heroBlock() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Welcome back',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to keep care moving —\nfor the people who once carried us.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── Fields ───────────────────────

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.fieldFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emergency),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emergency, width: 1.6),
      ),
    );
  }

  Widget _emailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      style: GoogleFonts.inter(
        fontSize: 14.5,
        color: AppColors.textPrimary,
      ),
      decoration: _fieldDecoration(
        hint: 'your@email.com',
        icon: Icons.mail_outline_rounded,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return 'Please enter your email';
        }
        if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _passwordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submit(),
      style: GoogleFonts.inter(
        fontSize: 14.5,
        color: AppColors.textPrimary,
      ),
      decoration: _fieldDecoration(
        hint: '••••••••',
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          onPressed: () =>
              setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Please enter your password' : null,
    );
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _emailController.text.trim(),
        ),
      ),
    );
  }

  Widget _primaryButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.1,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Log In'),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
      ),
    );
  }

  Widget _secureNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded,
            size: 12, color: AppColors.textSecondary.withValues(alpha: 0.7)),
        const SizedBox(width: 4),
        Text(
          'Encrypted · two-step verification supported',
          style: GoogleFonts.inter(
            fontSize: 11.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _manifestoStrip() {
    return Center(
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/bridgecare_logo.png',
              height: 26,
              fit: BoxFit.contain,
              semanticLabel: 'BridgeCare',
              color: Colors.white,
              colorBlendMode: BlendMode.multiply,
            ),
            const SizedBox(width: 10),
            Text(
              'Built so no one ages alone.',
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _signupRow() {
    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'New to BridgeCare? ',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          GestureDetector(
            onTap: () =>
                Navigator.pushReplacementNamed(context, '/signup'),
            child: Text(
              'Create an account',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -0.1,
      ),
    );
  }
}

/// Soft ambient gradient blobs behind the login surface — gives the screen
/// the same "alive" feel modern apps use (Stripe, Linear, Revolut).
class _AuroraBackdrop extends StatelessWidget {
  const _AuroraBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _blob(
              size: 240,
              color: AppColors.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            top: 120,
            left: -80,
            child: _blob(
              size: 200,
              color: const Color(0xFF24B6A8).withValues(alpha: 0.16),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _blob(
              size: 260,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }
}
