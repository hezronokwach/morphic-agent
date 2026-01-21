enum UIMode { table, chart, image, narrative, action }

enum Intent { inventory, finance, retail, unknown, updateStock, addProduct, deleteProduct, accountBalance }

class MorphicState {
  final Intent intent;
  final UIMode uiMode;
  final String narrative;
  final String? headerText;
  final Map<String, dynamic> data;
  final double confidence;

  MorphicState({
    required this.intent,
    required this.uiMode,
    required this.narrative,
    this.headerText,
    this.data = const {},
    this.confidence = 1.0,
  });

  factory MorphicState.initial() {
    return MorphicState(
      intent: Intent.unknown,
      uiMode: UIMode.narrative,
      narrative: 'Hello! Ask me about inventory, finances, or products.',
    );
  }
}
