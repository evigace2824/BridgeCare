import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/oauth_redirect_server.dart';
import '../widgets/brand_logo_header.dart';

/// **Forgot Password** entry point. Two visual states:
///
/// 1. **Form** — email field + "Send reset link". Validates and calls
///    [AuthService.sendPasswordResetEmail].
/// 2. **Sent** — confirmation copy + spam hint + a 30-second-cooldown
///    "Resend email" button (so we don't trip Supabase's
///    `over_email_send_rate_limit` on the built-in SMTP).
///
/// The actual password change happens on `ResetPasswordScreen`, which is
/// pushed automatically when the user opens the recovery link in their email
/// (handled globally by the auth listener in `main.dart`).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail});

  /// Email pre-filled from the login screen, if any.
  final String? initialEmail;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const int _cooldownSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _pasteController = TextEditingController();

  bool _isSending = false;
  bool _emailSent = false;
  bool _isProcessingPaste = false;
  bool _showPasteField = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  LoopbackAuthCallbackServer? _recoveryListener;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialEmail?.trim() ?? '';
    if (initial.isNotEmpty) _emailController.text = initial;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    _pasteController.dispose();
    _recoveryListener?.close();
    super.dispose();
  }

  /// Starts a desktop loopback server so the user clicking the email link
  /// lands on a local HTTP page we control — and the recovery URL gets fed
  /// straight into Supabase. No-op on web / non-desktop platforms; failures
  /// are silent because the manual-paste fallback covers the same case.
  Future<void> _ensureRecoveryListener() async {
    if (_recoveryListener != null) return;
    final server = await AuthService.instance.startDesktopRecoveryListener(
      onError: (err) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err.toString()),
            backgroundColor: Colors.red.shade700,
          ),
        );
      },
    );
    if (!mounted) {
      await server?.close();
      return;
    }
    _recoveryListener = server;
  }

  void _startCooldown() {
    _cooldown = _cooldownSeconds;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _send({bool isResend = false}) async {
    if (_isSending) return;
    if (!isResend && !_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(
        email: _emailController.text,
      );
      if (!mounted) return;
      setState(() {
        _emailSent = true;
      });
      _startCooldown();
      // Begin listening on the loopback port so when the user clicks the
      // email link the recovery URL is captured automatically.
      unawaited(_ensureRecoveryListener());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.primary,
          content: Text(
            isResend
                ? 'Reset link re-sent. Check your inbox (and spam folder).'
                : "If an account exists for that email, we've sent a reset link.",
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    }
  }

  /// Manual fallback when the loopback listener can't catch the redirect
  /// (app was closed when the user clicked the link, browser blocked the
  /// loopback, different device, etc.). User pastes the URL from their
  /// email and we feed it to Supabase the same way.
  Future<void> _processPastedLink() async {
    final raw = _pasteController.text.trim();
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paste the link from your email first.')),
      );
      return;
    }
    setState(() => _isProcessingPaste = true);
    try {
      await AuthService.instance.processRecoveryUrl(raw);
      // The `passwordRecovery` event listener in main.dart handles navigation
      // to ResetPasswordScreen automatically.
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessingPaste = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _emailSent ? _buildSent() : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandLogoHeader(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              onPressed: _goBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Forgot password',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enter your email and we'll send a reset link.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FieldLabel('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'your@email.com',
                ),
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSending ? null : () => _send(),
                  child: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Send reset link'),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Remembered it? ',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: _goBack,
                      child: Text(
                        'Log in',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSent() {
    final canResend = !_isSending && _cooldown <= 0;
    return Column(
      key: const ValueKey('sent'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.lock_reset_rounded,
              size: 48,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Check your email',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
            children: [
              const TextSpan(text: 'We sent a password reset link to '),
              TextSpan(
                text: _emailController.text.trim(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const TextSpan(
                text: '. Click it from this device to choose a new password.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Don't see it? Check your Spam or Promotions folder. The "
                  'link expires in about an hour.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.45,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (_) => false,
            ),
            child: const Text('Back to login'),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: canResend ? () => _send(isResend: true) : null,
            child: _isSending
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: AppColors.primary,
                    ),
                  )
                : Text(
                    _cooldown > 0 ? 'Resend in ${_cooldown}s' : 'Resend email',
                  ),
          ),
        ),
        const SizedBox(height: 22),
        const Divider(height: 1, color: AppColors.border),
        const SizedBox(height: 16),
        if (!_showPasteField)
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _showPasteField = true),
              icon: const Icon(
                Icons.link_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              label: const Text(
                "Browser shows an error? Paste the link instead",
              ),
            ),
          )
        else ...[
          Text(
            'Paste the link from your reset email',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If clicking the link in your email shows "site can\'t be '
            'reached", copy that URL from the browser bar and paste it here.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _pasteController,
            maxLines: 3,
            minLines: 2,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              hintText: 'http://127.0.0.1:54721/?code=...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessingPaste ? null : _processPastedLink,
              child: _isProcessingPaste
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Continue with link'),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _emailSent = false),
            child: const Text('Use a different email'),
          ),
        ),
      ],
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
