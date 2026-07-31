import 'dart:async';

/// Web / VM-without-io: loopback OAuth not used.
Future<Uri?> captureOAuthRedirectOnce({
  required int port,
  Future<void> Function()? afterServerListening,
  bool ipv6Loopback = false,
  Duration timeout = const Duration(minutes: 5),
}) async =>
    null;

/// Web stub: there is no native loopback HTTP server in browsers.
class LoopbackAuthCallbackServer {
  LoopbackAuthCallbackServer._();

  static Future<LoopbackAuthCallbackServer?> start({
    required int port,
    required void Function(Uri uri) onCallback,
    bool ipv6Loopback = false,
  }) async =>
      null;

  Future<void> close() async {}
}
