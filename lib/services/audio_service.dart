import 'dart:io';

class AudioService {
  AudioService._();

  static final AudioService instance = AudioService._();
  Process? _speechProcess;

  Future<void> speak(String text, {String? languageCode}) async {
    final safeText = text.replaceAll("'", "''");
    if (Platform.isWindows) {
      await stop();
      _speechProcess = await Process.start(
        'powershell',
        [
          '-NoProfile',
          '-Command',
          "Add-Type -AssemblyName System.Speech; "
              r"$s = New-Object System.Speech.Synthesis.SpeechSynthesizer; "
              "\$s.Speak('$safeText');",
        ],
      );
      await _speechProcess?.exitCode;
      return;
    }
    await Future<void>.value();
  }

  Future<void> stop() async {
    final p = _speechProcess;
    if (p != null) {
      p.kill();
      _speechProcess = null;
    }
  }
}
