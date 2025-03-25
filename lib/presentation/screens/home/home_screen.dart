import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/challenge_provider.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../presentation/screens/widgets/home/welcome_card.dart';
import '../../../presentation/screens/widgets/home/daily_challenge_card.dart';
import '../../../presentation/screens/widgets/home/menu_card.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Charger les données initiales lorsque l'écran s'initialise
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);

    if (authProvider.isAuthenticated) {
      challengeProvider.fetchDailyChallenge();
    }
  }

  void _navigateToScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunday Sport Club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigation vers l'écran des paramètres
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ChallengeProvider>(
        builder: (context, authProvider, challengeProvider, child) {
          // Vérifier si l'utilisateur est en cours de chargement ou non authentifié
          if (authProvider.isLoading) {
            return LoadingIndicator.fullScreen();
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return _buildLoginPrompt();
          }

          // Utilisateur authentifié - afficher le contenu principal
          return RefreshIndicator(
            onRefresh: () async {
              await challengeProvider.fetchDailyChallenge();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Carte de bienvenue
                WelcomeCard(
                  userName: "${user.firstName} ${user.lastName}",
                  level: user.level,
                  progressPercentage: (user.experiencePoints % 100) / 100,
                  experiencePoints: user.experiencePoints,
                  nextLevelXP: (user.level + 1) * 100,
                ),
                
                const SizedBox(height: 24),
                
                // Avatar au centre
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'Votre avatar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AvatarDisplay(
                        gender: user.gender,
                        skinColor: user.skinColor,
                        stage: user.avatarStage,
                        size: 200, // Taille augmentée pour un meilleur affichage
                        showBorder: true,
                        borderColor: Theme.of(context).colorScheme.primary,
                        borderWidth: 3.0,
                        interactive: true,
                        onTap: () {
                          // Navigation vers l'écran de personnalisation d'avatar
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getAvatarStageDescription(user.avatarStage),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Défi quotidien
                DailyChallengeCard(
                  challenge: challengeProvider.dailyChallenge,
                  isCompleted: challengeProvider.dailyChallenge != null
                      ? challengeProvider.isChallengeCompleted(
                          challengeProvider.dailyChallenge!.id,
                        )
                      : false,
                  onComplete: () async {
                    if (challengeProvider.dailyChallenge != null) {
                      await challengeProvider.completeChallenge(
                        challengeProvider.dailyChallenge!.id,
                        user.id,
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Menu de navigation
                MenuCard(
                  onRoutinesPressed: () {
                    // Navigation vers l'écran des routines
                  },
                  onCoursesPressed: () {
                    // Navigation vers l'écran des cours
                  },
                  onChallengesPressed: () {
                    // Navigation vers l'écran des défis
                  },
                  onMembershipPressed: () {
                    // Navigation vers l'écran des abonnements
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Description textuelle du stade de l'avatar
  String _getAvatarStageDescription(String stage) {
    switch (stage) {
      case 'mince':
        return "Débutant - Continuez à vous entraîner !";
      case 'moyen':
        return "Intermédiaire - Vous progressez bien !";
      case 'muscle':
        return "Avancé - Votre dévouement porte ses fruits !";
      default:
        return "Niveau actuel";
    }
  }

  // Widget affiché quand l'utilisateur n'est pas connecté
  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.sports_martial_arts,
              size: 80,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              'Bienvenue sur Sunday Sport Club',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Connectez-vous pour accéder à votre profil, suivre vos progrès et participer aux défis quotidiens.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Se connecter',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}