import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:moto_rent_dumaguete/services/auth_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/reservation_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/motorcycle_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/notification_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/storage_service_supabase.dart';
import 'package:moto_rent_dumaguete/services/theme_service.dart';
import 'package:moto_rent_dumaguete/services/locale_service.dart';
import 'package:moto_rent_dumaguete/services/supabase_service.dart';
import 'package:moto_rent_dumaguete/services/messaging_service.dart';
import 'package:moto_rent_dumaguete/theme/app_theme.dart';
import 'package:moto_rent_dumaguete/screens/splash_screen.dart';
import 'package:moto_rent_dumaguete/screens/auth/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
    print('✅ Supabase initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize Supabase: $e');
    // Continue running the app even if Supabase fails to initialize
    // You might want to show an error screen instead
  }

  // Set status bar style - will be overridden by theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(const MotoRentApp());
}

class MotoRentApp extends StatefulWidget {
  const MotoRentApp({super.key});

  @override
  State<MotoRentApp> createState() => _MotoRentAppState();
}

class _MotoRentAppState extends State<MotoRentApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  void _setupDeepLinkListener() {
    // Listen for auth state changes (password reset deep links)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      print('🔐 Auth event: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        print('🔑 Password recovery detected!');
        // Navigate to reset password screen
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            ),
            (route) => false,
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
        ChangeNotifierProvider(create: (_) => AuthServiceSupabase()),
        ChangeNotifierProvider(create: (_) => ReservationServiceSupabase()),
        ChangeNotifierProvider(create: (_) => MotorcycleServiceSupabase()),
        ChangeNotifierProvider(create: (_) => NotificationServiceSupabase()),
        ChangeNotifierProvider(create: (_) => MessagingService()),
        Provider(create: (_) => StorageServiceSupabase()),
      ],
      child: Consumer2<ThemeService, LocaleService>(
        builder: (context, themeService, localeService, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'MotoRent Dumaguete',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeService.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''), // English
            ],
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
