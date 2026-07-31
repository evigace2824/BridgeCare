import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_theme.dart';
import '../../../services/auth_service.dart';
import '../../../services/signup_verification_service.dart';

/// Shown after sign-up when the account must be confirmed by email.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.alreadyRegistered = false,
  });

  final String email;
  final bool alreadyRegistered;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _cooldownSeconds = 30;

  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _isResending = false;
  int _cooldown = 0;
  Timer? _cooldownTimer;
  String? _sendError;

  @override
  void initState() {
    super.initState();
    _sendInitialCode();
    if (widget.alreadyRegistered) {
      _startCooldown();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _sendInitialCode() async {
    setState(() {
      _isSending = true;
      _sendError = null;
    });
    try {
      await SignupVerificationService.instance.sendSignupVerification(
        email: widget.email,
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _sendError = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _sendError = 'Could not send verification email.');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
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

  Future<void> _resend() async {
    if (_isResending || _cooldown > 0) return;
    setState(() => _isResending = true);
    try {
      await AuthService.instance.resendSignupVerificationEmail(
        email: widget.email,
      );
      if (!mounted) return;
      _startCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Verification code sent. Check your inbox and spam folder.',
          ),
          backgroundColor: AppColors.primary,
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
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit code from your email.')),
      );
      return;
    }
    setState(() => _isVerifying = true);
    try {
      await SignupVerificationService.instance.verifySignupCode(
        email: widget.email,
        token: code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email confirmed! You can sign in now.'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _goToLogin() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final intro = widget.alreadyRegistered
        ? 'We re-sent a confirmation code to'
        : 'We sent a 6-digit confirmation code to';

    final fallback = SignupVerificationService.instance.visibleFallbackCode;
    final fallbackReason =
        SignupVerificationService.instance.fallbackReason;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
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
                        Icons.mark_email_read_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Verify your email',
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
                        TextSpan(text: '$intro '),
                        TextSpan(
                          text: widget.email,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const TextSpan(
                          text:
                              '. Enter the code below to activate your account.',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_isSending) ...[
                    const SizedBox(height: 20),
                    const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ),
                  ],
                  if (_sendError != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _sendError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                  if (fallback != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFB300)),
                      ),
                      child: Column(
                        children: [
                          if (fallbackReason != null)
                            Text(
                              fallbackReason,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8A5A00),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            fallback,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 8,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'If email delivery failed, try this code. '
                            'Otherwise use the code from your inbox.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    decoration: const InputDecoration(
                      hintText: '6-digit code',
                      prefixIcon: Icon(Icons.pin_outlined),
                    ),
                    onFieldSubmitted: (_) => _verifyCode(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Confirm email'),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: (_isResending || _cooldown > 0) ? null : _resend,
                      child: _isResending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppColors.primary,
                              ),
                            )
                          : Text(
                              _cooldown > 0
                                  ? 'Resend in ${_cooldown}s'
                                  : 'Resend code',
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: _goToLogin,
                      child: const Text('Go to login'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Don't see an email? Check Spam. Delivery can take up to a minute.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
