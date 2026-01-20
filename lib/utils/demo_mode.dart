import 'package:flutter/material.dart';
import '../main.dart';

class DemoMode {
  static final List<String> demoQueries = [
    "Show me all products",              // Table - full inventory
    "Which expense is highest?",         // Chart - visual comparison  
    "Show me the photo of Nike Air Max", // Image - specific product
    "What's our total inventory value?", // Narrative - summary text
  ];

  static Future<void> runDemo(AppState state) async {
    for (String query in demoQueries) {
      print('\n=== DEMO QUERY: $query ===');
      await Future.delayed(const Duration(seconds: 4));
      await state.processVoiceInput(query);
      print('=== DEMO COMPLETE FOR: $query ===\n');
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
