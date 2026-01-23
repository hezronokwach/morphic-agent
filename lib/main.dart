import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'models/morphic_state.dart' as morphic;
import 'models/business_data.dart';
import 'services/gemini_service.dart';
import 'services/speech_service.dart';
import 'services/elevenlabs_service.dart';
import 'services/supabase_service.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await SupabaseService.initialize(supabaseUrl, supabaseAnonKey);
  }
  
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
  String _lastTranscription = '';

  late GeminiService _geminiService;
  late SpeechService _speechService;
  late ElevenLabsService _elevenLabsService;

  morphic.MorphicState get currentState => _currentState;
  bool get isProcessing => _isProcessing;
  String get lastTranscription => _lastTranscription;

  void initialize() {
    final geminiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    final elevenLabsKey = dotenv.env['ELEVENLABS_API_KEY'] ?? '';
    
    _geminiService = GeminiService(apiKey: geminiKey);
    _speechService = SpeechService();
    _elevenLabsService = ElevenLabsService(apiKey: elevenLabsKey);
  }

  Future<void> preloadImages(BuildContext context) async {
    final products = await BusinessData.getProducts();
    for (var product in products) {
      try {
        await precacheImage(NetworkImage(product.imageUrl), context);
      } catch (e) {
        // Silently handle image preload failures
      }
    }
  }

  Future<void> processVoiceInput(String transcription) async {
    _lastTranscription = '';
    _isProcessing = true;
    notifyListeners();

    try {
      _conversationHistory.add(transcription);
      _currentState = await _geminiService.analyzeQuery(transcription);
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

  void handleActionConfirm(String actionType, Map<String, dynamic> actionData) async {
    final productId = actionData['product_id'] as String?;
    final productName = actionData['product_name'] as String;
    
    switch (actionType) {
      case 'updateStock':
        final quantity = actionData['quantity'] as int;
        final currentStock = actionData['current_stock'] as int;
        final productPrice = actionData['product_price'] as double;
        final totalCost = quantity * productPrice;
        final newStock = currentStock + quantity;
        
        if (!(await Account.canAfford(totalCost))) {
          final availableFunds = await Account.getAvailableFunds();
          _currentState = morphic.MorphicState(
            intent: morphic.Intent.unknown,
            uiMode: morphic.UIMode.narrative,
            narrative: 'Insufficient funds! You need \$${totalCost.toStringAsFixed(2)} but only have \$${availableFunds.toStringAsFixed(2)} available.',
            headerText: 'Order Failed',
            confidence: 1.0,
          );
        } else if (productId != null) {
          await BusinessData.updateStock(productId, newStock);
          await Account.debit(totalCost, 'Purchased $quantity units of $productName', productName);
          final newBalance = await Account.getAvailableFunds();
          _currentState = morphic.MorphicState(
            intent: morphic.Intent.inventory,
            uiMode: morphic.UIMode.narrative,
            narrative: 'Order placed! $productName now has $newStock units. \$${totalCost.toStringAsFixed(2)} deducted. New balance: \$${newBalance.toStringAsFixed(2)}',
            headerText: 'Success',
            confidence: 1.0,
          );
        }
        break;
      case 'deleteProduct':
        if (productId != null) {
          await BusinessData.deleteProduct(productId);
          _currentState = morphic.MorphicState(
            intent: morphic.Intent.inventory,
            uiMode: morphic.UIMode.narrative,
            narrative: '$productName has been removed from inventory.',
            headerText: 'Product Deleted',
            confidence: 1.0,
          );
        }
        break;
      case 'addProduct':
        final quantity = actionData['quantity'] as int;
        final productPrice = actionData['product_price'] as double;
        final totalCost = quantity * productPrice;
        
        if (!(await Account.canAfford(totalCost))) {
          final availableFunds = await Account.getAvailableFunds();
          _currentState = morphic.MorphicState(
            intent: morphic.Intent.unknown,
            uiMode: morphic.UIMode.narrative,
            narrative: 'Insufficient funds! You need \$${totalCost.toStringAsFixed(2)} but only have \$${availableFunds.toStringAsFixed(2)} available.',
            headerText: 'Order Failed',
            confidence: 1.0,
          );
        } else {
          final newProduct = Product(
            id: actionData['product_id'] as String,
            name: productName,
            stockCount: quantity,
            price: productPrice,
            imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
            category: 'shoes',
          );
          await BusinessData.addProduct(newProduct);
          await Account.debit(totalCost, 'Purchased $quantity units of $productName', productName);
          final newBalance = await Account.getAvailableFunds();
          _currentState = morphic.MorphicState(
            intent: morphic.Intent.inventory,
            uiMode: morphic.UIMode.narrative,
            narrative: 'New product added! $productName with $quantity units. \$${totalCost.toStringAsFixed(2)} deducted. New balance: \$${newBalance.toStringAsFixed(2)}',
            headerText: 'Product Added',
            confidence: 1.0,
          );
        }
        break;
    }
    
    notifyListeners();
    _elevenLabsService.speak(_currentState.narrative);
  }

  void handleActionCancel() {
    _currentState = morphic.MorphicState(
      intent: morphic.Intent.unknown,
      uiMode: morphic.UIMode.narrative,
      narrative: 'Action cancelled.',
      headerText: 'Cancelled',
      confidence: 1.0,
    );
    notifyListeners();
  }

  void updateTranscription(String transcription) {
    _lastTranscription = transcription;
    notifyListeners();
  }

  SpeechService get speechService => _speechService;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morphic Voice Agent',
      theme: AppTheme.theme,
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
