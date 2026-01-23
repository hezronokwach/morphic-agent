import '../main.dart';

class DemoMode {
  static final List<String> demoQueries = [
    "Delete Nike Air Max",
    "Which expense is highest?",
    "Show me Nike Air Max",
    "Add 20 more Nike Air Max",
    "What is my balance"
  ];

  static Future<void> runDemo(AppState state) async {
    for (String query in demoQueries) {
      await Future.delayed(const Duration(seconds: 4));
      await state.processVoiceInput(query);
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}
