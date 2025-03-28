import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/supabase_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/challenge_provider.dart';
import 'presentation/providers/progress_provider.dart';
import 'presentation/providers/user_provider.dart';
import 'presentation/providers/routine_provider.dart';
import 'presentation/providers/booking_provider.dart';
import 'presentation/screens/auth/login_screen.dart'; 
import 'core/utils/auth_route_handler.dart';

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
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Petite pause pour afficher l'écran de démarrage (optionnel)
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    // Vérifie si l'utilisateur est déjà connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUserData();
    
    if (!mounted) return;
    
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      // Redirige selon le rôle (admin ou utilisateur)
      AuthRouteHandler.routeUserBasedOnRole(context, authProvider.currentUser!);
    } else {
      // Sinon, affiche l'écran de connexion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo ou Image de l'application
            Image.asset(
              'assets/images/logo1.png',
              height: 150,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.sports_mma,
                size: 100,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sunday Sport Club',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}