# Testing Guide

## Prerequisites

1. **Add API Keys to .env file:**
   ```
   GEMINI_API_KEY=your_actual_gemini_key
   ELEVENLABS_API_KEY=your_actual_elevenlabs_key
   ```
   - Get Gemini key: https://aistudio.google.com/app/apikey
   - Get ElevenLabs key: https://elevenlabs.io/app/settings/api-keys

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

## Run the App

### Option 1: Windows (Recommended - No Android SDK needed)
```bash
flutter run -d windows
```

### Option 2: Chrome/Web
```bash
flutter run -d chrome
```

### Option 3: Android (Requires Android SDK)
```bash
flutter run -d android
```

## Testing Features

### 1. Test Demo Mode (Easiest)
1. Click the **Settings icon** (top right)
2. Click **Start Demo**
3. Watch the app automatically:
   - Query about Nike inventory → Shows table
   - Query about expenses → Shows chart
   - Query about supplier payment → Shows narrative
   - Query about product photo → Shows image

### 2. Test Voice Input (Requires Microphone)
1. Click the **Mic button** (bottom center)
2. Speak one of these queries:
   - "Show me Nike inventory"
   - "What are my expenses?"
   - "Show me product photos"
3. Watch the UI morph based on your query

### 3. Test Manual Queries (Without Voice)
Since voice might not work on all platforms, you can test by modifying the code temporarily:

Add this button to `home_screen.dart` for testing:
```dart
ElevatedButton(
  onPressed: () {
    context.read<AppState>().processVoiceInput("Show Nike inventory");
  },
  child: const Text('Test Query'),
)
```

## Expected Behavior

### UI Modes:
- **Table Mode**: Shows inventory with product names, stock, price, category
- **Chart Mode**: Shows bar chart of expenses by category
- **Image Mode**: Shows product image with details
- **Narrative Mode**: Shows text response

### Transitions:
- Smooth 600ms fade + slide animations between modes
- Mic button changes color: Blue (idle) → Red (listening) → Grey (processing)

## Troubleshooting

### "Speech recognition not available"
- **Windows**: Speech recognition might not work, use Demo Mode instead
- **Chrome**: Grant microphone permissions when prompted
- **Android**: Ensure microphone permissions are granted

### "API error"
- Check your API keys in `.env` file
- Ensure you have internet connection
- Verify Gemini API key is valid

### "Connection error"
- Check internet connection
- Try running demo mode (doesn't require voice)

### App won't run
```bash
flutter clean
flutter pub get
flutter run -d windows
```

## Quick Test Commands

```bash
# Check available devices
flutter devices

# Run on specific device
flutter run -d windows
flutter run -d chrome
flutter run -d <device-id>

# Run with verbose output
flutter run -v

# Hot reload (while app is running)
Press 'r' in terminal

# Hot restart (while app is running)
Press 'R' in terminal
```

## Demo Mode Test Flow

1. **Query 1**: "How's our stock on Nike shoes?"
   - Expected: Table showing all products with Nike highlighted

2. **Query 2**: "Is that our biggest expense this month?"
   - Expected: Bar chart showing expenses with Nike Supplier as tallest bar

3. **Query 3**: "When did we last pay the Nike supplier?"
   - Expected: Narrative text with date information

4. **Query 4**: "Show me the photo of the new Air Max"
   - Expected: Product image card with Nike Air Max details

## Performance Checks

- ✓ Response time < 3 seconds
- ✓ Smooth 60fps animations
- ✓ No flickering during transitions
- ✓ Mic button responds immediately
