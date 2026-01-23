import 'package:flutter_tts/flutter_tts.dart';

class VoiceGuidanceService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  DateTime? _lastSpeakTime;
  String? _lastMessage;
  
  // Minimum time between same messages to avoid repetition annoyance
  static const Duration _repeatInterval = Duration(seconds: 5);
  // Minimum time between any messages
  static const Duration _minInterval = Duration(seconds: 2);

  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((msg) {
      _isSpeaking = false;
    });
  }

  Future<void> speak(String message, {bool force = false}) async {
    final now = DateTime.now();

    // Don't interrupt if currently speaking unless forced
    if (_isSpeaking && !force) return;

    // throttling
    if (!force) {
      if (_lastSpeakTime != null) {
        if (now.difference(_lastSpeakTime!) < _minInterval) return;
      }
      
      if (_lastMessage == message && _lastSpeakTime != null) {
        if (now.difference(_lastSpeakTime!) < _repeatInterval) return;
      }
    }

    _lastMessage = message;
    _lastSpeakTime = now;
    await _flutterTts.speak(message);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }
}
