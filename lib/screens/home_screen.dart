import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/morphic_container.dart';
import '../utils/demo_mode.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isListening = false;
  bool _isDemoMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.initialize();
      appState.initializeSpeech();
    });
  }

  Future<void> _handleMicPress() async {
    final appState = context.read<AppState>();
    
    setState(() => _isListening = true);
    
    try {
      final transcription = await appState.speechService.listen();
      if (transcription.isNotEmpty) {
        await appState.processVoiceInput(transcription);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shoe Store Assistant'),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showDemoModeDialog,
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  appState.currentState.narrative,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: MorphicContainer(state: appState.currentState),
              ),
              _buildBottomControls(appState),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomControls(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.large(
            onPressed: appState.isProcessing ? null : _handleMicPress,
            backgroundColor: _isListening
                ? Colors.red
                : appState.isProcessing
                    ? Colors.grey
                    : const Color(0xFF1976D2),
            child: appState.isProcessing
                ? const CircularProgressIndicator(color: Colors.white)
                : Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Reset to initial state
            },
          ),
        ],
      ),
    );
  }

  void _showDemoModeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demo Mode'),
        content: const Text('Run automated demo with predefined queries?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runDemoMode();
            },
            child: const Text('Start Demo'),
          ),
        ],
      ),
    );
  }

  Future<void> _runDemoMode() async {
    setState(() => _isDemoMode = true);
    final appState = context.read<AppState>();
    await DemoMode.runDemo(appState);
    setState(() => _isDemoMode = false);
  }
}
