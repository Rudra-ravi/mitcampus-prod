import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mitcampus/blocs/auth_bloc.dart';
import 'package:mitcampus/blocs/chat_bloc.dart';
import 'package:mitcampus/blocs/splash/splash_bloc.dart';
import 'package:mitcampus/blocs/task_bloc.dart';
import 'package:mitcampus/blocs/settings_bloc.dart';
import 'package:mitcampus/firebase_options.dart';
import 'package:mitcampus/presentation/screens/splash_screen.dart';
import 'package:mitcampus/screens/home_screen.dart';
import 'package:mitcampus/screens/login_screen.dart';
import 'package:mitcampus/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckAuthStatusEvent()),
        ),
        BlocProvider<ChatBloc>(
          create: (context) => ChatBloc(),
        ),
        BlocProvider<SplashBloc>(
          create: (context) => SplashBloc()..add(InitializeSplash()),
        ),
        BlocProvider<TaskBloc>(
          create: (context) => TaskBloc()..add(LoadTasksEvent()),
        ),
        BlocProvider<SettingsBloc>(
          create: (context) => SettingsBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'MIT Campus',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF2563EB),
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
          useMaterial3: true,
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, authState) {
            return BlocListener<SplashBloc, SplashState>(
              listener: (context, splashState) {
                if (splashState is SplashCompleted) {
                  if (splashState.isAuthenticated && authState is AuthSuccess) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } else {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  }
                } else if (splashState is SplashError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(splashState.message)),
                  );
                }
              },
              child: const SplashScreen(),
            );
          },
        ),
      ),
    );
  }
}
