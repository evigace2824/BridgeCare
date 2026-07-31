import 'dart:async';
import 'dart:io';

/// Persistent loopback HTTP server that captures **password-recovery** (and
/// any other auth) callbacks while the app is running.
///
/// Unlike [captureOAuthRedirectOnce] (one-shot, used during OAuth where the
/// app *just* opened the browser), recovery links are clicked from the user's
/// email at an arbitrary time — sometimes minutes later, possibly in a
/// different browser tab. We need to keep a server up so the click always
/// lands somewhere.
///
/// On every valid request the server returns a friendly "you can close this
/// tab" page and forwards the URI through [onCallback].
class LoopbackAuthCallbackServer {
  LoopbackAuthCallbackServer._(this._server, this._sub);

  final HttpServer _server;
  final StreamSubscription<HttpRequest> _sub;
  var _closed = false;

  /// Binds [port] on loopback (IPv4 by default; pass `ipv6Loopback: true` to
  /// bind `[::1]` instead — useful when the OS resolves `localhost` to v6).
  ///
  /// Returns `null` if the port is already taken (so callers can decide
  /// whether to surface a fallback paste UI).
  static Future<LoopbackAuthCallbackServer?> start({
    required int port,
    required void Function(Uri uri) onCallback,
    bool ipv6Loopback = false,
  }) async {
    final bindAddr = ipv6Loopback
        ? InternetAddress.loopbackIPv6
        : InternetAddress.loopbackIPv4;

    HttpServer server;
    try {
      server = await HttpServer.bind(bindAddr, port);
    } catch (_) {
      return null;
    }

    late final StreamSubscription<HttpRequest> sub;
    sub = server.listen((req) async {
      try {
        if (req.uri.path == '/favicon.ico') {
          req.response.statusCode = 204;
          await req.response.close();
          return;
        }
        final uri = req.requestedUri;
        final isAuth = _looksLikeAuthCallback(uri);

        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.html;
        req.response.write(_callbackHtml(isAuth));
        await req.response.close();

        if (isAuth) {
          final normalized = _normalizeOAuthCallbackUri(uri);
          onCallback(normalized);
        }
      } catch (_) {
        try {
          await req.response.close();
        } catch (_) {}
      }
    });

    return LoopbackAuthCallbackServer._(server, sub);
  }

  /// Closes the server and cancels the listener. Safe to call multiple times.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _sub.cancel();
    await _server.close(force: true);
  }
}

/// True for any URL that looks like an auth callback (OAuth or recovery).
bool _looksLikeAuthCallback(Uri uri) {
  bool hasAny(Map<String, String> map) =>
      map.containsKey('code') ||
      map.containsKey('error') ||
      map.containsKey('access_token') ||
      map.containsKey('refresh_token') ||
      map['type'] == 'recovery';

  if (hasAny(uri.queryParameters)) return true;
  if (uri.fragment.isEmpty) return false;
  return hasAny(Uri.splitQueryString(uri.fragment));
}

String _callbackHtml(bool ok) {
  final title = ok ? 'You can close this window.' : 'Nothing to do here.';
  final body = ok
      ? 'BridgeCare picked up your link. Return to the app to continue.'
      : 'This URL did not contain a recognized authentication code.';
  return '<!DOCTYPE html><html><head><meta charset="utf-8">'
      '<title>BridgeCare</title>'
      '<style>body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;'
      'background:#F5F6F8;color:#101828;display:flex;align-items:center;'
      'justify-content:center;min-height:100vh;margin:0}'
      '.card{background:#fff;border:1px solid #E4E7EC;border-radius:16px;'
      'padding:36px 40px;max-width:420px;text-align:center;'
      'box-shadow:0 4px 24px rgba(16,24,40,0.06)}'
      'h1{font-size:20px;margin:0 0 8px;color:#2D5BFF}'
      'p{margin:0;color:#475467;line-height:1.5}'
      '</style></head><body><div class="card">'
      '<h1>$title</h1><p>$body</p></div></body></html>';
}

bool _oauthCallbackLooksValid(Uri uri) {
  if (uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('error')) {
    return true;
  }
  if (uri.fragment.isEmpty) return false;
  final frag = Uri.splitQueryString(uri.fragment);
  return frag.containsKey('code') || frag.containsKey('error');
}

/// Some providers return `code` in the fragment; GoTrue PKCE expects query.
Uri _normalizeOAuthCallbackUri(Uri uri) {
  if (uri.queryParameters.containsKey('code') ||
      uri.queryParameters.containsKey('error')) {
    return uri;
  }
  if (uri.fragment.isEmpty) return uri;
  final frag = Uri.splitQueryString(uri.fragment);
  if (!frag.containsKey('code') && !frag.containsKey('error')) return uri;
  final merged = Map<String, String>.from(uri.queryParameters);
  frag.forEach((k, v) => merged[k] = v);
  return uri.replace(queryParameters: merged, fragment: '');
}

/// Binds [port] on loopback (IPv4 127.0.0.1 or IPv6 ::1), calls
/// [afterServerListening] after listening starts, then returns the OAuth callback
/// URI (`code` or `error` in query or fragment).
Future<Uri?> captureOAuthRedirectOnce({
  required int port,
  Future<void> Function()? afterServerListening,
  bool ipv6Loopback = false,
  Duration timeout = const Duration(minutes: 5),
}) async {
  late HttpServer server;
  final bindAddr =
      ipv6Loopback ? InternetAddress.loopbackIPv6 : InternetAddress.loopbackIPv4;
  try {
    server = await HttpServer.bind(bindAddr, port);
  } catch (_) {
    return null;
  }

  var openedBrowser = false;

  try {
    while (true) {
      final nextRequest = server.first.timeout(timeout);
      if (!openedBrowser) {
        if (afterServerListening != null) {
          await afterServerListening();
        }
        openedBrowser = true;
      }
      final req = await nextRequest;
      if (req.uri.path == '/favicon.ico') {
        await req.response.close();
        continue;
      }
      final uri = req.requestedUri;
      if (!_oauthCallbackLooksValid(uri)) {
        req.response.statusCode = 204;
        await req.response.close();
        continue;
      }
      final normalized = _normalizeOAuthCallbackUri(uri);
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.html;
      req.response.write(
        '<!DOCTYPE html><html><body style="font-family:system-ui;text-align:center;'
        'padding:2rem">You can close this window and return to BridgeCare.</body></html>',
      );
      await req.response.close();
      return normalized;
    }
  } on TimeoutException {
    return null;
  } finally {
    await server.close(force: true);
  }
}
