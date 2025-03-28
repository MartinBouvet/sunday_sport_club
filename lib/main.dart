import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/supabase_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/challenge_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/routine_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/screens/splash_screen.dart';
import 'package:flutter/services.dart';
import '../config/themes.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations (portrait only)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Supabase
  try {
    await initializeSupabase();
    runApp(const SundaySportApp());
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
}

class SundaySportApp extends StatelessWidget {
  const SundaySportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => RoutineProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
      ],
      child: MaterialApp(
        title: 'Sunday Sport Club',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}