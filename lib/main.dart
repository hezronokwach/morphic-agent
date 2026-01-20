import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/morphic_state.dart' as morphic;
import 'services/openai_service.dart';
import 'services/speech_service.dart';
import 'services/elevenlabs_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  morphic.MorphicState _currentState = morphic.MorphicState.initial();
  final List<String> _conversationHistory = [];
  bool _isProcessing = false;

  late OpenAIService _openAIService;
  late SpeechService _speechService;
  late ElevenLabsService _elevenLabsService;

  morphic.MorphicState get currentState => _currentState;
  bool get isProcessing => _isProcessing;

  void initialize(String openAIKey, String elevenLabsKey) {
    _openAIService = OpenAIService(apiKey: openAIKey);
    _speechService = SpeechService();
    _elevenLabsService = ElevenLabsService(apiKey: elevenLabsKey);
  }

  Future<void> processVoiceInput(String transcription) async {
    _isProcessing = true;
    notifyListeners();

    try {
      _conversationHistory.add(transcription);
      
      _currentState = await _openAIService.analyzeQuery(transcription);
      notifyListeners();

      _elevenLabsService.speak(_currentState.narrative);
    } catch (e) {
      _currentState = morphic.MorphicState(
        intent: morphic.Intent.unknown,
        uiMode: morphic.UIMode.narrative,
        narrative: 'Sorry, something went wrong. Please try again.',
        confidence: 0.0,
      );
      notifyListeners();
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<void> initializeSpeech() async {
    await _speechService.initialize();
  }

  SpeechService get speechService => _speechService;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morphic Voice Agent',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}
