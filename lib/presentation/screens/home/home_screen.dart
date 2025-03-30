import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/progress_provider.dart';
import '../../screens/widgets/home/welcome_card.dart';
import '../../screens/widgets/home/daily_challenge_card.dart';
import '../../screens/widgets/home/menu_card.dart';
import '../../screens/widgets/home/stats_card.dart';
import '../courses/course_list_screen.dart';
import '../routines/routines_screen.dart';
import '../challenges/challenges_screen.dart';
import '../membership/membership_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/stats_screen.dart';
import 'avatar_customization_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      // Charger le défi quotidien
      await challengeProvider.fetchDailyChallenge();
      
      // Vérifier si l'utilisateur a déjà complété le défi
      await challengeProvider.fetchUserChallenges(authProvider.currentUser!.id);
      
      // Charger les dernières statistiques de l'utilisateur
      await progressProvider.fetchLatestProgress(authProvider.currentUser!.id);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading 
          ? const LoadingIndicator(center: true, message: 'Chargement des données...')
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                
                if (user == null) {
                  return const Center(
                    child: Text('Veuillez vous connecter pour accéder à votre compte'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadInitialData,
                  child: CustomScrollView(
                    slivers: [
                      // App Bar personnalisée avec logo
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.blue,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/logo1.png',
                                height: 36,
                                errorBuilder: (context, error, stackTrace) => const SizedBox(),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Sunday Sport Club',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          centerTitle: true,
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.blue.shade700, Colors.blue],
                              ),
                            ),
                          ),
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.person, color: Colors.white),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      // Contenu principal
                      SliverPadding(
                        padding: const EdgeInsets.all(16.0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Carte de bienvenue
                            WelcomeCard(
                              userName: "${user.firstName} ${user.lastName}",
                              level: user.level,
                              progressPercentage: (user.experiencePoints % 100) / 100,
                              experiencePoints: user.experiencePoints,
                              nextLevelXP: (user.level * 100) + 100,
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Avatar interactif
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AvatarCustomizationScreen(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomRight,
                                      children: [
                                        AvatarWithLevel(
                                          avatar: AvatarDisplay(
                                            gender: user.gender,
                                            skinColor: user.skinColor,
                                            stage: user.avatarStage,
                                            size: 180,
                                            borderWidth: 3.0,
                                          ),
                                          level: user.level,
                                        ),
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
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
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Statistiques de l'utilisateur
                            Consumer<ProgressProvider>(
                              builder: (context, progressProvider, _) {
                                return StatsCard(
                                  weight: user.weight ?? 0.0,
                                  initialWeight: user.initialWeight ?? user.weight ?? 0.0,
                                  endurance: user.endurance,
                                  strength: user.strength,
                                  onUpdatePressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const StatsScreen(),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Défi quotidien
                            Consumer<ChallengeProvider>(
                              builder: (context, challengeProvider, _) {
                                return DailyChallengeCard(
                                  challenge: challengeProvider.dailyChallenge,
                                  isCompleted: challengeProvider.dailyChallenge != null
                                      ? challengeProvider.isChallengeCompleted(challengeProvider.dailyChallenge!.id)
                                      : false,
                                  onComplete: () async {
                                    if (challengeProvider.dailyChallenge != null) {
                                      await challengeProvider.completeChallenge(
                                        challengeProvider.dailyChallenge!.id,
                                        user.id,
                                      );
                                      
                                      // Recharger pour mettre à jour l'avatar si nécessaire
                                      await authProvider.loadUserData();
                                      
                                      // Afficher un message de félicitations
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Félicitations ! +${challengeProvider.dailyChallenge!.experiencePoints} XP gagnés'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Menu principal
                            MenuCard(
                              onRoutinesPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RoutinesScreen(),
                                  ),
                                );
                              },
                              onCoursesPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CourseListScreen(),
                                  ),
                                );
                              },
                              onChallengesPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChallengesScreen(),
                                  ),
                                );
                              },
                              onMembershipPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MembershipScreen(),
                                  ),
                                );
                              },
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Bouton de classement
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LeaderboardScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.leaderboard),
                              label: const Text('Voir le classement'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Accueil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Routines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Cours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              // Déjà sur l'écran d'accueil
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RoutinesScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CourseListScreen()),
              );
              break;
            case 3:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
    );
  }
  
  // Description textuelle du stade de l'avatar
  String _getAvatarStageDescription(String stage) {
    switch (stage) {
      case AppConstants.avatarStageThin:
        return "Débutant - Continuez à vous entraîner !";
      case AppConstants.avatarStageMedium:
        return "Intermédiaire - Vous progressez bien !";
      case AppConstants.avatarStageMuscular:
        return "Avancé - Votre dévouement porte ses fruits !";
      default:
        return "Niveau actuel";
    }
  }
}