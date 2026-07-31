/// Web: subscription return handled via URL / manual refresh.
Future<String?> captureSubscriptionReturnOnce({
  required int port,
  Future<void> Function()? afterServerListening,
  bool ipv6Loopback = false,
  Duration timeout = const Duration(minutes: 10),
}) async =>
    null;
