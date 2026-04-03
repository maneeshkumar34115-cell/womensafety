// ignore_for_file: use_build_context_synchronously
/// SafeGuardHer - Emergency Contact Data Model
library;

class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String relation;
  final int priority; // 1 = highest

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relation,
    this.priority = 5,
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relation: map['relation'] ?? '',
      priority: map['priority'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'relation': relation,
      'priority': priority,
    };
  }
}