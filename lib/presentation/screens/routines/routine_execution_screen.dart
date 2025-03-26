import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/exercise.dart';
import '../../providers/routine_provider.dart';
import '../../providers/auth_provider.dart';

class RoutineExecutionScreen extends StatefulWidget {
  final String routineId;
  final String? userRoutineId;

  const RoutineExecutionScreen({
    Key? key,
    required this.routineId,
    this.userRoutineId,
  }) : super(key: key);

  @override
  State<RoutineExecutionScreen> createState() => _RoutineExecutionScreenState();
}

class _RoutineExecutionScreenState extends State<RoutineExecutionScreen> {
  bool _isLoading = true;
  Routine? _routine;
  List<Exercise> _exercises = [];
  String? _errorMessage;
  
  // État d'exécution
  int _currentExerciseIndex = 0;
  int _currentSet = 1;
  bool _isResting = false;
  int _timerSeconds = 0;
  Timer? _timer;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _loadRoutineDetails();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
        
        // Préparer le timer pour le premier exercice
        if (_exercises.isNotEmpty) {
          _timerSeconds = _exercises[0].durationSeconds;
          _startTimer();
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
  
  void _startTimer() {
    _timer?.cancel();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timer?.cancel();
          // Passage automatique au prochain set ou exercice
          if (_isResting) {
            _isResting = false;
            if (_currentExerciseIndex < _exercises.length) {
              _timerSeconds = _exercises[_currentExerciseIndex].durationSeconds;
            }
          } else {
            if (_currentSet < _getExerciseSets()) {
              _currentSet++;
              _isResting = true;
              _timerSeconds = 30; // Temps de repos par défaut (30 secondes)
            } else {
              _moveToNextExercise();
            }
          }
        }
      });
    });
  }
  
  void _moveToNextExercise() {
    if (_currentExerciseIndex < _exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _currentSet = 1;
        _isResting = false;
        _timerSeconds = _exercises[_currentExerciseIndex].durationSeconds;
      });
      _startTimer();
    } else {
      // Routine terminée
      _timer?.cancel();
      _showCompletionDialog();
    }
  }
  
  int _getExerciseSets() {
    final currentExercise = _exercises[_currentExerciseIndex];
    final exerciseDetails = _routine!.exerciseDetails;
    return exerciseDetails?[currentExercise.id]?['sets'] ?? currentExercise.sets ?? 3;
  }
  
  int _getExerciseReps() {
    final currentExercise = _exercises[_currentExerciseIndex];
    final exerciseDetails = _routine!.exerciseDetails;
    return exerciseDetails?[currentExercise.id]?['reps'] ?? currentExercise.repetitions ?? 10;
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Routine terminée !'),
        content: const Text('Félicitations ! Vous avez terminé tous les exercices de cette routine.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              _completeRoutine();
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _completeRoutine() async {
    if (_routine == null) return;
    
    setState(() {
      _isCompleting = true;
    });
    
    try {
      final routineProvider = Provider.of<RoutineProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser != null && widget.userRoutineId != null) {
        await routineProvider.completeUserRoutine(widget.userRoutineId!);
        
        // Félicitations
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Routine marquée comme terminée ! +25 XP'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
      
      // Retourner à l'écran précédent
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la validation de la routine: $e';
        _isCompleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routine?.name ?? 'Exécution de routine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              _timer?.cancel();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Quitter la routine ?'),
                  content: const Text('Voulez-vous vraiment arrêter cette routine ? Votre progression ne sera pas sauvegardée.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Continuer'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Fermer le dialog
                        Navigator.pop(context); // Retourner à l'écran précédent
                      },
                      child: const Text('Quitter'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Préparation de la routine...')
          : _errorMessage != null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  type: ErrorType.general,
                  actionLabel: 'Réessayer',
                  onAction: _loadRoutineDetails,
                )
              : _buildRoutineExecution(),
    );
  }

  Widget _buildRoutineExecution() {
    if (_routine == null || _exercises.isEmpty) {
      return const Center(
        child: Text('Impossible de démarrer la routine'),
      );
    }

    final currentExercise = _exercises[_currentExerciseIndex];
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Progression
          _buildProgressIndicator(),
          
          const SizedBox(height: 24),
          
          // Nom de l'exercice actuel
          Text(
            currentExercise.name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Phase actuelle (repos ou exercice)
          Text(
            _isResting ? 'REPOS' : 'EXERCICE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isResting ? Colors.green : Colors.blue,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Timer circulaire
          _buildCircularTimer(),
          
          const SizedBox(height: 32),
          
          // Information sur les séries
          Text(
            'Série $_currentSet sur ${_getExerciseSets()}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Information sur les répétitions (seulement si en mode exercice)
          if (!_isResting) ...[
            const SizedBox(height: 8),
            Text(
              '${_getExerciseReps()} répétitions',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Description de l'exercice
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(currentExercise.description),
                  if (!_isResting) ...[
                    const SizedBox(height: 12),
                    _buildTip('Respirez régulièrement, expirez pendant l\'effort'),
                    const SizedBox(height: 4),
                    _buildTip('Concentrez-vous sur la qualité plutôt que la vitesse'),
                  ] else ...[
                    const SizedBox(height: 12),
                    _buildTip('Hydratez-vous pendant la pause'),
                    const SizedBox(height: 4),
                    _buildTip('Respirez profondément et détendez-vous'),
                  ],
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // Boutons de contrôle
          Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Bouton précédent
    IconButton.filled(
      onPressed: _currentExerciseIndex > 0 
          ? () {
              setState(() {
                _currentExerciseIndex--;
                _currentSet = 1;
                _isResting = false;
                _timerSeconds = _exercises[_currentExerciseIndex].durationSeconds;
                _startTimer();
              });
          }
          : null,
      icon: const Icon(Icons.skip_previous),  // ✅ Placed correctly
    ),

    // Bouton pause/play
    IconButton.filled(
      onPressed: () {
        if (_timer?.isActive ?? false) {
          _timer?.cancel();
        } else {
          _startTimer();
        }
        setState(() {});
      },
      icon: Icon(_timer?.isActive ?? false ? Icons.pause : Icons.play_arrow),
      iconSize: 36,
    ),

    // Bouton suivant
    IconButton.filled(
      onPressed: () {
        _timer?.cancel();
        if (_isResting) {
          setState(() {
            _isResting = false;
            _timerSeconds = _exercises[_currentExerciseIndex].durationSeconds;
            _startTimer();
          });
        } else if (_currentSet < _getExerciseSets()) {
          setState(() {
            _currentSet++;
            _isResting = true;
            _timerSeconds = 30; // Temps de repos
            _startTimer();
          });
        } else {
          _moveToNextExercise();
        }
      },
      icon: const Icon(Icons.skip_next), // ✅ Placed correctly
    ),
  ],
),

          
          const SizedBox(height: 16),
          
          // Bouton pour terminer la routine manuellement
          AppButton(
            text: 'Terminer la routine',
            onPressed: _showCompletionDialog,
            type: AppButtonType.outline,
            size: AppButtonSize.medium,
            icon: Icons.check_circle,
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        // Barre de progression
        LinearProgressIndicator(
          value: (_currentExerciseIndex) / _exercises.length,
          minHeight: 10,
          backgroundColor: Colors.grey[300],
          borderRadius: BorderRadius.circular(5),
        ),
        const SizedBox(height: 8),
        
        // Texte de progression
        Text(
          'Exercice ${_currentExerciseIndex + 1} sur ${_exercises.length}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCircularTimer() {
    final maxTime = _isResting 
        ? 30 // Temps de repos fixé
        : _exercises[_currentExerciseIndex].durationSeconds;
    
    final progress = maxTime > 0 ? _timerSeconds / maxTime : 0.0;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cercle de progression
        SizedBox(
          width: 180,
          height: 180,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 12,
            backgroundColor: Colors.grey[300],
            color: _isResting ? Colors.green : Colors.blue,
          ),
        ),
        
        // Temps restant
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatTime(_timerSeconds),
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'secondes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
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
          child: Text(text, style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}