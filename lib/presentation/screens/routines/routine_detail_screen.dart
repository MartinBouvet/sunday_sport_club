import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/exercise.dart';
import '../../providers/routine_provider.dart';
import '../../providers/auth_provider.dart';
import 'routine_execution_screen.dart';

class RoutineDetailScreen extends StatefulWidget {
  final String routineId;
  final String? userRoutineId;

  const RoutineDetailScreen({
    Key? key,
    required this.routineId,
    this.userRoutineId,
  }) : super(key: key);

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  bool _isLoading = true;
  Routine? _routine;
  List<Exercise> _exercises = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRoutineDetails();
  }

  Future<void> _loadRoutineDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
      
      // Charger la routine
      _routine = await routineProvider.getRoutineById(widget.routineId);
      
      if (_routine != null) {
        // Charger les exercices associés
        for (final exerciseId in _routine!.exerciseIds) {
          final exercise = await routineProvider.getExerciseById(exerciseId);
          if (exercise != null) {
            _exercises.add(exercise);
          }
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement de la routine: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routine?.name ?? 'Détails de la routine'),
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement de la routine...')
          : _errorMessage != null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  type: ErrorType.general,
                  actionLabel: 'Réessayer',
                  onAction: _loadRoutineDetails,
                )
              : _buildRoutineDetails(),
    );
  }

  Widget _buildRoutineDetails() {
    if (_routine == null) {
      return const Center(
        child: Text('Routine introuvable'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la routine
          _buildRoutineHeader(),
          
          const SizedBox(height: 24),
          
          // Liste des exercices
          _buildExercisesList(),
          
          const SizedBox(height: 32),
          
          // Bouton pour commencer
          AppButton(
            text: 'Commencer la routine',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineExecutionScreen(
                    routineId: _routine!.id,
                    userRoutineId: widget.userRoutineId,
                  ),
                ),
              );
            },
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.play_arrow,
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _routine!.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _routine!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Durée estimée
                _buildInfoChip(
                  '${_routine!.estimatedDurationMinutes} min',
                  Icons.timer,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                // Niveau de difficulté
                _buildInfoChip(
                  _routine!.difficulty,
                  _getDifficultyIcon(_routine!.difficulty),
                  _getDifficultyColor(_routine!.difficulty),
                ),
                const SizedBox(width: 12),
                // Nombre d'exercices
                _buildInfoChip(
                  '${_routine!.exerciseIds.length} exercices',
                  Icons.fitness_center,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList() {
    return Card(
      elevation: 2,
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
                const Text(
                  'Exercices à réaliser',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_exercises.length} exercices',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_exercises.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    'Aucun exercice dans cette routine',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
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
                  return _buildExerciseItem(exercise, index);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseItem(Exercise exercise, int index) {
    // Récupérer les détails spécifiques à l'exercice dans cette routine
    final exerciseDetails = _routine!.exerciseDetails;
    final sets = exerciseDetails?[exercise.id]?['sets'] ?? exercise.sets ?? 3;
    final reps = exerciseDetails?[exercise.id]?['reps'] ?? exercise.repetitions ?? 10;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
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
            '$sets séries',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('$reps répétitions'),
        ],
      ),
      onTap: () {
        // Afficher les détails de l'exercice
        _showExerciseDetails(exercise, sets, reps);
      },
    );
  }

  void _showExerciseDetails(Exercise exercise, int sets, int reps) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et icône de fermeture
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Image ou icône représentative
                Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(exercise.category),
                    size: 64,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Description
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.description,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                
                // Informations détaillées
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildInstructionItem('Séries', '$sets', Icons.repeat),
                const SizedBox(height: 12),
                _buildInstructionItem('Répétitions', '$reps', Icons.fitness_center),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  'Durée', 
                  '${exercise.durationSeconds} secondes', 
                  Icons.timer
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  'Groupe musculaire', 
                  exercise.muscleGroup, 
                  Icons.accessibility_new
                ),
                const SizedBox(height: 24),
                
                // Conseils
                const Text(
                  'Conseils',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTip('Gardez le dos droit pendant l\'exercice'),
                const SizedBox(height: 8),
                _buildTip('Respirez régulièrement, expirez pendant l\'effort'),
                const SizedBox(height: 8),
                _buildTip('Concentrez-vous sur la qualité plutôt que la vitesse'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.blue,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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
        return Icons.arrow_downward;
      case 'intermédiaire':
        return Icons.arrow_forward;
      case 'difficile':
        return Icons.arrow_upward;
      default:
        return Icons.arrow_forward;
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'force':
      case 'strength':
        return Icons.fitness_center;
      case 'flexibility':
        return Icons.accessibility_new;
      default:
        return Icons.sports;
    }
  }
}