
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:nexus_ai/services/storage_service.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Dio _dio = Dio();
  final StorageService _storage = StorageService();

  // Default Voice: Rachel (American, Calm)
  static const String _defaultVoiceId = "21m00Tcm4TlvDq8ikWAM"; 

  Future<void> playTextToSpeech(String text) async {
    final apiKey = _storage.getApiKey('elevenlabs');
    if (apiKey == null || apiKey.isEmpty) {
      print("No ElevenLabs Key found.");
      return; 
    }

    try {
      final response = await _dio.post(
        'https://api.elevenlabs.io/v1/text-to-speech/$_defaultVoiceId',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'xi-api-key': apiKey,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          "text": text,
          "model_id": "eleven_monolingual_v1",
          "voice_settings": {
            "stability": 0.5,
            "similarity_boost": 0.5
          }
        },
      );

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/speech.mp3');
        await file.writeAsBytes(response.data);
        
        await _audioPlayer.play(DeviceFileSource(file.path));
      } else {
        print("ElevenLabs Error: ${response.statusCode}");
      }
    } catch (e) {
      print("TTS Error: $e");
    }
  }

  void stop() {
    _audioPlayer.stop();
  }
}
