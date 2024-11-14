import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';

import '../events/settings_event.dart';
import '../models/user.dart' as app_user;
import '../repositories/user_repository.dart';
import '../states/settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final _auth = auth.FirebaseAuth.instance;
  final _userRepository = UserRepository();

  SettingsBloc() : super(SettingsInitial()) {
    on<ShowAboutDialog>(_onShowAboutDialog);
    on<UpdateDisplayName>(_onUpdateDisplayName);
    on<CreateNewUser>(_onCreateNewUser);
    on<UpdateUserEvent>(_onUpdateUser);
    on<DeleteUserEvent>(_onDeleteUser);
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
      
      // Store current HOD auth instance
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Create a secondary Firebase Auth instance for new user creation
      final secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      try {
        // Create user with secondary auth instance
        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: event.email,
          password: event.password,
        );

        // Create user document in Firestore
        final newUser = app_user.User(
          id: userCredential.user!.uid,
          email: event.email,
          displayName: event.displayName,
          isHOD: false,
        );

        await _userRepository.createUser(newUser);

        // Delete the secondary app
        await secondaryApp.delete();

        emit(UserCreated());
      } finally {
        // Clean up secondary app even if there's an error
        try {
          await secondaryApp.delete();
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    } catch (e) {
      emit(SettingsError(message: 'Failed to create user: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateUser(UpdateUserEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());
      
      await _userRepository.updateUserDetails(
        userId: event.userId,
        displayName: event.displayName,
        email: event.email,
        password: event.password,
      );
      
      emit(UserUpdated());
    } catch (e) {
      emit(SettingsError(message: 'Failed to update user: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteUser(DeleteUserEvent event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());
      await _userRepository.deleteUser(event.userId);
      emit(UserDeleted());
    } catch (e) {
      emit(SettingsError(message: 'Failed to delete user: ${e.toString()}'));
    }
  }
}
      