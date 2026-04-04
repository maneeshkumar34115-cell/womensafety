import 'package:flutter/services.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/emergency_contact.dart';

class SmsService {
  static const MethodChannel _smsChannel = MethodChannel('com.safeguardher/sms');

  /// Send emergency SMS to all contacts dynamically
  static Future<List<String>> sendEmergencySMS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    final List<String> sentTo = [];

    // Directly send SMS via native MethodChannel
    for (var contact in contacts) {
      final phone = contact.phone.replaceAll(RegExp(r'\s+'), '');
      if (phone.isNotEmpty) {
        try {
          final bool result = await _smsChannel.invokeMethod('sendSMS', {
            'phone': phone,
            'message': message,
          });
          if (result) {
            sentTo.add(contact.name);
          }
        } catch (_) {
          // Fallback to url_launcher if background_sms fails
          try {
            final uri = Uri.parse('sms:$phone?body=${Uri.encodeComponent(message)}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri);
              sentTo.add(contact.name);
            }
          } catch (_) {}
        }
      }
    }

    // Call first available
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
      
      try {
        final bool result = await _smsChannel.invokeMethod('sendSMS', {
          'phone': cleanPhone,
          'message': message,
        });
        if (result) return true;
      } catch (_) {}
      
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