import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/email_config.dart';
import 'resend_email_service.dart';

/// Email OTP two-step verification for family accounts (Supabase Auth).
///
/// Falls back to a deterministic local one-time code when Supabase email
/// delivery is unavailable (rate-limited, OTP signup disabled, no SMTP
/// configured). The fallback code is surfaced via [demoFallbackCode] so the
/// OTP dialog can display it in a clearly-labelled banner — this keeps the
/// flow demoable in development while preserving the real email OTP in
/// production.
class TwoFactorAuthService extends ChangeNotifier {
  TwoFactorAuthService._();
  static final TwoFactorAuthService instance = TwoFactorAuthService._();

  static const _prefsKeyPrefix = 'family_2fa_enabled_';

  String? _lastOtpEmail;
  String? _demoFallbackCode;
  DateTime? _demoFallbackIssuedAt;
  String? _demoFallbackReason;

  /// Code generated locally and emailed via Resend. When this is non-null,
  /// [verifyEmailOtp] will accept it as a valid token.
  String? _resendOtp;
  DateTime? _resendOtpIssuedAt;

  SupabaseClient get _client => Supabase.instance.client;

  String? get lastOtpEmail => _lastOtpEmail;

  /// When non-null, Supabase email delivery is currently unavailable and
  /// callers should display this code so the user can verify locally.
  ///
  /// Only surfaced to the UI in [kDebugMode] — production builds never show
  /// the demo banner. Verification will still accept the fallback in either
  /// build mode as a safety net.
  String? get demoFallbackCode {
    final issuedAt = _demoFallbackIssuedAt;
    if (_demoFallbackCode == null || issuedAt == null) return null;
    if (DateTime.now().difference(issuedAt) > const Duration(minutes: 10)) {
      _demoFallbackCode = null;
      _demoFallbackIssuedAt = null;
      _demoFallbackReason = null;
      return null;
    }
    return _demoFallbackCode;
  }

  /// Returns the demo code only when the UI should display it (debug builds).
  String? get visibleDemoFallbackCode => kDebugMode ? demoFallbackCode : null;

  /// Optional short reason shown alongside the demo code (e.g. rate-limited).
  String? get demoFallbackReason => _demoFallbackReason;

  /// True iff the most recent `sendEmailOtp` call resorted to a local code
  /// because Supabase email delivery failed. UI can use this to inform the
  /// user that email failed but verification is still possible.
  bool get isInFallbackMode => _demoFallbackCode != null;

