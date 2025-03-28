import 'package:flutter/material.dart';
import '../../data/models/user.dart';
import '../../presentation/screens/admin/admin_dashboard.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';

/// Gestionnaire de routes basé sur l'authentification
///
/// Cette classe offre des méthodes utilitaires pour rediriger les utilisateurs
/// vers les bonnes pages en fonction de leur rôle (admin vs utilisateur normal)
class AuthRouteHandler {
  /// Redirige l'utilisateur vers la page appropriée selon son rôle
  ///
  /// Si l'utilisateur est admin, redirige vers le dashboard admin
  /// Sinon, redirige vers l'écran d'accueil standard
  static void routeUserBasedOnRole(BuildContext context, User user) {
    if (user.role == 'admin') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  /// Vérifie si l'utilisateur est connecté et redirige en conséquence
  ///
  /// Si l'utilisateur est connecté, redirige selon son rôle
  /// Sinon, redirige vers l'écran de connexion
  static void checkAuthAndRedirect(BuildContext context, User? user) {
    if (user != null) {
      routeUserBasedOnRole(context, user);
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }
  
  /// Vérifie si l'utilisateur a les droits d'administration
  ///
  /// Retourne true si l'utilisateur est administrateur, false sinon
  static bool isAdmin(User? user) {
    return user != null && user.role == 'admin';
  }
}