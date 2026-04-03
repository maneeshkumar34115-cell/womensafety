// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Contacts Service
/// Manages emergency contacts CRUD with SharedPreferences.
/// Ready to swap for Firestore.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';

class ContactsService extends ChangeNotifier {
  List<EmergencyContact> _contacts = [];
  bool _isLoading = false;

  List<EmergencyContact> get contacts => _contacts;
  bool get isLoading => _isLoading;

  ContactsService() {
    loadContacts();
  }

  /// Load contacts from local storage
  Future<void> loadContacts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('emergency_contacts');
      if (data != null) {
        final List decoded = jsonDecode(data);
        _contacts = decoded.map((e) => EmergencyContact.fromMap(e)).toList();
      }

      // Seed with real Indian dummy data on first launch
      if (_contacts.isEmpty) {
        _contacts = [
          EmergencyContact(
            id: '1',
            name: 'Papa',
            phone: '+91 98765 43210',
            relation: 'Father',
            priority: 1,
          ),
          EmergencyContact(
            id: '2',
            name: 'Bhaiya',
            phone: '+91 87654 32109',
            relation: 'Brother',
            priority: 2,
          ),
        ];
        await _save();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add a new contact (max 5)
  Future<void> addContact(EmergencyContact contact) async {
    if (_contacts.length >= 5) {
      throw Exception('Maximum 5 emergency contacts allowed');
    }
    _contacts.add(contact);
    await _save();
    notifyListeners();
  }

  /// Delete a contact by id
  Future<void> deleteContact(String id) async {
    _contacts.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  /// Reorder the contacts list
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _contacts.removeAt(oldIndex);
    _contacts.insert(newIndex, item);
    await _save();
    notifyListeners();
  }

  /// Persist contacts to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_contacts.map((c) => c.toMap()).toList());
    await prefs.setString('emergency_contacts', data);
  }
}