  /// Whether 2FA is on for [userId] or the signed-in user.
  Future<bool> isEnabled({String? userId}) async {
    final uid = userId ?? _client.auth.currentUser?.id;
    if (uid == null) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('$_prefsKeyPrefix$uid') == true) return true;
    } catch (_) {}

    final user = _client.auth.currentUser;
    if (user != null && user.id == uid) {
      final meta = user.userMetadata ?? {};
      if (meta['family_2fa_enabled'] == true || meta['two_factor_enabled'] == true) {
        return true;
      }
    }

    try {
      final row = await _client
          .from('profiles')
          .select('extras')
          .eq('id', uid)
          .maybeSingle();
      if (row != null && row['extras'] is Map) {
        final extras = Map<String, dynamic>.from(row['extras'] as Map);
        final block = extras['family_2fa'];
        if (block is Map && block['enabled'] == true) return true;
      }
    } catch (_) {
      // TODO: profiles.extras column — local prefs + metadata still apply.
    }

    return false;
  }

  String resolveEmail({String? hintEmail}) {
    final sessionMail = _client.auth.currentUser?.email;
    final raw = (sessionMail != null && sessionMail.trim().isNotEmpty)
        ? sessionMail
        : (hintEmail ?? '');
    return raw.trim().toLowerCase();
  }

  /// Sends a one-time code to the account email (must match signed-in user).
  ///
  /// Delivery path:
  /// 1. If Resend is configured ([EmailConfig.isResendConfigured]) — generate
  ///    a 6-digit code locally and email it through Resend's REST API. Real,
  ///    branded message, independent of Supabase Email-OTP settings.
  /// 2. Otherwise, attempt Supabase's built-in `signInWithOtp` flow.
  /// 3. If both fail, fall back to a locally generated code that we surface
  ///    via [demoFallbackCode] (debug-build only on the UI).
  Future<void> sendEmailOtp({String? email}) async {
    final addr = resolveEmail(hintEmail: email);
    if (addr.isEmpty) {
      throw const AuthException(
        'No email on this account. Sign in with email to use two-step verification.',
      );
    }

    _lastOtpEmail = addr;

    if (EmailConfig.isResendConfigured) {
      try {
        final code = _generateOtp();
        await ResendEmailService.instance.sendEmail(
          to: addr,
          subject: 'Your BridgeCare verification code',
          html: ResendEmailService.verificationCodeHtml(code: code),
          text: 'Your BridgeCare verification code is: $code\n\n'
              'It expires in 10 minutes. If you did not request this code, '
              'you can safely ignore this email.',
        );
        _resendOtp = code;
        _resendOtpIssuedAt = DateTime.now();
        _demoFallbackCode = null;
        _demoFallbackIssuedAt = null;
        _demoFallbackReason = null;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Resend OTP send failed → trying Supabase fallback: $e');
      }
    }

    try {
      await _client.auth.signInWithOtp(
        email: addr,
        shouldCreateUser: false,
      );
      _resendOtp = null;
      _resendOtpIssuedAt = null;
      _demoFallbackCode = null;
      _demoFallbackIssuedAt = null;
      _demoFallbackReason = null;
      notifyListeners();
    } on AuthException catch (e) {
      _activateDemoFallback(e);
      notifyListeners();
    } catch (e) {
      _activateDemoFallback(e);
      notifyListeners();
    }
  }

  String _generateOtp() =>
      (Random.secure().nextInt(900000) + 100000).toString();

  /// Returns the most recently issued Resend-delivered code, or `null` if it
  /// has expired (>10 minutes old) or was already consumed.
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

  void _activateDemoFallback(Object cause) {
    final code = (Random.secure().nextInt(900000) + 100000).toString();
    _demoFallbackCode = code;
    _demoFallbackIssuedAt = DateTime.now();
    final blob = cause.toString().toLowerCase();
    if (blob.contains('rate') || blob.contains('too many') || blob.contains('429')) {
      _demoFallbackReason = 'Email is rate-limited right now';
    } else if (blob.contains('signup') || blob.contains('disabled')) {
      _demoFallbackReason = 'Email OTP not configured for this build';
    } else {
      _demoFallbackReason = 'Email delivery unavailable';
    }
  }

  /// Verifies the code from email (6–8 digits) or a magic-link token/hash.
  ///
  /// Also accepts the locally generated [demoFallbackCode] when Supabase
  /// email delivery was unavailable on the previous send.
  Future<void> verifyEmailOtp({
    required String token,
    String? email,
  }) async {
    final addr = resolveEmail(hintEmail: email ?? _lastOtpEmail);
    if (addr.isEmpty) {
      throw const AuthException('Missing email for verification.');
    }

    final parsed = _parseTokenInput(token);
    if (parsed.token == null && parsed.tokenHash == null) {
      throw const AuthException('Enter the code from your email.');
    }

    AuthException? lastError;

    if (parsed.token != null) {
      final cleaned = parsed.token!;
      if (cleaned.length < 6 || cleaned.length > 8) {
        throw const AuthException(
          'Enter the 6-digit code from your email (check spam).',
        );
      }

      final resendCode = _activeResendOtp;
      if (resendCode != null && cleaned == resendCode) {
        _lastOtpEmail = addr;
        _resendOtp = null;
        _resendOtpIssuedAt = null;
        notifyListeners();
        return;
      }

      final fallback = demoFallbackCode;
      if (fallback != null && cleaned == fallback) {
        _lastOtpEmail = addr;
        _demoFallbackCode = null;
        _demoFallbackIssuedAt = null;
        _demoFallbackReason = null;
        notifyListeners();
        return;
      }

      for (final type in const [OtpType.email, OtpType.magiclink]) {
        try {
          await _client.auth.verifyOTP(
            type: type,
            email: addr,
            token: cleaned,
          );
          _lastOtpEmail = addr;
          _demoFallbackCode = null;
          _demoFallbackIssuedAt = null;
          _demoFallbackReason = null;
          notifyListeners();
          return;
        } on AuthException catch (e) {
          lastError = AuthException(_friendlyOtpError(e));
        }
      }
    }

    if (parsed.tokenHash != null) {
      for (final type in const [OtpType.magiclink, OtpType.email]) {
        try {
          await _client.auth.verifyOTP(
            type: type,
            tokenHash: parsed.tokenHash,
          );
          _lastOtpEmail = addr;
          _demoFallbackCode = null;
          _demoFallbackIssuedAt = null;
          _demoFallbackReason = null;
          notifyListeners();
          return;
        } on AuthException catch (e) {
          lastError = AuthException(_friendlyOtpError(e));
        }
      }
    }

    throw lastError ??
        const AuthException(
          'Invalid code. Use the latest code from your email, or open the newest link.',
        );
  }

  Future<void> setEnabled(bool enabled, {String? email}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in again to change two-step verification.');
    }

    final merged = Map<String, dynamic>.from(user.userMetadata ?? {});
    merged['family_2fa_enabled'] = enabled;
    merged['two_factor_enabled'] = enabled;
    if (enabled) {
      merged['family_2fa_email'] = resolveEmail(hintEmail: email);
      merged['family_2fa_enabled_at'] = DateTime.now().toIso8601String();
    } else {
      merged.remove('family_2fa_email');
      merged.remove('family_2fa_enabled_at');
    }

    try {
      await _client.auth.updateUser(UserAttributes(data: merged));
    } on AuthException catch (e) {
      throw AuthException(_friendlyOtpError(e));
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefsKeyPrefix${user.id}', enabled);
    } catch (_) {}

    try {
      final existing = await _client
          .from('profiles')
          .select('extras')
          .eq('id', user.id)
          .maybeSingle();
      Map<String, dynamic> extras = {};
      if (existing != null && existing['extras'] is Map) {
        extras = Map<String, dynamic>.from(existing['extras'] as Map);
      }
      extras['family_2fa'] = {
        'enabled': enabled,
        'email': enabled ? resolveEmail(hintEmail: email) : null,
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _client.from('profiles').update({'extras': extras}).eq('id', user.id);
    } catch (_) {
      // TODO: persist when profiles table exists for this user.
    }

    notifyListeners();
  }

  String _friendlyOtpError(AuthException e) {
    final blob = '${e.message} ${e.code ?? ''} ${e.statusCode ?? ''}'.toLowerCase();
    if (blob.contains('rate') ||
        blob.contains('too_many') ||
        blob.contains('too many') ||
        blob.contains('429')) {
      return 'Too many attempts. Wait a minute, then tap Resend.';
    }
    if (blob.contains('expired') || blob.contains('otp_expired')) {
      return 'That code expired. Tap Resend for a new one.';
    }
    if (blob.contains('invalid') ||
        blob.contains('validation') ||
        blob.contains('otp')) {
      return 'Invalid code. Use the latest code from your email.';
    }
    if (blob.contains('email_address_invalid') || blob.contains('invalid email')) {
      return 'This email address is not valid for verification.';
    }
    if (blob.contains('signups not allowed') || blob.contains('signup_disabled')) {
      return 'Email OTP is disabled in Supabase Auth settings for this project.';
    }
    return e.message;
  }

  ({String? token, String? tokenHash}) _parseTokenInput(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return (token: null, tokenHash: null);

    Uri? uri = Uri.tryParse(trimmed);
    if (uri == null && trimmed.contains('token=')) {
      uri = Uri.tryParse('https://local?$trimmed');
    }
    if (uri != null) {
      final fragment = uri.fragment.isNotEmpty
          ? Uri.splitQueryString(uri.fragment)
          : const <String, String>{};
      final hash = uri.queryParameters['token_hash'] ??
          uri.queryParameters['token'] ??
          fragment['token_hash'] ??
          fragment['access_token'];
      if (hash != null && hash.length >= 20) {
        return (token: null, tokenHash: hash);
      }
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        final digits = code.replaceAll(RegExp(r'\D'), '');
        if (digits.length >= 6) return (token: digits, tokenHash: null);
      }
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 6 && digitsOnly.length <= 8) {
      return (token: digitsOnly, tokenHash: null);
    }
    if (trimmed.length >= 20 && !trimmed.contains(' ')) {
      return (token: null, tokenHash: trimmed);
    }

    return (token: null, tokenHash: null);
  }
}
