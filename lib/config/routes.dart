import 'package:flutter/material.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/auth/signup_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/courses/course_list_screen.dart';
import '../presentation/screens/routines/routines_screen.dart';
import '../presentation/screens/challenges/challenges_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/membership/membership_screen.dart';

// Configuration des routes de l'application
class Routes {
  // Noms des routes
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String courses = '/courses';
  static const String routines = '/routines';
  static const String challenges = '/challenges';
  static const String profile = '/profile';
  static const String membership = '/membership';

  // Configuration des routes avec leurs widgets associés
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      home: (context) => const HomeScreen(),
      courses: (context) => const CourseListScreen(),
      routines: (context) => const RoutinesScreen(),
      challenges: (context) => const ChallengesScreen(),
      profile: (context) => const ProfileScreen(),
      membership: (context) => const MembershipScreen(),
    };
  }
}
