// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - String Constants & Localization
/// All user-facing strings centralized here for easy localization.
/// Use `AppStrings.tr(context, 'key')` to get the localized string.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class AppStrings {
  static const String appName = 'RAKSHAHER';

  // ─── Centralized Translation Helper ───────────────────────────────────────
  /// Returns the Hindi translation if the user has toggled Hindi,
  /// otherwise returns the original English text.
  static String tr(BuildContext context, String text) {
    final isHindi = context.watch<SettingsProvider>().isHindi;
    if (!isHindi) return text;
    return _hi[text] ?? text;
  }

  /// Non-reactive version for use outside of build methods
  /// (e.g., callbacks where you already have the provider).
  static String trStatic(bool isHindi, String text) {
    if (!isHindi) return text;
    return _hi[text] ?? text;
  }

  // ─── English Keys ─────────────────────────────────────────────────────────
  // Onboarding
  static const String onboarding1Title = 'Stay Safe Everywhere';
  static const String onboarding1Desc =
      'Send instant SOS alerts with your live location to your trusted contacts in just one tap.';
  static const String onboarding2Title = 'Track Your Journey';
  static const String onboarding2Desc =
      'Share your real-time location with family and friends while you travel. They can watch over you.';
  static const String onboarding3Title = 'Help is Always Near';
  static const String onboarding3Desc =
      'Find nearest police stations, hospitals, and women helpline centers on the map instantly.';

  // Auth
  static const String login = 'Log In';
  static const String signup = 'Sign Up';
  static const String email = 'Email Address';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String fullName = 'Full Name';
  static const String phone = 'Phone Number';
  static const String forgotPassword = 'Forgot Password?';
  static const String noAccount = "Don't have an account? ";
  static const String haveAccount = 'Already have an account? ';
  static const String createAccount = 'Create Account';

  // Dashboard
  static const String welcomeBack = 'Welcome back,';
  static const String safetyStatus = 'You are safe right now';
  static const String allSafetyFeaturesActive = 'All safety features active';
  static const String powerButtonSOS = 'Power Button SOS: Active';
  static const String quickActions = 'Quick Actions';
  static const String sos = 'SOS';
  static const String shareLocation = 'Share Location';
  static const String fakeCall = 'Fake Call';
  static const String safetyTips = 'Safety Tips';
  static const String contacts = 'Contacts';
  static const String trackJourney = 'Track Journey';
  static const String nearbyHelp = 'Nearby Help';
  static const String reportIncident = 'Report Incident';
  static const String emergencyHelplines = 'Emergency Helplines';
  static const String tagline = 'Your Safety, Our Priority';

  // Bottom Navigation
  static const String navHome = 'Home';
  static const String navTrack = 'Track';
  static const String navContacts = 'Contacts';
  static const String navProfile = 'Profile';

  // Helpline names
  static const String police = 'Police';
  static const String womenHelpline = 'Women Helpline';
  static const String emergency = 'Emergency';
  static const String ambulance = 'Ambulance';

  // Helpline numbers (India)
  static const String policeNumber = '100';
  static const String womenHelplineNumber = '1091';
  static const String emergencyNumber = '112';
  static const String ambulanceNumber = '102';

  // Settings
  static const String settings = 'Settings';
  static const String notifications = 'Notifications';
  static const String pushNotifications = 'Push Notifications';
  static const String receiveAlerts = 'Receive safety alerts and reminders';
  static const String notificationsEnabled = 'Notifications enabled';
  static const String notificationsDisabled = 'Notifications disabled';
  static const String sosSettings = 'SOS Settings';
  static const String vibrationOnSOS = 'Vibration on SOS';
  static const String vibrateWhenSOS = 'Vibrate when SOS is triggered';
  static const String sirenSoundOnSOS = 'Siren Sound on SOS';
  static const String playSirenWhenSOS = 'Play loud siren when SOS activates';
  static const String language = 'Language';
  static const String appLanguage = 'App Language';
  static const String english = 'English';
  static const String hindi = 'Hindi';
  static const String langChangedHindi = 'भाषा हिंदी में बदल दी गई है';
  static const String langChangedEnglish = 'Language changed to English';
  static const String appearance = 'Appearance';
  static const String darkMode = 'Dark Mode';
  static const String darkModeEnabled = 'Dark mode enabled';
  static const String lightModeEnabled = 'Light mode enabled';
  static const String reduceEyeStrain = 'Reduce eye strain at night';
  static const String about = 'About';
  static const String appVersion = 'App Version';
  static const String termsOfService = 'Terms of Service';
  static const String privacyPolicy = 'Privacy Policy';
  static const String rateApp = 'Rate this App';
  static const String thanksForRating = 'Thanks for rating us!';
  static const String calling = 'Calling';

  // ─── Hindi Translation Map ────────────────────────────────────────────────
  static const Map<String, String> _hi = {
    // Dashboard
    'Welcome back,': 'वापस स्वागत है,',
    'You are safe right now': 'आप अभी सुरक्षित हैं',
    'All safety features active': 'सभी सुरक्षा सुविधाएं सक्रिय',
    'Power Button SOS: Active': 'पावर बटन SOS: सक्रिय',
    'Quick Actions': 'त्वरित कार्य',
    'SOS': 'SOS',
    'Share Location': 'लोकेशन शेयर करें',
    'Fake Call': 'फेक कॉल',
    'Safety Tips': 'सुरक्षा सुझाव',
    'Contacts': 'संपर्क',
    'Track Journey': 'यात्रा ट्रैक करें',
    'Nearby Help': 'नज़दीकी मदद',
    'Report Incident': 'घटना रिपोर्ट करें',
    'Emergency Helplines': 'आपातकालीन हेल्पलाइन',
    'Your Safety, Our Priority': 'आपकी सुरक्षा, हमारी प्राथमिकता',

    // Bottom Nav
    'Home': 'होम',
    'Track': 'ट्रैक',
    'Profile': 'प्रोफ़ाइल',

    // Helpline Names
    'Police': 'पुलिस',
    'Women Helpline': 'महिला हेल्पलाइन',
    'Emergency': 'आपातकालीन',
    'Ambulance': 'एम्बुलेंस',
    'Calling': 'कॉल कर रहे हैं',

    // Settings
    'Settings': 'सेटिंग्स',
    'Notifications': 'सूचनाएं',
    'Push Notifications': 'पुश सूचनाएं',
    'Receive safety alerts and reminders': 'सुरक्षा अलर्ट और अनुस्मारक प्राप्त करें',
    'Notifications enabled': 'सूचनाएं सक्षम की गईं',
    'Notifications disabled': 'सूचनाएं अक्षम की गईं',
    'SOS Settings': 'SOS सेटिंग्स',
    'Vibration on SOS': 'SOS पर कंपन',
    'Vibrate when SOS is triggered': 'SOS ट्रिगर होने पर कंपन करें',
    'Siren Sound on SOS': 'SOS पर सायरन ध्वनि',
    'Play loud siren when SOS activates': 'SOS सक्रिय होने पर तेज़ सायरन बजाएं',
    'Language': 'भाषा',
    'App Language': 'ऐप की भाषा',
    'English': 'English',
    'Hindi': 'हिंदी',
    'Appearance': 'दिखावट',
    'Dark Mode': 'डार्क मोड',
    'Dark mode enabled': 'डार्क मोड सक्षम किया गया',
    'Light mode enabled': 'लाइट मोड सक्षम किया गया',
    'Reduce eye strain at night': 'रात में आंखों का तनाव कम करें',
    'About': 'के बारे में',
    'App Version': 'ऐप संस्करण',
    'Terms of Service': 'सेवा की शर्तें',
    'Privacy Policy': 'गोपनीयता नीति',
    'Rate this App': 'इस ऐप को रेट करें',
    'Thanks for rating us!': 'हमें रेट करने के लिए धन्यवाद!',

    // Auth
    'Log In': 'लॉग इन',
    'Sign Up': 'साइन अप',
    'Email Address': 'ईमेल पता',
    'Password': 'पासवर्ड',
    'Confirm Password': 'पासवर्ड की पुष्टि करें',
    'Full Name': 'पूरा नाम',
    'Phone Number': 'फ़ोन नंबर',
    'Forgot Password?': 'पासवर्ड भूल गए?',
    "Don't have an account? ": 'खाता नहीं है? ',
    'Already have an account? ': 'पहले से खाता है? ',
    'Create Account': 'खाता बनाएं',

    // Onboarding
    'Stay Safe Everywhere': 'हर जगह सुरक्षित रहें',
    'Send instant SOS alerts with your live location to your trusted contacts in just one tap.':
        'केवल एक टैप में अपने विश्वसनीय संपर्कों को अपनी लाइव लोकेशन के साथ तुरंत SOS अलर्ट भेजें।',
    'Track Your Journey': 'अपनी यात्रा ट्रैक करें',
    'Share your real-time location with family and friends while you travel. They can watch over you.':
        'यात्रा के दौरान परिवार और दोस्तों के साथ अपनी रियल-टाइम लोकेशन शेयर करें। वे आप पर नज़र रख सकते हैं।',
    'Help is Always Near': 'मदद हमेशा पास है',
    'Find nearest police stations, hospitals, and women helpline centers on the map instantly.':
        'नक्शे पर निकटतम पुलिस स्टेशन, अस्पताल और महिला हेल्पलाइन केंद्र तुरंत खोजें।',
  };
}