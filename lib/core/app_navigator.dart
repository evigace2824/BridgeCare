import 'package:flutter/material.dart';

import '../features/auth/screens/reset_password_screen.dart';

/// Top-level navigator key shared by `MaterialApp.navigatorKey` and the global
/// auth listener. Lets non-widget code (e.g. [AuthService.processRecoveryUrl])
/// push routes without holding a `BuildContext`.
final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Internal flag: are we already on (or pushing) the reset-password screen?
/// Prevents double-pushes when both the loopback listener AND
/// `AuthChangeEvent.passwordRecovery` fire for the same recovery URL.
bool _isOnResetPasswordScreen = false;

/// Push [ResetPasswordScreen] once, ignoring redundant calls. Returns the
/// navigator state used (null if no navigator is mounted, e.g. before the
/// first frame).
NavigatorState? goToResetPasswordOnce() {
  if (_isOnResetPasswordScreen) return rootNavigatorKey.currentState;
  final navigator = rootNavigatorKey.currentState;
  if (navigator == null) return null;
  _isOnResetPasswordScreen = true;
  navigator
      .push(
        MaterialPageRoute(
          builder: (_) => const ResetPasswordScreen(),
        ),
      )
      .whenComplete(() => _isOnResetPasswordScreen = false);
  return navigator;
}
