import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:async' show Future, unawaited;
import 'core/constants/app_strings.dart';
import 'core/widgets/snowfall_overlay.dart';
import 'dart:io' show Platform;

import 'screens/splash/splash_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'core/providers/user_provider.dart';
import 'core/providers/fortune_provider.dart';
import 'core/providers/test_provider.dart';
import 'core/providers/language_provider.dart';
import 'core/services/ads_service.dart';
import 'core/services/purchase_service.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable 120Hz high frame rate support
  await _enable120Hz();
  
  // Optimize initialization with timeout
  await _initializeServices();
  
  runApp(const FallaApp());
}

/// Enable 120Hz refresh rate for smoother animations (System default)
Future<void> _enable120Hz() async {
  try {
    // Enable edge-to-edge mode for modern UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    
    // Set system UI overlay style for transparent status bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    // UNLOCK MAX REFRESH RATE (Native Implementation)
    // Supports 120Hz, 144Hz, 240Hz directly via Android API
    try {
      if (Platform.isAndroid) {
        const channel = MethodChannel('com.mustafakarakus.falla/display');
        await channel.invokeMethod('setHighRefreshRate');
      }
    } catch (e) {
      debugPrint('Error setting native high refresh rate: $e');
    }
    
  } catch (e) {
    debugPrint('Error in system UI setup: $e');
  }
}


Future<void> _initializeServices() async {
  // Firebase must initialize first, then Ads/Purchase services
  await _initializeFirebaseWithTimeout();
  unawaited(_initializeAdsWithTimeout());
  unawaited(_initializePurchasesWithTimeout());
}

Future<void> _initializePurchasesWithTimeout() async {
  try {
    await PurchaseService().initialize().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          print('⚠️ PurchaseService initialization timeout after 5 seconds');
        }
      },
    );
  } catch (e) {
    if (kDebugMode) {
      print('❌ PurchaseService initialization error: $e');
    }
  }
}

Future<void> _initializeFirebaseWithTimeout() async {
  try {
    await _initializeFirebase().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        if (kDebugMode) {
          print('⚠️ Firebase initialization timeout after 10 seconds');
        }
      },
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization error: $e');
      print('Stack trace: $stackTrace');
    }
    // Continue anyway - Firebase might work with cached credentials
  }
}

Future<void> _initializeAdsWithTimeout() async {
  try {
    await _initializeAds().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        if (kDebugMode) {
          print('⚠️ AdMob initialization timeout after 5 seconds');
        }
      },
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ AdMob initialization error: $e');
      print('Stack trace: $stackTrace');
    }
    // Continue anyway - ads can initialize later
  }
}

Future<void> _initializeFirebase() async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        print('✅ Firebase initialized successfully');
      }
    } else {
      if (kDebugMode) {
        print('✅ Firebase already initialized');
      }
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ Firebase initialization failed: $e');
      print('Stack trace: $stackTrace');
      print('⚠️ Check if GoogleService-Info.plist exists in ios/Runner/');
      print('⚠️ Verify the file is added to Xcode target: Runner → Build Phases → Copy Bundle Resources');
    }
    rethrow;
  }
}

Future<void> _initializeAds() async {
  try {
    await AdsService.initialize();
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('❌ AdMob initialization failed: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
}

class FallaApp extends StatelessWidget {
  const FallaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FortuneProvider()),
        ChangeNotifierProvider(create: (_) => TestProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, child) {
          // AppStrings'e context'i set et
          AppStrings.setContext(context);
          
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Falla',
            theme: themeProvider.getCurrentThemeData(),
            locale: languageProvider.locale,
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
              Locale('it', 'IT'),
              Locale('fr', 'FR'),
              Locale('ru', 'RU'),
              Locale('de', 'DE'),
              Locale('ar', 'SA'),
              Locale('fa', 'IR'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              ],
            builder: (context, child) {
              return SnowfallOverlay(
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}