import 'package:flutter/cupertino.dart';

/// Patient-side navigation helpers — Cupertino-style transitions read as
/// native on mobile (§10).
abstract final class PatientNav {
  PatientNav._();

  static Route<T> route<T extends Object?>(Widget page) =>
      CupertinoPageRoute<T>(builder: (_) => page);

  static Future<T?> push<T extends Object?>(
    BuildContext context,
    Widget page,
  ) =>
      Navigator.of(context).push<T>(route<T>(page));
}
