import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/supabase_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/challenge_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/routine_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/screens/auth/login_screen.dart'; // Import de l'écran de connexion

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await initializeSupabase();
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            primary: Colors.blue,
            secondary: Colors.green,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        debugShowCheckedModeBanner: false,
        // Modification: utilisation de LoginScreen comme écran initial
        home: const LoginScreen(),
      ),
    );
  }
}