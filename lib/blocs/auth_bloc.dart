import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/services/credential_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Events
abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  LoginEvent({required this.email, required this.password});
}

class LogoutEvent extends AuthEvent {}

class CheckAuthStatusEvent extends AuthEvent {}

// States
abstract class AuthState {
  get user => null;
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  @override
  final User user;

  AuthSuccess({required this.user});
}

class AuthFailure extends AuthState {
  final String error;

  AuthFailure({required this.error});
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthBloc() : super(AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );
      
      // If user is HOD, securely store password
      if (event.email == 'hodece@mvit.edu.in') {
        await CredentialManager.saveHODPassword(event.password);
      }
      
      await _saveAuthStatus(true);
      emit(AuthSuccess(user: userCredential.user!));
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await _auth.signOut();
    await _saveAuthStatus(false);
    emit(AuthInitial());
  }

  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    final user = _auth.currentUser;
    if (user != null) {
      emit(AuthSuccess(user: user));
    } else {
      emit(AuthInitial());
    }
  }

  Future<void> _saveAuthStatus(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', isLoggedIn);
  }
}
