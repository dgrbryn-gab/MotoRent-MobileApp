# Language Selection Feature

## Overview
The MotoRent Dumaguete app now has a fully functional language selection feature that allows users to choose their preferred language for the app interface.

## Features Implemented

### 1. LocaleService (`lib/services/locale_service.dart`)
- Manages app-wide language/locale state
- Persists language preference using SharedPreferences
- Supports 3 languages:
  - **English** (en)
  - **Filipino** (fil)
  - **Cebuano** (ceb)
- Notifies all listeners when language changes

### 2. Language Selection Screen (`lib/screens/profile/language_selection_screen.dart`)
- Beautiful UI with language options
- Shows current selected language with visual indicators
- Instant save when user selects a language
- Success notification when language is changed
- Fully themed for dark/light mode

### 3. Profile Screen Integration
- Shows current selected language in subtitle: "Current: English"
- Real-time updates when language changes
- Navigates to language selection screen when tapped

### 4. Main App Integration (`lib/main.dart`)
- LocaleService added to MultiProvider
- MaterialApp configured with:
  - `locale`: Current selected locale
  - `supportedLocales`: All supported languages
- Changes apply immediately throughout the app

## How It Works

### User Flow:
1. User opens **Profile** screen
2. Taps on **Language** menu item (shows current language)
3. Opens Language Selection screen
4. Selects desired language (English, Filipino, or Cebuano)
5. Language preference is saved instantly
6. Success message appears
7. Profile screen updates to show new language
8. Language persists across app restarts

### Technical Flow:
```dart
User Selects Language
        ↓
LocaleService.setLocale(languageCode)
        ↓
Save to SharedPreferences
        ↓
Update _locale variable
        ↓
notifyListeners()
        ↓
All Consumer<LocaleService> widgets rebuild
        ↓
MaterialApp rebuilds with new locale
```

## Usage Examples

### Getting Current Language:
```dart
Consumer<LocaleService>(
  builder: (context, localeService, child) {
    final currentLang = localeService.locale.languageCode; // 'en', 'fil', 'ceb'
    final langName = localeService.getLanguageName(currentLang); // 'English', 'Filipino', 'Cebuano'
    return Text('Current: $langName');
  },
)
```

### Changing Language:
```dart
final localeService = Provider.of<LocaleService>(context, listen: false);
await localeService.setLocale('fil'); // Change to Filipino
```

### Using Translations (Basic):
```dart
import 'package:moto_rent_dumaguete/utils/translations.dart';

Consumer<LocaleService>(
  builder: (context, localeService, child) {
    final lang = localeService.locale.languageCode;
    return Text(Translations.get('welcome', lang)); // Shows translated 'Welcome'
  },
)
```

## Files Modified

1. **Created:**
   - `lib/services/locale_service.dart` - Language state management
   - `lib/utils/translations.dart` - Simple translation helper
   - `LANGUAGE_FEATURE.md` - This documentation

2. **Modified:**
   - `lib/main.dart` - Added LocaleService provider and MaterialApp locale config
   - `lib/screens/profile/profile_screen.dart` - Shows current language, uses Consumer
   - `lib/screens/profile/language_selection_screen.dart` - Converted to use Provider

## Current State

✅ **Fully Functional:**
- Language selection UI
- Persistent storage of language preference
- Real-time updates across app
- Beautiful themed interface
- Success notifications

⚠️ **Note:**
- The app UI is currently in English
- Translation infrastructure is ready for full implementation
- To translate the entire app, you would need to:
  1. Add more translations to `translations.dart` or use a package like `flutter_localizations`
  2. Replace hardcoded strings with translation calls
  3. Update all screens to use `Translations.get()` method

## Testing the Feature

1. **Hot Restart the app** (not just hot reload):
   ```bash
   flutter run
   ```

2. **Navigate to Profile:**
   - Tap Profile tab in bottom navigation

3. **Open Language Settings:**
   - Scroll to "Language" menu item
   - Should show "Current: English" by default

4. **Change Language:**
   - Tap on Language menu item
   - Select Filipino or Cebuano
   - See success message
   - Press back button
   - Profile screen now shows "Current: Filipino"

5. **Test Persistence:**
   - Close the app completely
   - Reopen the app
   - Go to Profile > Language
   - Your selected language should still be selected

## Future Enhancements

To fully translate the app:

### Option 1: Use flutter_localizations (Recommended)
```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
```

Create `.arb` files for each language and use `MaterialLocalizations`.

### Option 2: Use easy_localization Package
```yaml
dependencies:
  easy_localization: ^3.0.0
```

Create JSON translation files and use the `tr()` extension method.

### Option 3: Expand Current System
Add more translations to `translations.dart` and wrap all UI text:
```dart
// Instead of:
Text('Welcome to MotoRent')

// Use:
Text(Translations.get('welcome_message', locale.languageCode))
```

## API Reference

### LocaleService Methods:

```dart
class LocaleService extends ChangeNotifier {
  Locale get locale;                              // Current locale
  List<Locale> get supportedLocales;              // All supported locales
  
  Future<void> setLocale(String languageCode);    // Change language
  String getLanguageName(String code);            // Get English name
  String getLanguageNativeName(String code);      // Get native name
}
```

### Translations Helper:

```dart
class Translations {
  static String get(String key, String languageCode); // Get translation
}
```

## Conclusion

The language selection feature is now **fully functional** with:
- ✅ Persistent storage
- ✅ Real-time UI updates
- ✅ Beautiful interface
- ✅ Three language options
- ✅ Provider state management

The infrastructure is ready for full app translation when needed!
