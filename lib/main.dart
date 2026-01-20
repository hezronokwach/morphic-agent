import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/morphic_state.dart' as morphic;
import 'services/gemini_service.dart';
import 'services/speech_service.dart';
import 'services/elevenlabs_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
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

  late GeminiService _geminiService;
  late SpeechService _speechService;
  late ElevenLabsService _elevenLabsService;

  morphic.MorphicState get currentState => _currentState;
  bool get isProcessing => _isProcessing;

  void initialize() {
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    
    _geminiService = GeminiService(apiKey: geminiKey);
    _speechService = SpeechService();
    _elevenLabsService = ElevenLabsService(apiKey: elevenLabsKey);
  }

  Future<void> processVoiceInput(String transcription) async {
    print('\n🔄 START processVoiceInput: $transcription');
    _isProcessing = true;
    notifyListeners();

    try {
      _conversationHistory.add(transcription);
      
      print('🔄 Calling Gemini...');
      _currentState = await _geminiService.analyzeQuery(transcription);
      print('🔄 State updated: ${_currentState.uiMode}, data keys: ${_currentState.data.keys.toList()}');
      notifyListeners();
      print('🔄 notifyListeners() called');

      _elevenLabsService.speak(_currentState.narrative);
    } catch (e) {
      print('🔴 ERROR in processVoiceInput: $e');
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
      print('🔄 END processVoiceInput\n');
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
