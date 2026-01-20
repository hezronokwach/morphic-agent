import 'package:flutter/material.dart';
import '../main.dart';

class DemoMode {
  static final List<String> demoQueries = [
    "How's our stock on Nike shoes?",
    "Is that our biggest expense this month?",
    "When did we last pay the Nike supplier?",
    "Show me the photo of the new Air Max"
  ];

  static Future<void> runDemo(AppState state) async {
    for (String query in demoQueries) {
      await Future.delayed(const Duration(seconds: 3));
      await state.processVoiceInput(query);
      await Future.delayed(const Duration(seconds: 2));
    }
  }
}
