import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/daily_challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';
import 'challenge_detail_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  String _filter = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Utiliser addPostFrameCallback pour éviter setState pendant le build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChallenges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadChallenges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final challengeProvider = Provider.of<ChallengeProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        // Load all challenges first
        await challengeProvider.fetchAllChallenges();

        // Then load daily challenge
        await challengeProvider.fetchDailyChallenge();

        // Load user challenges
        await challengeProvider.fetchUserChallenges(
          authProvider.currentUser!.id,
        );
      }
    } catch (e) {
      // Error handling is done by the provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Défis'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'En cours'),
            Tab(text: 'Complétés'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
          indicatorWeight: 3.0,
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Veuillez vous connecter pour accéder à cette page'),
            );
          }

          return Consumer<ChallengeProvider>(
            builder: (context, challengeProvider, _) {
              if (_isLoading) {
                return const LoadingIndicator(
                  center: true,
                  message: 'Chargement des défis...',
                );
              }

              if (challengeProvider.hasError) {
                return ErrorDisplay(
                  message: challengeProvider.errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadChallenges,
                );
              }

              // TabBarView pour afficher le contenu des onglets
              return TabBarView(
                controller: _tabController,
                children: [
                  // Onglet "Tous"
                  _buildAllChallengesTab(challengeProvider),

                  // Onglet "En cours"
                  _buildPendingChallengesTab(challengeProvider),

                  // Onglet "Complétés"
                  _buildCompletedChallengesTab(challengeProvider),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadChallenges,
        tooltip: 'Rafraîchir',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildAllChallengesTab(ChallengeProvider provider) {
    final challenges = provider.allChallenges;

    if (challenges.isEmpty) {
      return _buildEmptyState('Aucun défi disponible pour le moment');
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: challenges.length,
        itemBuilder: (context, index) {
          final challenge = challenges[index];
          final bool isCompleted = provider.isChallengeCompleted(challenge.id);

          return _buildChallengeCard(challenge, isCompleted, provider);
        },
      ),
    );
  }

  Widget _buildPendingChallengesTab(ChallengeProvider provider) {
    // Filtrer pour les défis non complétés
    final pendingChallenges =
        provider.allChallenges
            .where((challenge) => !provider.isChallengeCompleted(challenge.id))
            .toList();

    if (pendingChallenges.isEmpty) {
      return _buildEmptyState('Vous n\'avez pas de défis en cours');
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: pendingChallenges.length,
        itemBuilder: (context, index) {
          final challenge = pendingChallenges[index];
          return _buildChallengeCard(challenge, false, provider);
        },
      ),
    );
  }

  Widget _buildCompletedChallengesTab(ChallengeProvider provider) {
    // Filtrer pour les défis complétés
    final completedChallenges =
        provider.allChallenges
            .where((challenge) => provider.isChallengeCompleted(challenge.id))
            .toList();

    if (completedChallenges.isEmpty) {
      return _buildEmptyState('Vous n\'avez pas encore complété de défis');
    }

    return RefreshIndicator(
      onRefresh: _loadChallenges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: completedChallenges.length,
        itemBuilder: (context, index) {
          final challenge = completedChallenges[index];
          return _buildChallengeCard(challenge, true, provider);
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard pour de nouveaux défis!',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    DailyChallenge challenge,
    bool isCompleted,
    ChallengeProvider provider,
  ) {
    Color difficultyColor = _getDifficultyColor(challenge.difficulty);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChallengeDetailScreen(challengeId: challenge.id),
            ),
          ).then((_) => _loadChallenges());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      challenge.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Complété',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                challenge.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Détails du défi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge de difficulté
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: difficultyColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getDifficultyIcon(challenge.difficulty),
                          size: 16,
                          color: difficultyColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          challenge.difficulty,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: difficultyColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Points XP
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.experiencePoints} XP',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'intermédiaire':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Icons.trip_origin;
      case 'intermédiaire':
        return Icons.copyright;
      case 'difficile':
        return Icons.change_history;
      default:
        return Icons.copyright;
    }
  }
}
