// SafeGuardHer - SMS Service
// Sends real SMS using sms_sender package. Works WITHOUT internet.

import 'package:telephony/telephony.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_contact.dart';

class SmsService {
  static final Telephony telephony = Telephony.instance;

  /// Send emergency SMS to all contacts with custom message
  static Future<List<String>> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    // Ensure permission
    final bool? result = await telephony.requestPhoneAndSmsPermissions;
    if (result != null && !result) {
      throw Exception('SMS permission denied');
    }

    final List<String> sentTo = [];

    for (final contact in contacts) {
      try {
        final phone = contact.phone.replaceAll(RegExp(r'\s+'), '');
        if (phone.isEmpty) continue;
        await telephony.sendSms(
          to: phone,
          message: message,
          isMultipart: true,
        );
        sentTo.add(contact.name);
      } catch (e) {
        // Continue sending to remaining contacts
        continue;
      }
    }

    return sentTo;
  }

  /// Send "I am safe now" follow-up SMS
  static Future<void> sendSafeNowSMS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    for (final contact in contacts) {
      try {
        final phone = contact.phone.replaceAll(RegExp(r'\s+'), '');
        if (phone.isEmpty) continue;
        await telephony.sendSms(
          to: phone,
          message: message,
          isMultipart: true,
        );
      } catch (_) {
        continue;
      }
    }
  }

  /// Send a single SMS (for live location share notification)
  static Future<bool> sendSingleSMS({
    required String phone,
    required String message,
  }) async {
    try {
      final cleanPhone = phone.replaceAll(RegExp(r'\s+'), '');
      await telephony.sendSms(
        to: cleanPhone, 
        message: message,
        isMultipart: true,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Request SMS permission
  static Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }
}
