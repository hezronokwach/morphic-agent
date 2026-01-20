import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastTranscription = '';

  bool get isListening => _isListening;
  String get lastTranscription => _lastTranscription;

  Future<bool> initialize() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    return await _speech.initialize(
      onError: (error) => _isListening = false,
      onStatus: (status) => _isListening = status == 'listening',
    );
  }

  Future<String> listen({
    Function(String)? onResult,
    Function(String)? onStatus,
  }) async {
    if (!_speech.isAvailable) {
      throw Exception('Speech recognition not available');
    }

    _lastTranscription = '';
    _isListening = true;

    await _speech.listen(
      onResult: (result) {
        _lastTranscription = result.recognizedWords;
        if (onResult != null) {
          onResult(_lastTranscription);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
    );

    while (_isListening) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return _lastTranscription;
  }

  Future<void> stop() async {
    await _speech.stop();
    _isListening = false;
  }

  void dispose() {
    _speech.cancel();
  }
}
