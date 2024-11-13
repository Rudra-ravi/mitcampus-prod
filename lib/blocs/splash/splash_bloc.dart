import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class SplashEvent {}
class InitializeSplash extends SplashEvent {}

// States
abstract class SplashState {}
class SplashInitial extends SplashState {}
class SplashCompleted extends SplashState {
  final bool isAuthenticated;
  SplashCompleted({required this.isAuthenticated});
}
class SplashError extends SplashState {
  final String message;
  SplashError({required this.message});
}

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  SplashBloc() : super(SplashInitial()) {
    on<InitializeSplash>((event, emit) async {
      try {
        // Add initialization delay for splash screen
        await Future.delayed(const Duration(seconds: 2));
        
        // Check both Firebase Auth and SharedPreferences
        final currentUser = _auth.currentUser;
        final prefs = await SharedPreferences.getInstance();
        final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
        
        emit(SplashCompleted(
          isAuthenticated: currentUser != null && isLoggedIn
        ));
      } catch (e) {
        emit(SplashError(message: e.toString()));
      }
    });
  }
} 