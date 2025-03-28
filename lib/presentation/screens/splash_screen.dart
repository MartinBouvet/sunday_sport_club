import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth/login_screen.dart';
import 'home/home_screen.dart';
import 'admin/admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Configure l'animation
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    
    // Démarre l'animation
    _controller.forward();
    
    // Vérifie l'authentification après un délai
    _checkAuthentication();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkAuthentication() async {
    // Petite pause pour montrer l'écran de démarrage (et finir l'animation)
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    // Vérifie si l'utilisateur est déjà connecté
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.loadUserData();
    
    if (!mounted) return;
    
    // Navigation basée sur le statut d'authentification
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      // Redirige selon le rôle (admin ou utilisateur)
      final user = authProvider.currentUser!;
      if (user.role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } else {
      // Sinon, affiche l'écran de connexion
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeInAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo ou Image de l'application
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo2.png', // Remplace avec ton chemin d'image
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Sunday Sport Club',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Application de Motivation au sport',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}