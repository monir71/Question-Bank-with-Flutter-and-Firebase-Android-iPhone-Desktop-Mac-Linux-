import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:questionbank/models/app_user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  Future<void> syncUser({
    required String username,
    required String displayName,
    String? mobileNumber,
    String? photoUrl,
  }) async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      throw Exception('No authenticated user found.');
    }

    final userReference = _firestore.collection('users').doc(firebaseUser.uid);

    final documentSnapshot = await userReference.get();

    if (!documentSnapshot.exists) {
      final appUser = AppUser(
        userId: firebaseUser.uid,
        username: username,
        email: firebaseUser.email ?? '',
        displayName: displayName,
        mobileNumber: mobileNumber,
        photoUrl: photoUrl,
        role: UserRole.examinee,
        isActive: true,
        createdAt: DateTime.now(),
      );

      final userData = appUser.toMap();

      userData['createdAt'] = FieldValue.serverTimestamp();

      await userReference.set(userData);

      return;
    }

    await userReference.update({
      'username': username,
      'email': firebaseUser.email ?? '',
      'displayName': displayName,
      'mobileNumber': mobileNumber,
      'photoUrl': photoUrl,
    });
  }

  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    final documentSnapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!documentSnapshot.exists) {
      return null;
    }

    final data = documentSnapshot.data();

    if (data == null) {
      return null;
    }

    return AppUser.fromMap(data);
  }

  Future<List<AppUser>> getAllUsers() async {
    final querySnapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs
        .map((document) => AppUser.fromMap(document.data()))
        .toList();
  }

  Future<void> updateUser({
    required String userId,
    required String username,
    required String displayName,
    String? mobileNumber,
    required UserRole role,
    required bool isActive,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({
      'username': username,
      'displayName': displayName,
      'mobileNumber': mobileNumber,
      'role': role.name,
      'isActive': isActive,
    });
  }
}
