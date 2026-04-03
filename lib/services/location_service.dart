// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Location Service
/// Handles GPS permissions and real-time location fetching.
library;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  final bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  /// Request location permissions and get current position
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    notifyListeners();
    return _currentPosition;
  }

  /// Format location as a Google Maps URL for SMS sharing
  String getLocationUrl() {
    if (_currentPosition == null) return '';
    return 'https://maps.google.com/?q=${_currentPosition!.latitude},${_currentPosition!.longitude}';
  }
}