/// SafeGuardHer - Application Entry Point
/// Sets up Provider for state management and defines the root Material App
/// with custom theme, routing, and splash screen entry.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/contacts_service.dart';
import 'services/sms_service.dart';
import 'screens/splash/splash_screen.dart';
import 'package:power_button_plugin/power_button_plugin.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
    ),
    iosConfiguration: IosConfiguration(),
  );
  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  
  debugPrint("Background service started - initializing Power Button SOS...");
  
  // Set up the callback: when native detects 5 rapid power presses,
  // this function will be called automatically.
  PowerButtonPlugin.initialize(
    onSosTriggered: () async {
      debugPrint(">>> BACKGROUND SOS TRIGGERED VIA POWER BUTTON! <<<");
      
      // 1. Load contacts
      final contactsService = ContactsService();
      await contactsService.loadContacts();
      
      if (contactsService.contacts.isEmpty) {
        debugPrint("No contacts saved for background SOS");
        return;
      }
      
      // 2. Get Location
      final locationService = LocationService();
      String locationUrl = "";
      try {
        await locationService.getCurrentLocation();
        locationUrl = locationService.getLocationUrl();
      } catch (e) {
        debugPrint("Background location failed: $e");
      }
      
      // 3. Send SMS
      final message = "SOS! I am in danger and triggered the emergency power button alert. "
          "Please verify my safety immediately. My live location: $locationUrl";
          
      try {
        await SmsService.sendEmergencySMS(
          contacts: contactsService.contacts,
          message: message,
        );
        debugPrint("Background SOS SMS sent successfully!");
      } catch (e) {
        debugPrint("Background SOS SMS failed: $e");
      }
    },
  );
  
  // Also explicitly start the listener (it auto-starts, but this ensures it)
  try {
    await PowerButtonPlugin.startService();
    debugPrint("Power Button listener started successfully");
  } catch (e) {
    debugPrint("Power Button start error: $e");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for mobile-first experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style for status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize Firebase to enable Auth, Firestore, and Storage
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // Handling if google-services.json is missing or invalid.
  }

  // Initialize Background Service
  try {
    await initializeBackgroundService();
  } catch (e) {
    debugPrint("Background service init failed: $e");
  }

  runApp(const SafeGuardHerApp());
}

class SafeGuardHerApp extends StatelessWidget {
  const SafeGuardHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app with all service providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => ContactsService()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
