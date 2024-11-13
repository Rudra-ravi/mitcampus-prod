import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { user, admin, hod }

class User {
  final String id;
  final String email;
  final String? displayName;
  final bool isHOD;
  final UserRole role;

  User({
    required this.id,
    required this.email,
    this.displayName,
    required this.isHOD,
  })  : role = isHOD ? UserRole.hod : UserRole.user;

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      isHOD: data['isHOD'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'isHOD': isHOD,
    };
  }

  bool canManageTasks() => role == UserRole.hod || role == UserRole.admin;
  bool canViewAllTasks() => role != UserRole.user;

  static fromMap(Map<String, dynamic> data) {}
}
