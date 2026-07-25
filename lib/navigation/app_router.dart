import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/person_screen.dart';
import '../screens/write_letter_screen.dart';
import '../screens/read_letter_screen.dart';
import '../screens/create_capsule_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case '/home':
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case '/person':
        return MaterialPageRoute(builder: (_) => const PersonScreen());

      case '/write':
        return MaterialPageRoute(builder: (_) => const WriteLetterScreen());

      case '/read':
        return MaterialPageRoute(builder: (_) => const ReadLetterScreen());

      case '/capsule':
        return MaterialPageRoute(builder: (_) => const CreateCapsuleScreen());

      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}