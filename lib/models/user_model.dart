/// SafeGuardHer - User Data Model
/// Represents a registered user stored in Firestore.

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profileImageUrl;
  final List<String> emergencyContactIds;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profileImageUrl,
    this.emergencyContactIds = const [],
    required this.createdAt,
  });

  /// Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'],
      emergencyContactIds: List<String>.from(map['emergencyContactIds'] ?? []),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Convert UserModel to Firestore-compatible map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'emergencyContactIds': emergencyContactIds,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
