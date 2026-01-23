import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/morphic_state.dart' as morphic;
import '../models/business_data.dart';

class GeminiService {
  final String apiKey;
  final List<String> _conversationHistory = [];
  static const int maxHistoryLength = 3;

  GeminiService({required this.apiKey});

  Future<String> _buildSystemPrompt(List<Product> products, List<Expense> expenses) async {
    final productList = products.map((p) => '${p.name}:\$${p.price},${p.stockCount}').join('|');
    final balance = (await Account.getAvailableFunds()).toStringAsFixed(0);

    return '''Shoe store assistant. JSON only.

Products: $productList | Balance: \$$balance

JSON: {"intent":"inventory|finance|retail|updateStock|deleteProduct|addProduct|accountBalance","ui_mode":"table|chart|image|narrative|action","header_text":"...","narrative":"...","entities":{},"confidence":0-1}

Rules:
- "can I afford" / "afford" → accountBalance+narrative (calculate: quantity × price, compare to balance, answer yes/no with numbers)
- "order" / "buy" / "purchase" → updateStock+action
- "show inventory" / "inventory" → inventory+table
- "show [product]" / "display [product]" → retail+image+{"product_name":"[product]"}
- "expenses" / "spending" → finance+chart
- Balance query → accountBalance+narrative

Ex: "can I afford 10 Nike Air Max"→accountBalance,narrative,"10 Nike Air Max costs \$1200. You have \$$balance. Yes, you can afford it." | "show Nike Air Max"→retail,image,{"product_name":"Nike Air Max"} | "show inventory"→inventory,table''';
  }

  Future<morphic.MorphicState> analyzeQuery(String userInput) async {
    try {
      final products = await BusinessData.getProducts();
      final expenses = await BusinessData.getExpenses();

      _conversationHistory.add(userInput);
      if (_conversationHistory.length > maxHistoryLength) {
        _conversationHistory.removeAt(0);
      }

      final systemPrompt = await _buildSystemPrompt(products, expenses);
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
        final result = await _parseResponse(aiResponse, products, expenses);
        return result;
      } else {
        return _errorState('API error: ${response.statusCode}');
      }
    } catch (e) {
      return _errorState('Connection error. Please try again.');
    }
  }

  Future<morphic.MorphicState> _parseResponse(Map<String, dynamic> response, List<Product> products, List<Expense> expenses) async {
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
          'quantity': int.tryParse(entities['quantity']?.toString() ?? '0') ?? 0,
          'price': double.tryParse(entities['price']?.toString() ?? '100.0') ?? 100.0,
          'stock': int.tryParse(entities['quantity']?.toString() ?? '0') ?? 0,
          'product_price': double.tryParse(entities['price']?.toString() ?? '100.0') ?? 100.0,
        };
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
      }
    } else if (intent == morphic.Intent.accountBalance) {
      // Handle affordability checks
      if (entities.containsKey('product_name') && entities.containsKey('quantity')) {
        final productName = entities['product_name'];
        final quantity = entities['quantity'] ?? 1;
        final product = products.firstWhere(
          (p) => p.name.toLowerCase().contains(productName.toLowerCase()),
          orElse: () => products.first,
        );
        final totalCost = quantity * product.price;
        final balance = await Account.getAvailableFunds();
        final canAfford = await Account.canAfford(totalCost);
        
        final affordabilityText = canAfford 
          ? '$quantity ${product.name} costs \$${totalCost.toStringAsFixed(0)}. You have \$${balance.toStringAsFixed(0)}. Yes, you can afford it!'
          : '$quantity ${product.name} costs \$${totalCost.toStringAsFixed(0)}. You have \$${balance.toStringAsFixed(0)}. No, insufficient funds.';
        
        return morphic.MorphicState(
          intent: intent,
          uiMode: morphic.UIMode.narrative,
          narrative: affordabilityText,
          headerText: 'Affordability Check',
          data: {},
          confidence: confidence,
        );
      }
    } else if (intent == morphic.Intent.inventory) {
      var filteredProducts = products;
      
      // Apply stock filter if present
      if (entities.containsKey('stock_filter')) {
        final filter = entities['stock_filter'];
        if (filter.startsWith('<')) {
          final threshold = int.tryParse(filter.substring(1)) ?? 0;
          filteredProducts = filteredProducts.where((p) => p.stockCount < threshold).toList();
        } else if (filter.startsWith('>')) {
          final threshold = int.tryParse(filter.substring(1)) ?? 0;
          filteredProducts = filteredProducts.where((p) => p.stockCount > threshold).toList();
        }
      }
      
      // Apply product name filter if present
      if (entities.containsKey('product_name')) {
        final productName = entities['product_name'];
        filteredProducts = filteredProducts.where(
          (p) => p.name.toLowerCase().contains(productName.toLowerCase())
        ).toList();
      }
      
      data['products'] = filteredProducts;
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
