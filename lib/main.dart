import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/splash_screen.dart';
import 'providers/location_provider.dart';
import 'providers/hospital_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/subscription_provider.dart';
import 'services/auto_sync_service.dart';
import 'config/app_config.dart';
import 'app_settings.dart';

import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  
  // Force Google Maps OFF for simulator (it crashes without real device keys)
  // On real device, keys are loaded from backend
  if (Platform.isIOS) {
    AppConfig.useGoogleMaps = false;
    // Splash + ApiKeyManager set TomTom/OSM from keys; avoid both TomTom and OSM true here.
    AppConfig.useTomTomMaps = false;
    AppConfig.useOpenStreetMap = true;
  } else {
    // Android - use keys from backend
    if (AppConfig.googleMapsApiKey == null || 
        AppConfig.googleMapsApiKey!.isEmpty || 
        AppConfig.googleMapsApiKey!.length <= 10) {
      AppConfig.useGoogleMaps = false;
      if (!AppConfig.useTomTomMaps) {
        AppConfig.useOpenStreetMap = true;
      }
    }
  }
  
  // Initialize AdMob
  await MobileAds.instance.initialize();
  
  // Initialize Auto Sync Service
  await AutoSyncService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(
          create: (_) => AuthProvider()..initialize(),
        ),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => AppSettings()..load()),
      ],
      child: Consumer<AppSettings>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'ER Wait Time',
            debugShowCheckedModeBanner: false,
            theme: settings.lightTheme,
            darkTheme: settings.darkTheme,
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppI18n.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: SplashScreen(),
          );
        },
      ),
    );
  }
}