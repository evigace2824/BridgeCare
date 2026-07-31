import 'package:flutter/foundation.dart' show kIsWeb;

/// Replace with your Supabase project URL and anon key from the dashboard
/// (Settings → API). For production, prefer `--dart-define` or a secrets tool.
///
/// **Google OAuth:** enable Google under Authentication → Sign In / Providers;
/// in Google Cloud, set the redirect URI to Supabase’s `…/auth/v1/callback`;
/// in Supabase URL Configuration add `carebridge://login-callback` (mobile) and
/// `http://127.0.0.1:54721/` (desktop, default port). If Google never returns to
/// the app, also add `http://localhost:54721/` there, or run with
/// `--dart-define=OAUTH_DESKTOP_LOCALHOST=true` (uses localhost + IPv6 loopback).
class SupabaseConfig {
  SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rwoukovwoiqykgverdns.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ3b3Vrb3Z3b2lxeWtndmVyZG5zIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU2MzM2MzUsImV4cCI6MjA5MTIwOTYzNX0.KjxMtqRUF7K2owLjxuVS3D76etLcEFSzuAaGGanXtFk',
  );

  /// OAuth redirect: add this exact URL in Supabase → Authentication → URL Configuration
  /// (Redirect URLs). Must match Android intent-filter + iOS URL scheme below.
  static const String _oauthRedirectNative = String.fromEnvironment(
    'OAUTH_REDIRECT_URL',
    defaultValue: 'carebridge://login-callback',
  );

  /// Public site URL for **web** OAuth (e.g. https://yourapp.web.app). Optional.
  static const String siteUrl = String.fromEnvironment(
    'SITE_URL',
    defaultValue: '',
  );

  /// Value passed to [signInWithOAuth] as `redirectTo`.
  static String? get oauthRedirectUri {
    if (kIsWeb) {
      if (siteUrl.isNotEmpty) return siteUrl;
      try {
        return Uri.base.origin;
      } catch (_) {
        return null;
      }
    }
    return _oauthRedirectNative;
  }

  /// Windows / macOS / Linux: local HTTP callback for OAuth (PKCE). Add this
  /// exact URL under Supabase → Authentication → URL Configuration → Redirect URLs.
  static const int oauthDesktopPort = int.fromEnvironment(
    'OAUTH_DESKTOP_PORT',
    defaultValue: 54721,
  );

  /// When true, use `http://localhost:<port>/` and bind [::1] (helps when the
  /// browser uses IPv6 for "localhost").
  static const bool oauthDesktopUseLocalhost = bool.fromEnvironment(
    'OAUTH_DESKTOP_LOCALHOST',
    defaultValue: false,
  );

  static String get oauthDesktopRedirectUri => oauthDesktopUseLocalhost
      ? 'http://localhost:$oauthDesktopPort/'
      : 'http://127.0.0.1:$oauthDesktopPort/';
}
