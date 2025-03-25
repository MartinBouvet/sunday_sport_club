import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/utils/supabase_client.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/challenge_provider.dart';
import 'presentation/screens/home/home_screen.dart';

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
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ChallengeProvider()),
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
          appBarTheme: AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}