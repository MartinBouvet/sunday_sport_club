import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sunday_sport_club/presentation/providers/user_provider.dart';
import 'package:sunday_sport_club/presentation/providers/challenge_provider.dart';
import 'package:sunday_sport_club/presentation/providers/progress_provider.dart';
import 'package:sunday_sport_club/presentation/screens/widgets/home/welcome_card.dart';
import 'package:sunday_sport_club/presentation/screens/widgets/home/stats_card.dart';
import 'package:sunday_sport_club/presentation/screens/widgets/home/menu_card.dart';
import 'package:sunday_sport_club/presentation/screens/widgets/home/daily_challenge_card.dart';
import 'package:sunday_sport_club/core/widgets/avatar_display.dart';
import 'package:sunday_sport_club/core/widgets/loading_indicator.dart';
import 'package:sunday_sport_club/core/constants/app_constants.dart';
import 'package:sunday_sport_club/core/utils/date_utils.dart' as date_utils;

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Chargement des données nécessaires à l'affichage de l'écran d'accueil
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Récupération des données utilisateur
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchCurrentUser();

      // Récupération du défi quotidien
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      await challengeProvider.fetchDailyChallenge();

      // Récupération des données de progression
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      await progressProvider.fetchLatestProgress();

      // Vérification si les données ont été correctement chargées
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });
    }
  }

  // Affichage d'un message d'erreur si le chargement a échoué
  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // Construction du contenu principal de l'écran
  Widget _buildContent() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;
    
    if (user == null) {
      return const Center(
        child: Text('Aucun utilisateur connecté.'),
      );
    }

    // Calcul du pourcentage de progression vers le niveau suivant
    final currentXP = user.experiencePoints;
    final nextLevelXP = AppConstants.xpForDailyChallenge(user.level);
    final previousLevelXP = user.level > 1
        ? AppConstants.calculateXPForNextLevel(user.level - 1) 
        : 0;
    final progressPercentage = (currentXP - previousLevelXP) / (nextLevelXP - previousLevelXP);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Carte de bienvenue avec niveau et progression
            WelcomeCard(
              userName: '${user.firstName} ${user.lastName}',
              level: user.level,
              progressPercentage: progressPercentage,
              experiencePoints: user.experiencePoints,
              nextLevelXP: nextLevelXP,
            ),
            
            const SizedBox(height: 24),
            
            // Affichage de l'avatar
            Center(
              child: Column(
                children: [
                  AvatarDisplay(
                    gender: user.gender,
                    skinColor: user.skinColor,
                    stage: user.avatarStage,
                    size: 200,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Niveau ${user.level}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    user.avatarStage == 'mince' 
                        ? 'Débutant' 
                        : (user.avatarStage == 'moyen' ? 'Intermédiaire' : 'Avancé'),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Carte du défi quotidien
            Consumer<ChallengeProvider>(
              builder: (context, challengeProvider, _) {
                final dailyChallenge = challengeProvider.dailyChallenge;
                final userChallenges = challengeProvider.userChallenges;
                
                final bool isCompleted = dailyChallenge != null && userChallenges.any(
                  (uc) => uc.challengeId == dailyChallenge.id && uc.isCompleted
                );
                
                return DailyChallengeCard(
                  challenge: dailyChallenge,
                  isCompleted: isCompleted,
                  onComplete: () => challengeProvider.completeChallenge(
                    dailyChallenge?.id ?? '',
                    user.id,
                  ),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Carte des statistiques
            Consumer<ProgressProvider>(
              builder: (context, progressProvider, _) {
                final latestProgress = progressProvider.latestProgress;
                
                return StatsCard(
                  weight: latestProgress?.weight ?? user.weight,
                  initialWeight: user.initialWeight,
                  endurance: latestProgress?.endurance ?? user.endurance,
                  strength: latestProgress?.strength ?? user.strength,
                  onUpdatePressed: () => Navigator.pushNamed(context, '/stats'),
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Carte des menus principaux
            MenuCard(
              onRoutinesPressed: () => Navigator.pushNamed(context, '/routines'),
              onCoursesPressed: () => Navigator.pushNamed(context, '/courses'),
              onChallengesPressed: () => Navigator.pushNamed(context, '/challenges'),
              onMembershipPressed: () => Navigator.pushNamed(context, '/membership'),
            ),
            
            const SizedBox(height: 24),
            
            // Classement et badge récents
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Votre classement',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/leaderboard'),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          '#${user.ranking}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text('${user.firstName} ${user.lastName}'),
                      subtitle: Text('${user.experiencePoints} XP'),
                      trailing: Text(
                        'Niveau ${user.level}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),
                    Text(
                      'Derniers badges',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (user.achievements.isNotEmpty)
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: user.achievements.length.clamp(0, 5),
                          itemBuilder: (context, index) {
                            final achievement = user.achievements[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Tooltip(
                                message: achievement,
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  child: Text(
                                    achievement.substring(0, 1),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Text('Aucun badge pour le moment'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunday Sport Club'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Implémenter l'affichage des notifications
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _hasError
              ? _buildErrorWidget()
              : _buildContent(),
    );
  }
}