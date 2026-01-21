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
    final productList = products.map((p) => '${p.name}:\$${p.price},${p.stockCount}').join('|');
    final balance = Account.getAvailableFunds().toStringAsFixed(0);

    return '''Shoe store assistant. JSON only.

Products: $productList | Balance: \$$balance

JSON: {"intent":"inventory|finance|retail|updateStock|deleteProduct|addProduct|accountBalance","ui_mode":"table|chart|image|narrative|action","header_text":"...","narrative":"...","entities":{},"confidence":0-1}

Rules: Balance→accountBalance+narrative | CRUD→action | 1product→image/narrative | Multi→table | Expenses→chart | NewProduct→addProduct

Ex: "balance"→accountBalance,narrative,"\$$balance" | "add 20 Nike"→updateStock,action,{"product_name":"Nike Air Max","quantity":20} | "show Nike"→retail,image''';
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
    String? actionType;
    
    if (intent == morphic.Intent.updateStock || intent == morphic.Intent.deleteProduct || intent == morphic.Intent.addProduct) {
      // CRUD operations
      actionType = intent.name;
      final productName = entities['product_name'];
      
      if (intent == morphic.Intent.addProduct) {
        // New product - use provided data
        data['action_type'] = actionType;
        data['action_data'] = {
          'product_name': productName,
          'product_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'current_stock': 0,
          'quantity': entities['quantity'] ?? 0,
          'price': entities['price'] ?? 100.0,
          'stock': entities['quantity'] ?? 0,
          'product_price': entities['price'] ?? 100.0,
        };
        print('⚡ CRUD Action: $actionType for NEW product $productName');
      } else {
        // Existing product
        final product = products.firstWhere(
          (p) => p.name.toLowerCase().contains(productName.toLowerCase()),
          orElse: () => products.first,
        );
        
        data['action_type'] = actionType;
        data['action_data'] = {
          'product_name': product.name,
          'product_id': product.id,
          'current_stock': product.stockCount,
          'quantity': entities['quantity'] ?? 0,
          'price': entities['price'] ?? product.price,
          'stock': entities['stock'] ?? 0,
          'product_price': product.price,
        };
        print('⚡ CRUD Action: $actionType for ${product.name}');
      }
    } else if (intent == morphic.Intent.inventory) {
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
