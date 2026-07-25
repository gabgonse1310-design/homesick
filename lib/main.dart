import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/read_letter_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/write_letter_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const HomesickApp());
}

class HomesickApp extends StatelessWidget {
  const HomesickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Homesick',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/read': (_) => const ReadLetterScreen(),
        '/write': (_) => const WriteLetterScreen(),
        '/settings': (_) => const SettingsScreen(),
      },
    );
  }
}
