import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  bool _isHindi = false;
  bool _isDarkMode = false;
  bool _sosVibration = true;
  bool _sosSiren = true;
  bool _notificationsEnabled = true;

  bool get isHindi => _isHindi;
  bool get isDarkMode => _isDarkMode;
  bool get sosVibration => _sosVibration;
  bool get sosSiren => _sosSiren;
  bool get notificationsEnabled => _notificationsEnabled;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isHindi = prefs.getBool('isHindi') ?? false;
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    _sosVibration = prefs.getBool('sosVibration') ?? true;
    _sosSiren = prefs.getBool('sosSiren') ?? true;
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    notifyListeners();
  }

  Future<void> toggleLanguage(bool isHindi) async {
    _isHindi = isHindi;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isHindi', _isHindi);
  }

  Future<void> toggleDarkMode(bool isDark) async {
    _isDarkMode = isDark;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  Future<void> toggleSosVibration(bool val) async {
    _sosVibration = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('sosVibration', val);
  }

  Future<void> toggleSosSiren(bool val) async {
    _sosSiren = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('sosSiren', val);
  }

  Future<void> toggleNotifications(bool val) async {
    _notificationsEnabled = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('notificationsEnabled', val);
  }
}
