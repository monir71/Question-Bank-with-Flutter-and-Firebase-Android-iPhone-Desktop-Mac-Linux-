import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, examiner, examinee }

class AppUser {
  final String userId;
  final String username;
  final String email;
  final String displayName;

  final String? mobileNumber;
  final String? photoUrl;

  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const AppUser({
    required this.userId,
    required this.username,
    required this.email,
    required this.displayName,
    this.mobileNumber,
    this.photoUrl,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'displayName': displayName,
      'mobileNumber': mobileNumber,
      'photoUrl': photoUrl,
      'role': role.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final createdAtValue = map['createdAt'];

    return AppUser(
      userId: map['userId'] as String? ?? '',
      username: map['username'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      mobileNumber: map['mobileNumber'] as String?,
      photoUrl: map['photoUrl'] as String?,
      role: UserRole.values.firstWhere(
        (value) => value.name == map['role'],
        orElse: () => UserRole.examinee,
      ),
      isActive: map['isActive'] as bool? ?? true,
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.now(),
    );
  }
}
