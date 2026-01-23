# Morphic Voice Agent

AI-powered business management through voice commands. Built with Flutter, Google Gemini AI, and Supabase.

## Features

- **Voice-First Interface** - Natural language business operations
- **AI Analysis** - Google Gemini 2.0 Flash with optimized prompts
- **Real-Time Database** - Supabase PostgreSQL with live sync
- **Dynamic UI** - Adaptive interface based on query type
- **Financial Intelligence** - Affordability checks and expense tracking

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (3.10.7 or higher) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (comes with Flutter)
- **Android Studio** (for Android development) or **Xcode** (for iOS development)
- **Git** - [Install Git](https://git-scm.com/downloads)
- **A code editor** - VS Code or Android Studio recommended

### Platform-Specific Requirements

#### Android
- Android SDK (API level 21 or higher)
- Android device or emulator

#### iOS (macOS only)
- Xcode 12.0 or higher
- CocoaPods
- iOS device or simulator

## Installation & Setup

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/morphic-agent.git
cd morphic-agent
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. Setup Environment Variables

#### Create .env file:

```bash
cp .env.example .env
```

#### Get API Keys:

**Gemini API Key:**
1. Go to [Google AI Studio](https://aistudio.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated key

**Supabase Setup:**
1. Go to [Supabase](https://supabase.com)
2. Create a new project
3. Go to Project Settings → API
4. Copy your `Project URL` and `anon public` key

**ElevenLabs API Key (Optional - for TTS):**
1. Go to [ElevenLabs](https://elevenlabs.io)
2. Sign up for an account
3. Go to Settings → API Keys
4. Generate and copy your API key

#### Update .env file:

```env
# Required
GEMINI_API_KEY=your_gemini_api_key_here
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Optional
ELEVENLABS_API_KEY=your_elevenlabs_api_key_here
```

### 4. Setup Supabase Database

#### Create Tables:

Run these SQL commands in your Supabase SQL Editor:

```sql
-- Products table
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  stock_count INTEGER NOT NULL,
  price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  category TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Account table
CREATE TABLE account (
  id SERIAL PRIMARY KEY,
  balance DECIMAL(10, 2) NOT NULL DEFAULT 10000.00,
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Expenses table
CREATE TABLE expenses (
  id SERIAL PRIMARY KEY,
  category TEXT NOT NULL,
  amount DECIMAL(10, 2) NOT NULL,
  date TIMESTAMP DEFAULT NOW()
);

-- Insert initial account balance
INSERT INTO account (balance) VALUES (10000.00);
```

#### Enable Row Level Security (Optional but Recommended):

```sql
-- Enable RLS
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE account ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- Create policies for public access (adjust based on your needs)
CREATE POLICY "Enable read access for all users" ON products FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON products FOR INSERT WITH CHECK (true);
CREATE POLICY "Enable update access for all users" ON products FOR UPDATE USING (true);
CREATE POLICY "Enable delete access for all users" ON products FOR DELETE USING (true);

CREATE POLICY "Enable read access for all users" ON account FOR SELECT USING (true);
CREATE POLICY "Enable update access for all users" ON account FOR UPDATE USING (true);

CREATE POLICY "Enable read access for all users" ON expenses FOR SELECT USING (true);
CREATE POLICY "Enable insert access for all users" ON expenses FOR INSERT WITH CHECK (true);
```

### 5. Platform-Specific Setup

#### Android Permissions

Permissions are already configured in `android/app/src/main/AndroidManifest.xml`:
- Microphone access
- Internet access

#### iOS Permissions

Permissions are already configured in `ios/Runner/Info.plist`:
- Microphone usage description
- Speech recognition usage description

### 6. Run the App

#### Check connected devices:

```bash
flutter devices
```

#### Run on connected device/emulator:

```bash
flutter run
```

#### Run in release mode:

```bash
flutter run --release
```

#### Build APK (Android):

```bash
flutter build apk --release
```

The APK will be located at: `build/app/outputs/flutter-apk/app-release.apk`

#### Build iOS (macOS only):

```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

**1. "No devices found"**
```bash
# For Android
# Enable USB debugging on your device
# Or start an emulator from Android Studio

# For iOS
# Connect your iPhone and trust the computer
# Or start a simulator from Xcode
```

**2. "Pub get failed"**
```bash
flutter clean
flutter pub get
```

**3. "Microphone permission denied"**
- Ensure microphone permissions are granted in device settings
- Check AndroidManifest.xml and Info.plist have correct permissions

**4. "Supabase connection error"**
- Verify your SUPABASE_URL and SUPABASE_ANON_KEY in .env
- Check your internet connection
- Ensure Supabase project is active

**5. "Gemini API error"**
- Verify your GEMINI_API_KEY is correct
- Check API quota limits at Google AI Studio
- Ensure you have internet connection

### Clean Build

If you encounter persistent issues:

```bash
flutter clean
flutter pub get
flutter run
```

## Project Structure

```
morphic-agent/
├── lib/
│   ├── models/              # Data models (Product, Expense, Account)
│   ├── screens/             # UI screens (Home screen)
│   ├── services/            # API services (Gemini, Supabase, Speech)
│   ├── utils/               # Utilities (Theme, Demo mode)
│   ├── widgets/             # Reusable widgets (Charts, Tables, Cards)
│   └── main.dart            # App entry point
├── android/                 # Android-specific files
├── ios/                     # iOS-specific files
├── web/                     # Web-specific files
├── .env                     # Environment variables (create from .env.example)
├── pubspec.yaml             # Flutter dependencies
└── README.md                # This file
```

## Tech Stack

- **Frontend:** Flutter 3.10.7 with Provider state management
- **AI:** Google Gemini 2.0 Flash API
- **Database:** Supabase PostgreSQL with real-time sync
- **Voice:** Flutter speech_to_text package
- **Charts:** fl_chart for data visualization
- **Design:** Modern emerald/white/black theme

## Architecture

- **Voice Input** → **AI Analysis** → **Dynamic UI Response**
- Real-time database sync across devices
- Optimized 200-token prompts for fast AI responses
- Clean separation of concerns with modular components

## Usage Examples

Once the app is running, try these voice commands:

- "Show me all products" - Display inventory table
- "Show me Nike Air Max" - Display single product card
- "Can I afford 10 Nike shoes?" - Financial affordability check
- "Order 5 Adidas shoes" - Place order with confirmation
- "Show me expenses" - Display expense chart
- "What's my balance?" - Check account balance

## Development

### Running Tests

```bash
flutter test
```

### Code Formatting

```bash
flutter format .
```

### Analyze Code

```bash
flutter analyze
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review troubleshooting section above
