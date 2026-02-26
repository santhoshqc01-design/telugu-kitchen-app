import 'dart:io';

void main() {
  final files = {
    'pubspec.yaml': '''name: telugu_cooking_app
description: A cooking app with Telugu language and voice support

publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  speech_to_text: ^6.6.0
  flutter_tts: ^3.8.5
  permission_handler: ^11.0.1
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  flutter_staggered_grid_view: ^0.7.0
  lottie: ^2.7.0
  google_fonts: ^6.1.0
  shared_preferences: ^2.2.2
  intl: ^0.18.1
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
  share_plus: ^7.2.1
  url_launcher: ^6.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/lottie/
    - assets/fonts/
''',
  };

  // Create directories
  final dirs = [
    'lib/blocs/language',
    'lib/blocs/recipe', 
    'lib/blocs/voice',
    'lib/models',
    'lib/screens',
    'lib/services',
    'lib/l10n',
    '.vscode',
    'assets/images',
    'assets/fonts',
    'assets/lottie',
    'test',
  ];

  for (var dir in dirs) {
    Directory(dir).createSync(recursive: true);
    print('Created: $dir');
  }

  // Create files
  files.forEach((path, content) {
    File(path).writeAsStringSync(content);
    print('Created: $path');
  });

  print('\n✅ Project structure created successfully!');
  print('Next steps:');
  print('1. Copy all the Dart files I provided earlier into lib/');
  print('2. Run: flutter pub get');
  print('3. Run: flutter run');
}