import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/daily_challenge.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/user_challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';
import 'challenge_validation_screen.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final String challengeId;
  final String? userChallengeId;

  const ChallengeDetailScreen({
    Key? key,
    required this.challengeId,
    this.userChallengeId,
  }) : super(key: key);

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  bool _isLoading = false;
  DailyChallenge? _challenge;
  UserChallenge? _userChallenge;
  List<Exercise> _exercises = [];
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _loadChallengeDetails();
  }
  

  Future<void> _loadChallengeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      
      // Get challenge details
      final challenge = await challengeProvider.getChallenge(widget.challengeId);
      setState(() {
        _challenge = challenge;
      });
      
      // Get user challenge if exists
      if (widget.userChallengeId != null) {
        final userChallenge = challengeProvider.userChallenges
            .firstWhere((uc) => uc.id == widget.userChallengeId);
        setState(() {
          _userChallenge = userChallenge;
        });
      }
      
      // Load exercises
      if (_challenge != null) {
        // In a real implementation, you would fetch the exercises
        // For demo, we'll create some mock exercises
        setState(() {
          _exercises = _createMockExercises(_challenge!);
        });
      }
    } catch (e) {
      // Error handled by provider
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Exercise> _createMockExercises(DailyChallenge challenge) {
    // In a real app, you would fetch these from your repository
    // This is just for demonstration
    return [
      Exercise(
        id: '1',
        name: 'Pompes',
        description: 'Effectuez des pompes en gardant le dos droit',
        category: 'force',
        difficulty: challenge.difficulty,
        durationSeconds: 60,
        repetitions: 20,
        sets: 3,
        muscleGroup: 'pectoraux',
      ),
      Exercise(
        id: '2',
        name: 'Squats',
        description: 'Effectuez des squats en gardant le dos droit',
        category: 'force',
        difficulty: challenge.difficulty,
        durationSeconds: 60,
        repetitions: 15,
        sets: 3,
        muscleGroup: 'jambes',
      ),
      Exercise(
        id: '3',
        name: 'Burpees',
        description: 'Enchaînez les mouvements rapidement',
        category: 'cardio',
        difficulty: challenge.difficulty,
        durationSeconds: 30,
        repetitions: 10,
        sets: 3,
        muscleGroup: 'full_body',
      ),
    ];
  }

  Future<void> _completeChallenge() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || _challenge == null) return;
    
    setState(() {
      _isCompleting = true;
    });
    
    try {
      final success = await challengeProvider.completeChallenge(
        _challenge!.id,
        authProvider.currentUser!.id,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Défi complété! +${_challenge!.experiencePoints} XP'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Refresh to update the UI
        await _loadChallengeDetails();
        
        // Optionally navigate to validation screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChallengeValidationScreen(
              challengeId: _challenge!.id,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du défi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChallengeDetails,
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement du défi...')
          : _challenge == null
              ? ErrorDisplay(
                  message: 'Impossible de charger les détails du défi',
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadChallengeDetails,
                )
              : Consumer<ChallengeProvider>(
                  builder: (context, challengeProvider, _) {
                    final isCompleted = widget.userChallengeId != null
                        ? _userChallenge?.status == 'completed'
                        : challengeProvider.isChallengeCompleted(_challenge!.id);

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Card
                          _buildHeaderCard(isCompleted),
                          
                          const SizedBox(height: 24),
                          
                          // Exercises Section
                          _buildExercisesSection(),
                          
                          const SizedBox(height: 24),
                          
                          // Tips Section
                          _buildTipsSection(),
                          
                          const SizedBox(height: 32),
                          
                          // Action Button
                          if (!isCompleted)
                            AppButton(
                              text: 'Marquer comme terminé',
                              onPressed: _completeChallenge,
                              type: AppButtonType.primary,
                              size: AppButtonSize.large,
                              fullWidth: true,
                              icon: Icons.check_circle,
                              isLoading: _isCompleting,
                            )
                          else
                            AppButton(
                              text: 'Défi déjà complété',
                              onPressed: null,
                              type: AppButtonType.outline,
                              size: AppButtonSize.large,
                              fullWidth: true,
                              icon: Icons.emoji_events,
                            ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildHeaderCard(bool isCompleted) {
    if (_challenge == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isCompleted
                ? [Colors.green.shade100, Colors.green.shade50]
                : [Colors.blue.shade100, Colors.blue.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _challenge!.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Complété',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date and difficulty
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(_challenge!.date)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildDifficultyBadge(_challenge!.difficulty),
                ],
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                _challenge!.description,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              
              // XP reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Récompense: +${_challenge!.experiencePoints} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExercisesSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercices à réaliser',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            if (_exercises.isEmpty)
              const Center(
                child: Text(
                  'Aucun exercice disponible pour ce défi',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exercises.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final exercise = _exercises[index];
                  return _buildExerciseItem(exercise);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getExerciseIcon(exercise.category),
          color: Colors.blue,
        ),
      ),
      title: Text(
        exercise.name,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(exercise.description),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${exercise.sets} séries',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('${exercise.repetitions} répétitions'),
        ],
      ),
      onTap: () {
        // Show exercise details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(exercise.name),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(exercise.description),
                  const SizedBox(height: 16),
                  Text('Catégorie: ${exercise.category}'),
                  Text('Difficulté: ${exercise.difficulty}'),
                  Text('Séries: ${exercise.sets}'),
                  Text('Répétitions: ${exercise.repetitions}'),
                  Text('Durée: ${exercise.durationSeconds} secondes'),
                  Text('Groupe musculaire: ${exercise.muscleGroup}'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTipsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Conseils',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildTipItem(
              'Échauffez-vous avant de commencer les exercices',
              Icons.whatshot,
              Colors.orange,
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              'Respectez les temps de repos entre les séries',
              Icons.timer,
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              'Hydratez-vous régulièrement pendant l\'effort',
              Icons.water_drop,
              Colors.lightBlue,
            ),
            const SizedBox(height: 8),
            _buildTipItem(
              'Concentrez-vous sur la qualité plutôt que la vitesse',
              Icons.high_quality,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    IconData icon;
    
    switch (difficulty.toLowerCase()) {
      case 'facile':
        color = Colors.green;
        icon = Icons.trip_origin;
        break;
      case 'intermédiaire':
        color = Colors.orange;
        icon = Icons.copyright;
        break;
      case 'difficile':
        color = Colors.red;
        icon = Icons.change_history;
        break;
      default:
        color = Colors.orange;
        icon = Icons.copyright;
    }
    
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
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            difficulty,
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

  IconData _getExerciseIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'force':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.accessibility_new;
      default:
        return Icons.sports;
    }
  }
}