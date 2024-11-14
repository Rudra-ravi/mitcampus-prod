import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mitcampus/models/user.dart' as app_user;

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<app_user.User> getCurrentUser() async {
    final User? firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('No authenticated user found');
    }

    final docSnapshot =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!docSnapshot.exists) {
      // If the user document doesn't exist in Firestore, create it
      final newUser = app_user.User(
        id: firebaseUser.uid,
        email: firebaseUser.email!,
        isHOD: firebaseUser.email == 'hodece@mvit.edu.in',
      );
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(newUser.toFirestore());
      return newUser;
    }

    return app_user.User.fromFirestore(docSnapshot);
  }

  Future<bool> isUserHOD() async {
    final currentUser = await getCurrentUser();
    return currentUser.isHOD;
  }

  Future<List<app_user.User>> getAllUsers() async {
    final querySnapshot = await _firestore.collection('users').get();
    return querySnapshot.docs
        .map((doc) => app_user.User.fromFirestore(doc))
        .toList();
  }

  Future<void> updateUser(app_user.User user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toFirestore());
  }

  Future<void> createUser(app_user.User user) async {
    try {
      // Ensure the current user is HOD before creating new user
      final currentUser = await getCurrentUser();
      if (!currentUser.isHOD) {
        throw Exception('Only HOD can create new users');
      }

      // Create the user document in Firestore
      await _firestore
          .collection('users')
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<List<app_user.User>> getUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs
          .map((doc) => app_user.User.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  Future<void> updateUserDetails({
    required String userId,
    required String displayName,
    required String email,
    String? password,
  }) async {
    try {
      // Update Firestore document
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        'email': email,
      });

      // Update Firebase Auth if password is provided
      if (password != null && password.isNotEmpty) {
        final currentAuthUser = _auth.currentUser;
        if (currentAuthUser?.uid == userId) {
          await currentAuthUser?.updatePassword(password);
          await currentAuthUser?.verifyBeforeUpdateEmail(email);
        }
      }
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      // Delete from Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Delete from Firebase Auth
      final currentAuthUser = _auth.currentUser;
      if (currentAuthUser?.uid == userId) {
        await currentAuthUser?.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
