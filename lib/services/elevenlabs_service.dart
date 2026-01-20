import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class ElevenLabsService {
  final String apiKey;
  final String voiceId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, String> _cache = {};

  ElevenLabsService({
    required this.apiKey,
    this.voiceId = '21m00Tcm4TlvDq8ikWAM', // Default voice
  });

  Future<Uint8List?> synthesizeSpeech(String text) async {
    if (_cache.containsKey(text)) {
      final cachedPath = _cache[text]!;
      final file = File(cachedPath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
    }

    try {
      final response = await http.post(
        Uri.parse('https://api.elevenlabs.io/v1/text-to-speech/$voiceId'),
        headers: {
          'xi-api-key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.5,
          },
        }),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> playAudio(Uint8List audioBytes, {String? cacheKey}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/audio_$timestamp.mp3');
      
      await tempFile.writeAsBytes(audioBytes);

      if (cacheKey != null) {
        _cache[cacheKey] = tempFile.path;
      }

      await _audioPlayer.play(DeviceFileSource(tempFile.path));

      _audioPlayer.onPlayerComplete.listen((_) async {
        if (cacheKey == null) {
          await tempFile.delete();
        }
      });
    } catch (e) {
      // Silently fail - audio is optional
    }
  }

  Future<void> speak(String text) async {
    final audioBytes = await synthesizeSpeech(text);
    if (audioBytes != null) {
      await playAudio(audioBytes, cacheKey: text);
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
