import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../events/settings_event.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../states/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final _auth = auth.FirebaseAuth.instance;
  final _userRepository = UserRepository();

  SettingsBloc() : super(SettingsInitial()) {
    on<ShowAboutDialog>(_onShowAboutDialog);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<CreateNewUser>(_onCreateNewUser);
  }

  Future<void> _onShowAboutDialog(ShowAboutDialog event, Emitter<SettingsState> emit) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = 'Version ${packageInfo.version}';
      const developerInfo = 'Developed by Ravi Kumar E';
      
      emit(ShowAboutDialogState(
        developerInfo: developerInfo,
        version: version,
      ));
    } catch (e) {
      emit(SettingsError(message: 'Failed to load app information'));
    }
  }

  Future<void> _onUpdateDisplayName(
    UpdateDisplayName event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(SettingsLoading());
      
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        emit(SettingsError(message: 'No user logged in'));
        return;
      }

      // Update display name in Firebase
      await user.updateDisplayName(event.newDisplayName);
      
      // Optionally update any additional user data in Firestore if needed
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'displayName': event.newDisplayName});

      emit(DisplayNameUpdated(newDisplayName: event.newDisplayName));
    } catch (e) {
      emit(SettingsError(message: 'Failed to update display name: ${e.toString()}'));
    }
  }

  Future<void> _onCreateNewUser(
    CreateNewUser event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      emit(SettingsLoading());
      
      // Check if current user is HOD
      final currentUser = await _userRepository.getCurrentUser();
      if (!currentUser.isHOD) {
        throw Exception('Only HOD can create new users');
      }

      // Create a secondary Firebase Auth instance for user creation
      final secondaryAuth = auth.FirebaseAuth.instance;
      final currentAuth = await secondaryAuth.createUserWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Get the user credential but don't sign in
      final newUserCredential = currentAuth.user;
      if (newUserCredential == null) {
        throw Exception('Failed to create user account');
      }

      // Update display name
      await newUserCredential.updateDisplayName(event.displayName);

      // Create user document in Firestore
      final newUser = User(
        id: newUserCredential.uid,
        email: event.email,
        isHOD: false,
        displayName: event.displayName,
      );

      await _userRepository.createUser(newUser);

      // Sign out the newly created user to restore HOD session
      await secondaryAuth.signOut();
      
      // Re-authenticate HOD if needed
      if (_auth.currentUser == null) {
        // You might want to store HOD credentials securely or handle re-authentication
        // For now, we'll assume HOD session is maintained
        emit(SettingsError(message: 'HOD session expired. Please login again.'));
        return;
      }

      emit(UserCreated());
    } catch (e) {
      emit(SettingsError(message: 'Failed to create user: ${e.toString()}'));
    }
  }
}
      