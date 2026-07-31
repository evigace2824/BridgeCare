import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:gotrue/gotrue.dart' as gt;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../core/email_config.dart';
import '../core/supabase_config.dart';
import 'auth_service.dart';
import 'resend_email_service.dart';

/// Delivers and checks signup / email-confirmation codes after registration.
class SignupVerificationService {
  SignupVerificationService._();
  static final SignupVerificationService instance = SignupVerificationService._();

  String? _lastEmail;
  String? _resendOtp;
  DateTime? _resendOtpIssuedAt;
  String? _demoFallbackCode;
  DateTime? _demoFallbackIssuedAt;
  String? _demoFallbackReason;

  SupabaseClient get _client => Supabase.instance.client;

  String? get lastEmail => _lastEmail;

  /// Shown when every email provider failed so signup can still be tested.
  String? get visibleFallbackCode {
    final issuedAt = _demoFallbackIssuedAt;
    if (_demoFallbackCode == null || issuedAt == null) return null;
    if (DateTime.now().difference(issuedAt) > const Duration(minutes: 10)) {
      _clearFallback();
      return null;
    }
    return _demoFallbackCode;
  }

  String? get fallbackReason => _demoFallbackReason;

  String? get _activeResendOtp {
    final issued = _resendOtpIssuedAt;
    if (_resendOtp == null || issued == null) return null;
    if (DateTime.now().difference(issued) > const Duration(minutes: 10)) {
      _resendOtp = null;
      _resendOtpIssuedAt = null;
      return null;
    }
    return _resendOtp;
  }

  void _clearFallback() {
    _demoFallbackCode = null;
    _demoFallbackIssuedAt = null;
    _demoFallbackReason = null;
  }

  /// Sends a confirmation code to [email] after sign-up.
  Future<void> sendSignupVerification({required String email}) async {
    final addr = email.trim().toLowerCase();
    if (addr.isEmpty) {
      throw AuthException('Please enter your email first.');
    }
    _lastEmail = addr;
    _clearFallback();
    _resendOtp = null;
    _resendOtpIssuedAt = null;

    final redirectTo = SupabaseConfig.siteUrl.isNotEmpty
        ? SupabaseConfig.siteUrl
        : null;

    Object? lastError;

    // 1) Supabase OTP for the pending account.
    try {
      await _client.auth.signInWithOtp(
        email: addr,
        shouldCreateUser: false,
      );
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Signup signInWithOtp failed: $e');
    }

    // 2) Signup confirmation resend (link or OTP depending on project).
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: addr,
        emailRedirectTo: redirectTo,
      );
      return;
    } catch (e) {
      lastError = e;
      debugPrint('Signup resend failed: $e');
    }

    // 3) Branded email via Resend when configured.
    if (EmailConfig.isResendConfigured) {
      try {
        final code = _generateOtp();
        await ResendEmailService.instance.sendEmail(
          to: addr,
          subject: 'Confirm your BridgeCare account',
          html: ResendEmailService.verificationCodeHtml(code: code),
          text:
              'Your BridgeCare confirmation code is: $code\n\n'
              'Enter it in the app to activate your account.',
        );
        _resendOtp = code;
        _resendOtpIssuedAt = DateTime.now();
        // Also nudge Supabase to send its own OTP if possible.
        try {
          await _client.auth.signInWithOtp(
            email: addr,
            shouldCreateUser: false,
          );
        } catch (_) {}
        return;
      } catch (e) {
        lastError = e;
        debugPrint('Signup Resend delivery failed: $e');
      }
    }

    _activateDemoFallback(lastError ?? 'Could not send email');
  }

  /// Confirms the account using the code from email (or fallback).
  Future<void> verifySignupCode({
    required String email,
    required String token,
  }) async {
    final addr = email.trim().toLowerCase();
    if (addr.isEmpty) {
      throw AuthException('Missing email for verification.');
    }

    final cleaned = token.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.length < 6 || cleaned.length > 8) {
      throw AuthException('Enter the 6-digit code from your email.');
    }

    AuthException? lastError;

    for (final type in const [
      OtpType.signup,
      OtpType.email,
      OtpType.magiclink,
    ]) {
      try {
        await _client.auth.verifyOTP(
          type: type,
          email: addr,
          token: cleaned,
        );
        _clearFallback();
        _resendOtp = null;
        _resendOtpIssuedAt = null;
        return;
      } on gt.AuthException catch (e) {
        lastError = AuthException(_friendlyOtpError(e));
      }
    }

    final resendCode = _activeResendOtp;
    final fallback = visibleFallbackCode;
    final matchesLocal = (resendCode != null && cleaned == resendCode) ||
        (fallback != null && cleaned == fallback);

    if (matchesLocal) {
      // Resend-only code: retry Supabase delivery then ask user to use email OTP.
      try {
        await sendSignupVerification(email: addr);
      } catch (_) {}
      throw AuthException(
        'We emailed a code from BridgeCare, but your Supabase project must '
        'accept email OTP to finish signup. In Supabase → Authentication → '
        'Providers → Email, enable "Confirm email" with OTP, then tap Resend '
        'and enter the newest 6-digit code from your inbox.',
      );
    }

    throw lastError ??
        AuthException(
          'Invalid or expired code. Tap “Resend code” and use the newest email.',
        );
  }

  String _generateOtp() =>
      (Random.secure().nextInt(900000) + 100000).toString();

  void _activateDemoFallback(Object error) {
    _demoFallbackCode = _generateOtp();
    _demoFallbackIssuedAt = DateTime.now();
    _demoFallbackReason = _reasonFromError(error);
  }

  String _reasonFromError(Object error) {
    final blob = error.toString().toLowerCase();
    if (blob.contains('rate') || blob.contains('limit')) {
      return 'Email rate-limited — use the code below, then resend';
    }
    if (blob.contains('smtp') || blob.contains('email')) {
      return 'Email delivery unavailable — use the code below';
    }
    return 'Could not send email — use the code below';
  }

  String _friendlyOtpError(Object e) {
    final msg = e is AuthException
        ? e.message
        : e is gt.AuthException
            ? e.message
            : e.toString();
    final blob = msg.toLowerCase();
    if (blob.contains('expired')) {
      return 'That code expired. Resend a new one.';
    }
    if (blob.contains('invalid') || blob.contains('otp')) {
      return 'Invalid code. Check the latest email or resend.';
    }
    return msg;
  }
}
