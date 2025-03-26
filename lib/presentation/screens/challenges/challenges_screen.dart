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

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  String _filter = 'all'; // 'all', 'completed', 'pending'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadChallenges();
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
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        // Load daily challenge
        await challengeProvider.fetchDailyChallenge();
        
        // Load user challenges
        await challengeProvider.fetchUserChallenges(authProvider.currentUser!.id);
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

              // Filter user challenges based on tab
              final userChallenges = challengeProvider.userChallenges;
              List<dynamic> filteredChallenges = [];
              
              switch (_tabController.index) {
                case 0: // All
                  filteredChallenges = userChallenges;
                  break;
                case 1: // Pending
                  filteredChallenges = userChallenges.where((challenge) => 
                    challenge.status == 'pending' || challenge.status == 'in_progress').toList();
                  break;
                case 2: // Completed
                  filteredChallenges = userChallenges.where((challenge) => 
                    challenge.status == 'completed').toList();
                  break;
              }

              // For demo purposes, if no challenges, add daily challenge
              if (filteredChallenges.isEmpty && challengeProvider.dailyChallenge != null) {
                filteredChallenges = [challengeProvider.dailyChallenge!];
              }

              return RefreshIndicator(
                onRefresh: _loadChallenges,
                child: filteredChallenges.isEmpty 
                  ? _buildEmptyState() 
                  : _buildChallengesList(filteredChallenges, challengeProvider),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Refresh challenges
          _loadChallenges();
        },
        tooltip: 'Rafraîchir',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = '';
    
    switch (_tabController.index) {
      case 0:
        message = 'Aucun défi disponible pour le moment';
        break;
      case 1:
        message = 'Vous n\'avez pas de défis en cours';
        break;
      case 2:
        message = 'Vous n\'avez pas encore complété de défis';
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Revenez plus tard pour de nouveaux défis!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesList(List<dynamic> challenges, ChallengeProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        // Handle both DailyChallenge and UserChallenge objects
        final challenge = challenges[index];
        final bool isCompleted = challenge is DailyChallenge
            ? provider.isChallengeCompleted(challenge.id)
            : challenge.status == 'completed';
        
        // Get title and description
        final String title = challenge is DailyChallenge 
            ? challenge.title 
            : challenge.dailyChallenge?.title ?? 'Défi';
        
        final String description = challenge is DailyChallenge 
            ? challenge.description 
            : challenge.dailyChallenge?.description ?? 'Description non disponible';
        
        // Get difficulty and experience points
        final String difficulty = challenge is DailyChallenge 
            ? challenge.difficulty 
            : challenge.dailyChallenge?.difficulty ?? 'Intermédiaire';
        
        final int experiencePoints = challenge is DailyChallenge 
            ? challenge.experiencePoints 
            : challenge.experienceGained ?? 0;

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChallengeDetailScreen(
                    challengeId: challenge is DailyChallenge ? challenge.id : challenge.challengeId,
                    userChallengeId: challenge is DailyChallenge ? null : challenge.id,
                  ),
                ),
              ).then((_) => _loadChallenges());
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Challenge title and status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  
                  // Challenge description
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Challenge details (difficulty, XP)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailChip(
                        _getDifficultyIcon(difficulty), 
                        difficulty,
                        _getDifficultyColor(difficulty),
                      ),
                      _buildDetailChip(
                        Icons.star, 
                        '$experiencePoints XP',
                        Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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
}