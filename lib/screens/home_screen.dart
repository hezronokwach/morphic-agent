import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../widgets/morphic_container.dart';
import '../utils/demo_mode.dart';
import '../utils/app_theme.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool _isListening = false;
  late AnimationController _pulseController;
  late AnimationController _shineController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.initialize();
      appState.initializeSpeech();
      appState.preloadImages(context);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _handleMicPress() async {
    HapticFeedback.heavyImpact();
    final appState = context.read<AppState>();
    setState(() => _isListening = true);
    
    try {
      final transcription = await appState.speechService.listen(
        onResult: (partialResult) {
          appState.updateTranscription(partialResult);
        },
      );
      if (transcription.isNotEmpty) {
        await appState.processVoiceInput(transcription);
      }
    } catch (e) {
      HapticFeedback.heavyImpact();
    } finally {
      setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      body: Stack(
        children: [
          _buildBackgroundPattern(),
          Consumer<AppState>(
            builder: (context, appState, child) {
              return SafeArea(
                child: Column(
                  children: [
                    _buildHeader(appState),
                    if (appState.lastTranscription.isNotEmpty)
                      _buildTranscriptionBadge(appState.lastTranscription),
                    Expanded(
                      child: appState.isProcessing
                          ? _buildLoadingState()
                          : AnimatedSwitcher(
                              duration: AppTheme.medium,
                              child: MorphicContainer(
                                key: ValueKey(appState.currentState.uiMode),
                                state: appState.currentState,
                                onActionConfirm: appState.handleActionConfirm,
                                onActionCancel: appState.handleActionCancel,
                              ),
                            ),
                    ),
                    _buildMicButton(appState),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: CustomPaint(
        painter: BackgroundPatternPainter(),
      ),
    );
  }

  Widget _buildHeader(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.sm),
      child: const Text(
        'MORPHIC AI',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.black,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildTranscriptionBadge(String text) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.md, vertical: AppTheme.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.sm, vertical: AppTheme.xs),
      decoration: BoxDecoration(
        color: AppTheme.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$text"',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.black,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppTheme.lg),
        decoration: AppTheme.whiteCard(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppTheme.orangeGradient,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                  strokeWidth: 3,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.md),
            const Text('Processing...', style: AppTheme.narrativeText),
          ],
        ),
      ),
    );
  }

  Widget _buildMicButton(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.md),
      child: GestureDetector(
        onTap: appState.isProcessing ? null : _handleMicPress,
        child: AnimatedContainer(
          duration: AppTheme.fast,
          width: 72,
          height: 72,
          decoration: _isListening
              ? AppTheme.orangeButton()
              : AppTheme.blackCard(borderRadius: 36),
          child: Icon(
            _isListening ? Icons.mic : Icons.mic_none,
            size: 32,
            color: _isListening ? AppTheme.white : AppTheme.orange,
          ),
        ),
      ),
    );
  }


}

class BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.emerald.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x + 25, y + 25), 3, paint);
        canvas.drawCircle(Offset(x, y), 1.5, paint..color = AppTheme.emerald.withValues(alpha: 0.02));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
