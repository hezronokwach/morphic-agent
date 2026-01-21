import 'package:flutter/material.dart';
import '../main.dart';

class DemoMode {
  static final List<String> demoQueries = [
    "Show me all products",
    "Which expense is highest?",
    "Show me Nike Air Max",
    "Add 20 more Nike Air Max",
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
