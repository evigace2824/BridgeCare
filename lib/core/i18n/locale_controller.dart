import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App-wide locale state.
/// Kept as a singleton so any feature (home/profile/settings) can switch
/// language and the whole UI rebuilds immediately.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  String _code = 'en';
  String get code => _code;
  Locale get locale => Locale(_code);

  void setCode(String value) {
    if (value != 'en' && value != 'sq') return;
    if (_code == value) return;
    _code = value;
    notifyListeners();
  }
}

