/// Simple translation helper for common phrases
/// This is a basic implementation. For full app translation,
/// consider using flutter_localizations or easy_localization packages.
library;

class Translations {
  static Map<String, Map<String, String>> translations = {
    'welcome': {
      'en': 'Welcome',
      'fil': 'Maligayang pagdating',
      'ceb': 'Maayong pag-abot',
    },
    'logout': {
      'en': 'Logout',
      'fil': 'Mag-logout',
      'ceb': 'Logout',
    },
    'profile': {
      'en': 'Profile',
      'fil': 'Profile',
      'ceb': 'Profile',
    },
    'bookings': {
      'en': 'Bookings',
      'fil': 'Mga Booking',
      'ceb': 'Mga Booking',
    },
    'favorites': {
      'en': 'Favorites',
      'fil': 'Mga Paborito',
      'ceb': 'Mga Paborito',
    },
    'language': {
      'en': 'Language',
      'fil': 'Wika',
      'ceb': 'Pinulongan',
    },
    'settings': {
      'en': 'Settings',
      'fil': 'Mga Setting',
      'ceb': 'Mga Setting',
    },
    'search': {
      'en': 'Search motorcycles...',
      'fil': 'Maghanap ng motor...',
      'ceb': 'Pangitaa ang motor...',
    },
    'book_now': {
      'en': 'Book Now',
      'fil': 'Mag-book Ngayon',
      'ceb': 'Book Karon',
    },
    'available': {
      'en': 'Available',
      'fil': 'Available',
      'ceb': 'Available',
    },
    'rented': {
      'en': 'Rented',
      'fil': 'Naka-renta',
      'ceb': 'Giabangan',
    },
  };

  static String get(String key, String languageCode) {
    final translation = translations[key];
    if (translation == null) return key;
    return translation[languageCode] ?? translation['en'] ?? key;
  }
}
