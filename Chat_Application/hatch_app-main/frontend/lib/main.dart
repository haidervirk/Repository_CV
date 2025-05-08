import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/presentation/auth/welcome_screen.dart';
import 'package:frontend/presentation/auth/login_screen.dart';
import 'package:frontend/presentation/auth/signup_screen.dart';
import 'package:frontend/presentation/auth/reset_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/presentation/navbar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hatch',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme(
          brightness: AppColors.brightness,
          primary: AppColors.primaryColor,
          onPrimary: AppColors.textColor,
          secondary: AppColors.secondaryColor,
          onSecondary: AppColors.lightTextColor,
          error: AppColors.errorColor,
          onError: AppColors.textColor,
          surface: AppColors.backgroundColor,
          onSurface: AppColors.textColor,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return const NavBar();
                }
                return const WelcomeScreen();
              },
            ),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/home': (context) => const NavBar(),
      },
    );
  }
}
