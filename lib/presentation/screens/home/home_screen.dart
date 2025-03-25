import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../presentation/screens/widgets/home/welcome_card.dart';
import '../../../presentation/screens/widgets/home/menu_card.dart';
import '../../../presentation/screens/widgets/home/daily_challenge_card.dart';
import '../../../presentation/providers/challenge_provider.dart';
import '../../../core/widgets/loading_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch daily challenge when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser != null) {
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
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
      body: Consumer2<AuthProvider, ChallengeProvider>(
        builder: (context, authProvider, challengeProvider, child) {
          // Check if user is loading or not authenticated
          if (authProvider.isLoading) {
            return LoadingIndicator.fullScreen();
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return _buildLoginPrompt();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await challengeProvider.fetchDailyChallenge();
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // User Avatar and Welcome Section
                Row(
                  children: [
                    AvatarDisplay(
                      gender: user.gender,
                      skinColor: user.skinColor,
                      stage: user.avatarStage,
                      size: 80,
                      interactive: true,
                      onTap: () {
                        // TODO: Navigate to profile or avatar customization
                      },
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: WelcomeCard(
                        userName: user.firstName,
                        level: user.level,
                        progressPercentage: (user.experiencePoints % 100) / 100,
                        experiencePoints: user.experiencePoints,
                        nextLevelXP: 100, // Based on current level calculation
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Daily Challenge Card
                DailyChallengeCard(
                  challenge: challengeProvider.dailyChallenge,
                  isCompleted:
                      challengeProvider.dailyChallenge != null
                          ? challengeProvider.isChallengeCompleted(
                            challengeProvider.dailyChallenge!.id,
                          )
                          : false,
                  onComplete: () {
                    // TODO: Implement challenge completion logic
                  },
                ),

                const SizedBox(height: 16),

                // Menu Card with Navigation
                MenuCard(
                  onRoutinesPressed: () {
                    // TODO: Navigate to Routines Screen
                  },
                  onCoursesPressed: () {
                    // TODO: Navigate to Courses Screen
                  },
                  onChallengesPressed: () {
                    // TODO: Navigate to Challenges Screen
                  },
                  onMembershipPressed: () {
                    // TODO: Navigate to Membership Screen
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Bienvenue sur Sunday Sport Club',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Connectez-vous pour commencer votre parcours sportif',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to Login Screen
            },
            child: const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}
