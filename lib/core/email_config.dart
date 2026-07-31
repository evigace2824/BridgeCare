/// Configuration for transactional email sending (Resend).
///
/// **Setup**: paste your Resend API key into [resendApiKey] below, or pass it
/// at run-time via `--dart-define=RESEND_API_KEY=re_xxxxx`. The key is what
/// you generated at https://resend.com → API Keys.
///
/// When [resendApiKey] is non-empty the app delivers 2FA codes through
/// Resend's REST API directly (no dependency on Supabase Email-OTP being
/// enabled). When empty the app falls back to Supabase's built-in OTP.
class EmailConfig {
  EmailConfig._();

  /// Resend API key — starts with `re_`. Leave empty in source if you'd
  /// rather pass via `--dart-define`. **Do not commit a real key to git.**
  static const String resendApiKey = String.fromEnvironment(
    'RESEND_API_KEY',
    defaultValue: '',
  );

  /// "From" header for outgoing BridgeCare emails. The default uses
  /// Resend's sandbox sender which works without DNS verification.
  /// Once you verify your own domain in Resend, switch this to
  /// `BridgeCare <noreply@yourdomain.com>`.
  static const String resendFromAddress = String.fromEnvironment(
    'RESEND_FROM',
    defaultValue: 'BridgeCare <onboarding@resend.dev>',
  );

  /// True when the Resend integration is configured. Callers should use
  /// this to decide whether to attempt Resend delivery before falling back
  /// to Supabase.
  static bool get isResendConfigured => resendApiKey.isNotEmpty;
}
