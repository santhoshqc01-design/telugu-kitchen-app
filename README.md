# Telugu Kitchen App 🍳

A modern cooking application with **Telugu language support and voice features**.

## Framework & Technology Stack

**Mobile Framework:** Flutter with Dart 3.0+

**Architecture Pattern:** BLoC (Business Logic Component) - State Management

**Platform Support:** iOS & Android

## Key Features

- 🎙️ **Voice-Activated Recipes** - Speech-to-Text for hands-free recipe navigation
- 🔊 **Text-to-Speech** - Listen to recipe instructions in Telugu
- 🇮🇳 **Full Telugu Localization** - Complete Telugu language support
- 📸 **Rich Recipe UI** - Animated cards with shimmer effects and staggered grids
- 💾 **Offline Support** - Cached recipes and persistent storage
- 🌐 **Network-Aware** - Connectivity detection for seamless data syncing

## Tech Stack Breakdown

### State Management
- **flutter_bloc** (v9.1.1) - BLoC pattern implementation
- **equatable** (v2.0.5) - Value equality for Dart classes

### Voice & Speech
- **speech_to_text** (v7.0.0) - Convert speech to text input
- **flutter_tts** (v4.2.2) - Text-to-speech output in Telugu

### UI & Animation
- **cached_network_image** (v3.4.1) - Image caching and loading
- **shimmer** (v3.0.0) - Loading placeholders
- **flutter_staggered_grid_view** (v0.7.0) - Creative grid layouts
- **lottie** (v3.3.1) - Vector animations
- **google_fonts** (v6.2.1) - Beautiful typography

### Localization & Language
- **flutter_localizations** - Flutter's localization framework
- **intl** (v0.20.2) - Internationalization and localization support

### Utilities
- **shared_preferences** (v2.3.2) - Local data persistence
- **dio** (v5.7.0) - HTTP client for API calls
- **connectivity_plus** (v6.0.3) - Network connectivity detection
- **share_plus** (v10.1.4) - Native sharing functionality
- **url_launcher** (v6.3.0) - External URL and app launching
- **permission_handler** (v11.3.1) - Runtime permission management

## Requirements

- **Dart SDK:** 3.0.0 - 3.x
- **Flutter:** Latest stable version
- **iOS:** 11.0+
- **Android:** API level 21+

## Getting Started

### Prerequisites
- Install [Flutter](https://flutter.dev/docs/get-started/install)
- Ensure Dart 3.0+ is installed with Flutter

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/santhoshqc01-design/telugu-kitchen-app.git
   cd telugu-kitchen-app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

### Build APK/IPA
```bash
# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release
```

## Project Structure

```
lib/
├── bloc/              # BLoC pattern - business logic
├── models/            # Data models
├── pages/             # Screen/page widgets
├── widgets/           # Reusable UI components
├── services/          # API and external services
├── utils/             # Utility functions and constants
└── main.dart          # App entry point

assets/
├── images/            # Recipe and UI images
├── lottie/            # Animation JSON files
└── fonts/             # Custom Telugu fonts
```

## Resources

- [Flutter Documentation](https://flutter.dev)
- [BLoC Pattern Guide](https://bloclibrary.dev)
- [Material Design](https://material.io/design)
- [Dart Language Guide](https://dart.dev)

## Contributing

Contributions are welcome! Please feel free to submit a pull request.

## License

This project is open source and available under the MIT License.

---

**Made with ❤️ for Telugu food lovers**