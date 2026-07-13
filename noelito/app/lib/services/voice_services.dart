import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SttService {
  final SpeechToText _stt = SpeechToText();
  bool _ready = false;

  Future<bool> init() async {
    _ready = await _stt.initialize();
    return _ready;
  }

  bool get isListening => _stt.isListening;

  /// Escucha una frase y devuelve el texto final (o null si no entendió).
  Future<String?> listenOnce({
    void Function(String partial)? onPartial,
  }) async {
    if (!_ready && !await init()) return null;

    String finalText = '';
    await _stt.listen(
      localeId: 'es_419', // español latino; cae a es_ES si no existe
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onResult: (r) {
        onPartial?.call(r.recognizedWords);
        if (r.finalResult) finalText = r.recognizedWords;
      },
    );

    // Espera a que termine la sesión de escucha
    while (_stt.isListening) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    return finalText.isEmpty ? null : finalText;
  }

  Future<void> stop() => _stt.stop();
}

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _configured = false;

  Future<void> _config() async {
    if (_configured) return;
    await _tts.setLanguage('es-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _configured = true;
  }

  Future<void> speak(String text) async {
    await _config();
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
