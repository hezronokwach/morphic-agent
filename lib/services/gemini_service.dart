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

    return '''You are a business assistant for a shoe store. Analyze user queries and respond with JSON.

Available products: $productList
Expense categories: $expenseCategories

Respond with this exact JSON structure:
{
  "intent": "inventory" | "finance" | "retail" | "unknown",
  "ui_mode": "table" | "chart" | "image" | "narrative",
  "header_text": "Contextual header (e.g., 'Price of Nike Air Max:')",
  "narrative": "Brief answer or description",
  "entities": {"product_name": "...", "stock_filter": "<30", "query_type": "price|stock|details"},
  "confidence": 0.0-1.0
}

Rules:
- Asking about ONE specific product (details/photo) → ui_mode: "image", intent: "retail"
- Asking for price/stock of ONE product → ui_mode: "narrative", header_text: "Price of [product]:" or "Stock of [product]:", narrative: just the value
- Asking about MULTIPLE products or list → ui_mode: "table", intent: "inventory"
- Filtering queries ("stock less than X") → ui_mode: "table", add stock_filter to entities
- ANY expense/finance query → ui_mode: "chart", intent: "finance"
- Calculations/summaries → ui_mode: "narrative"

Examples:
- "Show me Nike Air Max" → ui_mode: "image", header_text: "Nike Air Max", entities: {"product_name": "Nike Air Max"}
- "What's the price of Nike?" → ui_mode: "narrative", header_text: "Price of Nike Air Max:", narrative: "\$120", entities: {"query_type": "price"}
- "How many Puma do I have?" → ui_mode: "narrative", header_text: "Stock of Puma Running Shoes:", narrative: "22 units", entities: {"query_type": "stock"}
- "Show me all products" → ui_mode: "table", header_text: "Product Inventory"
- "Products with stock less than 30" → ui_mode: "table", header_text: "Low Stock Products", entities: {"stock_filter": "<30"}
- "Which expense is highest?" → ui_mode: "chart", header_text: "Expense Breakdown"

ALWAYS provide header_text with context!''';
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

      print('\n🔵 GEMINI REQUEST: $userInput');

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
        print('🟢 GEMINI RAW RESPONSE: ${response.body}');
        
        final content = data['candidates'][0]['content']['parts'][0]['text'];
        print('🟢 GEMINI PARSED CONTENT: $content');
        
        final aiResponse = jsonDecode(content);
        print('🟢 GEMINI AI RESPONSE: $aiResponse');

        final result = _parseResponse(aiResponse, products, expenses);
        print('🟢 FINAL STATE: intent=${result.intent}, uiMode=${result.uiMode}, narrative=${result.narrative}');
        
        return result;
      } else {
        print('🔴 GEMINI ERROR: ${response.statusCode} - ${response.body}');
        return _errorState('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 GEMINI EXCEPTION: $e');
      return _errorState('Connection error. Please try again.');
    }
  }

  morphic.MorphicState _parseResponse(Map<String, dynamic> response, List<Product> products, List<Expense> expenses) {
    final intentStr = response['intent'] ?? 'unknown';
    final uiModeStr = response['ui_mode'] ?? 'narrative';
    final narrative = response['narrative'] ?? 'I\'m not sure how to help with that.';
    final headerText = response['header_text'];
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
      var filteredProducts = products;
      
      // Apply stock filter if present
      if (entities.containsKey('stock_filter')) {
        final filter = entities['stock_filter'];
        if (filter.startsWith('<')) {
          final threshold = int.tryParse(filter.substring(1)) ?? 0;
          filteredProducts = filteredProducts.where((p) => p.stockCount < threshold).toList();
          print('📦 Filtered to ${filteredProducts.length} products with stock < $threshold');
        } else if (filter.startsWith('>')) {
          final threshold = int.tryParse(filter.substring(1)) ?? 0;
          filteredProducts = filteredProducts.where((p) => p.stockCount > threshold).toList();
          print('📦 Filtered to ${filteredProducts.length} products with stock > $threshold');
        }
      }
      
      // Apply product name filter if present
      if (entities.containsKey('product_name')) {
        final productName = entities['product_name'];
        filteredProducts = filteredProducts.where(
          (p) => p.name.toLowerCase().contains(productName.toLowerCase())
        ).toList();
        print('📦 Filtered to ${filteredProducts.length} products matching "$productName"');
      }
      
      data['products'] = filteredProducts;
    } else if (intent == morphic.Intent.finance) {
      data['expenses'] = expenses;
      print('💰 Added ${expenses.length} expenses to data');
    } else if (intent == morphic.Intent.retail && entities.containsKey('product_name')) {
      final productName = entities['product_name'];
      final product = products.firstWhere(
        (p) => p.name.toLowerCase().contains(productName.toLowerCase()),
        orElse: () => products.first,
      );
      data['product'] = product;
      print('🖼️ Added product: ${product.name}');
    }

    print('📊 Final data keys: ${data.keys.toList()}');

    return morphic.MorphicState(
      intent: intent,
      uiMode: uiMode,
      narrative: narrative,
      headerText: headerText,
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
