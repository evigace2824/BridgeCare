import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/email_config.dart';

/// Thin wrapper around Resend's REST API (`POST /emails`).
///
/// Used by [TwoFactorAuthService] when [EmailConfig.isResendConfigured] is
/// true — that lets us send a real branded 2FA email without depending on
/// Supabase's `signInWithOtp` (which requires Email-OTP to be explicitly
/// enabled in the project's Auth → Providers settings).
class ResendEmailService {
  ResendEmailService._();
  static final ResendEmailService instance = ResendEmailService._();

  static final Uri _endpoint = Uri.parse('https://api.resend.com/emails');

  /// Sends a single email through Resend.
  ///
  /// Throws [ResendException] when the API call fails (network error,
  /// auth error, invalid recipient, etc.).
  Future<void> sendEmail({
    required String to,
    required String subject,
    required String html,
    String? text,
    String? from,
  }) async {
    if (!EmailConfig.isResendConfigured) {
      throw ResendException(
        'Resend API key not configured. Pass --dart-define=RESEND_API_KEY=re_… '
        'or fill `EmailConfig.resendApiKey` in lib/core/email_config.dart.',
      );
    }

    http.Response response;
    try {
      response = await http.post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer ${EmailConfig.resendApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': from ?? EmailConfig.resendFromAddress,
          'to': [to],
          'subject': subject,
          'html': html,
          if (text != null) 'text': text,
        }),
      );
    } catch (e) {
      throw ResendException('Network error sending email: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) return;

    String message = 'Resend API error (${response.statusCode})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['message'] is String) {
        message = decoded['message'] as String;
      }
    } catch (_) {}
    throw ResendException(message);
  }

  /// Branded HTML for the 2FA verification code email.
  static String verificationCodeHtml({
    required String code,
    String productName = 'BridgeCare',
  }) {
    return '''
<!doctype html>
<html>
  <body style="margin:0;padding:0;background:#F0F4FF;font-family:-apple-system,Segoe UI,Roboto,Helvetica,Arial,sans-serif;">
    <table width="100%" cellpadding="0" cellspacing="0" border="0" style="padding:32px 16px;">
      <tr>
        <td align="center">
          <table width="100%" style="max-width:480px;background:#ffffff;border-radius:18px;border:1px solid #E2E8F0;padding:32px;">
            <tr>
              <td style="padding-bottom:12px;">
                <div style="display:inline-block;width:42px;height:42px;border-radius:12px;background:linear-gradient(135deg,#1976D2,#24B6A8);text-align:center;line-height:42px;color:#fff;font-weight:800;font-size:18px;">CB</div>
              </td>
            </tr>
            <tr>
              <td style="padding:8px 0 4px;font-size:22px;font-weight:800;color:#0F172A;letter-spacing:-0.3px;">
                Your verification code
              </td>
            </tr>
            <tr>
              <td style="padding-bottom:18px;color:#475569;font-size:14px;line-height:1.5;">
                Enter this code in $productName to finish signing in. The code
                expires in 10 minutes. If you didn't request it, you can safely
                ignore this email.
              </td>
            </tr>
            <tr>
              <td>
                <div style="background:#F1F5FF;border:1px solid #C7D2FE;border-radius:14px;padding:18px;text-align:center;font-family:'SF Mono',Menlo,Consolas,monospace;font-size:30px;font-weight:900;letter-spacing:10px;color:#1E293B;">
                  $code
                </div>
              </td>
            </tr>
            <tr>
              <td style="padding-top:18px;color:#94A3B8;font-size:12px;line-height:1.5;">
                Sent by $productName — never share this code with anyone, not
                even support.
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  </body>
</html>
''';
  }
}

class ResendException implements Exception {
  ResendException(this.message);
  final String message;
  @override
  String toString() => message;
}
