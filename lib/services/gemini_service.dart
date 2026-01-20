import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/morphic_state.dart' as morphic;
import '../models/business_data.dart';

class GeminiService {
  final String apiKey;
  final List<String> _conversationHistory = [];
  static const int maxHistoryLength = 3;

  GeminiService({required this.apiKey});

  String _buildSystemPrompt(List<Product> products, List<Expense> expenses) {
    final productList = products.map((p) => '${p.name} (${p.category}, stock: ${p.stockCount}, price: \$${p.price})').join(', ');
    final expenseCategories = expenses.map((e) => e.category).toSet().join(', ');

    return '''You are a business assistant for a pet boutique. Analyze user queries and respond with JSON.

Available products: $productList
Expense categories: $expenseCategories

Respond with this exact JSON structure:
{
  "intent": "inventory" | "finance" | "retail" | "unknown",
  "ui_mode": "table" | "chart" | "image" | "narrative",
  "narrative": "Brief response text",
  "entities": {"product_name": "...", "product_id": "..."},
  "confidence": 0.0-1.0
}

Rules:
- inventory queries → ui_mode: "table"
- expense/finance queries → ui_mode: "chart"
- product photo requests → ui_mode: "image"
- unclear queries → ui_mode: "narrative", confidence < 0.7''';
  }

  Future<morphic.MorphicState> analyzeQuery(String userInput) async {
    try {
      final products = BusinessData.getProducts();
      final expenses = BusinessData.getExpenses();

      _conversationHistory.add(userInput);
      if (_conversationHistory.length > maxHistoryLength) {
        _conversationHistory.removeAt(0);
      }

      final systemPrompt = _buildSystemPrompt(products, expenses);
      final fullPrompt = '$systemPrompt\n\nUser query: $userInput\n\nRespond with JSON only:';

      final response = await http
          .post(
            Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': fullPrompt}
                  ]
                }
              ],
              'generationConfig': {
                'temperature': 0.7,
                'responseMimeType': 'application/json',
              }
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        final aiResponse = jsonDecode(content);

        return _parseResponse(aiResponse, products, expenses);
      } else {
        return _errorState('API error: ${response.statusCode}');
      }
    } catch (e) {
      return _errorState('Connection error. Please try again.');
    }
  }

  morphic.MorphicState _parseResponse(Map<String, dynamic> response, List<Product> products, List<Expense> expenses) {
    final intentStr = response['intent'] ?? 'unknown';
    final uiModeStr = response['ui_mode'] ?? 'narrative';
    final narrative = response['narrative'] ?? 'I\'m not sure how to help with that.';
    final confidence = (response['confidence'] ?? 1.0).toDouble();
    final entities = response['entities'] ?? {};

    final intent = morphic.Intent.values.firstWhere(
      (e) => e.name == intentStr,
      orElse: () => morphic.Intent.unknown,
    );

    final uiMode = morphic.UIMode.values.firstWhere(
      (e) => e.name == uiModeStr,
      orElse: () => morphic.UIMode.narrative,
    );

    Map<String, dynamic> data = {};
    if (intent == morphic.Intent.inventory) {
      data['products'] = products;
    } else if (intent == morphic.Intent.finance) {
      data['expenses'] = expenses;
    } else if (intent == morphic.Intent.retail && entities.containsKey('product_name')) {
      final productName = entities['product_name'];
      final product = products.firstWhere(
        (p) => p.name.toLowerCase().contains(productName.toLowerCase()),
        orElse: () => products.first,
      );
      data['product'] = product;
    }

    return morphic.MorphicState(
      intent: intent,
      uiMode: uiMode,
      narrative: narrative,
      data: data,
      confidence: confidence,
    );
  }

  morphic.MorphicState _errorState(String message) {
    return morphic.MorphicState(
      intent: morphic.Intent.unknown,
      uiMode: morphic.UIMode.narrative,
      narrative: message,
      confidence: 0.0,
    );
  }
}
