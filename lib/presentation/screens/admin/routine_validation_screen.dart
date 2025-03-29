import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/datasources/supabase/supabase_routine_datasource.dart';
import '../../../data/models/user_routine.dart';
import '../../../data/models/routine.dart';
import '../../providers/auth_provider.dart';

class RoutineValidationScreen extends StatefulWidget {
  const RoutineValidationScreen({Key? key}) : super(key: key);

  @override
  State<RoutineValidationScreen> createState() =>
      _RoutineValidationScreenState();
}

class _RoutineValidationScreenState extends State<RoutineValidationScreen> {
  final SupabaseRoutineDatasource _routineDatasource =
      SupabaseRoutineDatasource();

  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingRoutines = [];
  String? _errorMessage;

  // Pour le mode détail
  bool _showDetail = false;
  Map<String, dynamic>? _selectedRoutine;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadPendingRoutines();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pendingRoutines =
          await _routineDatasource.getPendingValidationRoutines();

      setState(() {
        _pendingRoutines = pendingRoutines;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des routines: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des routines'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRoutines,
          ),
        ],
      ),
      body:
          _isLoading
              ? const LoadingIndicator(
                center: true,
                message: 'Chargement des routines...',
              )
              : _errorMessage != null
              ? ErrorDisplay(
                message: _errorMessage!,
                type: ErrorType.network,
                actionLabel: 'Réessayer',
                onAction: _loadPendingRoutines,
              )
              : _showDetail
              ? _buildDetailView()
              : _buildRoutinesList(),
    );
  }

  Widget _buildRoutinesList() {
    if (_pendingRoutines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Aucune routine en attente de validation',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Toutes les routines ont été validées',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingRoutines.length,
      itemBuilder: (context, index) {
        final routineData = _pendingRoutines[index];
        final userName =
            '${routineData['profiles']['first_name']} ${routineData['profiles']['last_name']}';
        final routineName =
            routineData['routines']?['name'] ?? 'Routine sans nom';
        final completionDate = DateTime.parse(
          routineData['completion_date'] ?? DateTime.now().toIso8601String(),
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedRoutine = routineData;
                _showDetail = true;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName.substring(0, 1) : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              routineName,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'En attente',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Terminée le: ${DateFormat('dd/MM/yyyy').format(completionDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedRoutine = routineData;
                            _showDetail = true;
                          });
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Détails'),
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

  Widget _buildDetailView() {
    if (_selectedRoutine == null) {
      return ErrorDisplay(
        message: 'Aucune routine sélectionnée',
        type: ErrorType.general,
        actionLabel: 'Retour',
        onAction: () {
          setState(() {
            _showDetail = false;
          });
        },
      );
    }

    final userId = _selectedRoutine!['user_id'];
    final routineId = _selectedRoutine!['routine_id'];
    final userRoutineId = _selectedRoutine!['id'];
    final userName =
        '${_selectedRoutine!['profiles']['first_name']} ${_selectedRoutine!['profiles']['last_name']}';
    final routineName =
        _selectedRoutine!['routines']?['name'] ?? 'Routine sans nom';
    final routineDescription =
        _selectedRoutine!['routines']?['description'] ?? '';
    final completionDate = DateTime.parse(
      _selectedRoutine!['completion_date'] ?? DateTime.now().toIso8601String(),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bouton retour
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showDetail = false;
                _selectedRoutine = null;
                _feedbackController.clear();
              });
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Retour à la liste'),
          ),

          const SizedBox(height: 16),

          // Carte des détails
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // En-tête
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                        child: Text(
                          userName.isNotEmpty ? userName.substring(0, 1) : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'ID: $userId',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'En attente de validation',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Détails de la routine
                  Text(
                    routineName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (routineDescription.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      routineDescription,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Date de complétion
                  Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 16,
                        color: Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Terminée le: ${DateFormat('dd/MM/yyyy à HH:mm').format(completionDate)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),

                  // Section de feedback
                  const SizedBox(height: 24),
                  const Text(
                    'Feedback pour l\'utilisateur (optionnel)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Entrez votre feedback ici...',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed:
                            _isValidating
                                ? null
                                : () {
                                  setState(() {
                                    _showDetail = false;
                                    _selectedRoutine = null;
                                    _feedbackController.clear();
                                  });
                                },
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed:
                            _isValidating
                                ? null
                                : () => _validateRoutine(userRoutineId),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Valider la routine'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _validateRoutine(String userRoutineId) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté pour valider une routine'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isValidating = true;
    });

    try {
      await _routineDatasource.validateUserRoutine(
        userRoutineId,
        authProvider.currentUser!.id,
        feedback:
            _feedbackController.text.isNotEmpty
                ? _feedbackController.text
                : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Routine validée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _showDetail = false;
          _selectedRoutine = null;
          _feedbackController.clear();
        });

        _loadPendingRoutines();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isValidating = false;
      });
    }
  }
}
