// ignore_for_file: use_build_context_synchronously
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_contact.dart';

class SmsService {
  /// Send emergency SMS to all contacts with custom message
  /// Since telephony was removed, we use url_launcher to open SMS app
  static Future<List<String>> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    final List<String> sentTo = [];

    // Combine all phone numbers into one string separated by comma
    final phones = contacts.map((c) => c.phone.replaceAll(RegExp(r'\s+'), '')).where((p) => p.isNotEmpty).join(',');
    
    if (phones.isNotEmpty) {
      final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          sentTo.addAll(contacts.map((c) => c.name));
        }
      } catch (_) {}
    }

    // Attempt to make a direct phone call to the first available contact as backup
    if (contacts.isNotEmpty) {
      final firstPhone = contacts.first.phone.replaceAll(RegExp(r'\s+'), '');
      if (firstPhone.isNotEmpty) {
        await FlutterPhoneDirectCaller.callNumber(firstPhone);
      }
    }

    return sentTo;
  }

  /// Send "I am safe now" follow-up SMS
  static Future<void> sendSafeNowSMS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    final phones = contacts.map((c) => c.phone.replaceAll(RegExp(r'\s+'), '')).where((p) => p.isNotEmpty).join(',');
    if (phones.isNotEmpty) {
      final uri = Uri.parse('sms:$phones?body=${Uri.encodeComponent(message)}');
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (_) {}
    }
  }

  /// Send a single SMS (for live location share notification)
  static Future<bool> sendSingleSMS({
    required String phone,
    required String message,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      final uri = Uri.parse('sms:$cleanPhone?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Request SMS permission (Placeholder, as url_launcher doesn't strictly need SMS permission, but calling might need phone permission)
  static Future<bool> requestPermission() async {
    final status = await Permission.phone.request();
    return status.isGranted;
  }
}