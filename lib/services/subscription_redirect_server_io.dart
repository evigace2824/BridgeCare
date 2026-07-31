import 'dart:async';
import 'dart:io';

/// Desktop loopback server for Stripe Checkout return (`?session_id=`).
Future<String?> captureSubscriptionReturnOnce({
  required int port,
  Future<void> Function()? afterServerListening,
  bool ipv6Loopback = false,
  Duration timeout = const Duration(minutes: 10),
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

  var opened = false;

  try {
    while (true) {
      final req = await server.first.timeout(timeout);
      if (!opened) {
        await afterServerListening?.call();
        opened = true;
      }

      if (req.uri.path == '/favicon.ico') {
        req.response.statusCode = 204;
        await req.response.close();
        continue;
      }

      final qp = req.uri.queryParameters;
      if (qp.containsKey('cancelled')) {
        req.response.statusCode = 200;
        req.response.headers.contentType = ContentType.html;
        req.response.write(_html(cancelled: true));
        await req.response.close();
        return null;
      }

      final sessionId = qp['session_id'];
      req.response.statusCode = 200;
      req.response.headers.contentType = ContentType.html;
      req.response.write(_html(cancelled: false));
      await req.response.close();

      if (sessionId != null && sessionId.isNotEmpty) return sessionId;
    }
  } on TimeoutException {
    return null;
  } finally {
    await server.close(force: true);
  }
}

String _html({required bool cancelled}) {
  final title = cancelled ? 'Checkout cancelled' : 'Payment received!';
  final body = cancelled
      ? 'You can close this window and return to BridgeCare.'
      : 'BridgeCare is activating your premium plan. You can close this window.';
  return '<!DOCTYPE html><html><head><meta charset="utf-8"><title>BridgeCare</title>'
      '<style>body{font-family:system-ui,sans-serif;background:#F5F8FC;'
      'display:flex;align-items:center;justify-content:center;min-height:100vh;margin:0}'
      '.card{background:#fff;border-radius:16px;padding:32px;text-align:center;'
      'max-width:400px;box-shadow:0 4px 24px rgba(0,0,0,.08)}'
      'h1{color:#7C3AED;font-size:20px}</style></head><body>'
      '<div class="card"><h1>$title</h1><p>$body</p></div></body></html>';
}
