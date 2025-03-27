import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../core/widgets/error_display.dart';
import '../../data/models/user_routine.dart';
import '../../data/models/routine.dart';
import '../../data/models/exercise.dart';
import '../../providers/auth_provider.dart';
import '../../providers/routine_provider.dart';

class RoutineValidationScreen extends StatefulWidget {
  const RoutineValidationScreen({Key? key}) : super(key: key);

  @override
  State<RoutineValidationScreen> createState() => _RoutineValidationScreenState();
}

class _RoutineValidationScreenState extends State<RoutineValidationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserRoutine> _allUserRoutines = [];
  List<UserRoutine> _filteredRoutines = [];
  Map<String, Routine> _routinesCache = {};
  Map<String, String> _userNames = {};
  
  // Filtres
  String _currentFilter = "pending"; // pending, validated, rejected
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadRoutines();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _currentFilter = "pending";
            break;
          case 1:
            _currentFilter = "validated";
            break;
          case 2:
            _currentFilter = "rejected";
            break;
        }
      });
      _filterRoutines();
    }
  }
  
  void _filterRoutines() {
    setState(() {
      _filteredRoutines = _allUserRoutines.where((routine) {
        switch (_currentFilter) {
          case "pending":
            return routine.status == 'completed' && !routine.isValidatedByCoach;
          case "validated":
            return routine.status == 'validated';
          case "rejected":
            return routine.status == 'rejected';
          default:
            return true;
        }
      }).toList();
      
      // Tri par date (plus récent d'abord)
      _filteredRoutines.sort((a, b) => b.completedDate?.compareTo(a.completedDate ?? DateTime.now()) ?? 0);
    });
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simuler le chargement des données pour la démo
      await Future.delayed(const Duration(seconds: 1));
      
      // Créer des routines utilisateur fictives pour la démo
      final routineData = _createMockRoutineData();
      
      setState(() {
        _allUserRoutines = routineData['userRoutines'] as List<UserRoutine>;
        _routinesCache = routineData['routines'] as Map<String, Routine>;
        _userNames = routineData['userNames'] as Map<String, String>;
        _filterRoutines();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des routines: $e';
        _isLoading = false;
      });
    }
  }
  
  // Génération de données fictives pour la démo
  Map<String, dynamic> _createMockRoutineData() {
    List<UserRoutine> userRoutines = [];
    Map<String, Routine> routines = {};
    Map<String, String> userNames = {};
    
    // Créer quelques routines de base
    final routinesList = [
      Routine(
        id: 'routine1',
        name: 'Renforcement musculaire complet',
        description: 'Routine complète pour renforcer tous les groupes musculaires',
        difficulty: 'Intermédiaire',
        estimatedDurationMinutes: 45,
        exerciseIds: ['ex1', 'ex2', 'ex3', 'ex4'],
        exerciseDetails: {
          'ex1': {'sets': 3, 'reps': 12},
          'ex2': {'sets': 4, 'reps': 10},
          'ex3': {'sets': 3, 'reps': 15},
          'ex4': {'sets': 3, 'reps': 20},
        },
      ),
      Routine(
        id: 'routine2',
        name: 'Cardio intensif',
        description: 'Routine de cardio à haute intensité pour brûler des calories',
        difficulty: 'Difficile',
        estimatedDurationMinutes: 30,
        exerciseIds: ['ex5', 'ex6', 'ex7'],
        exerciseDetails: {
          'ex5': {'sets': 4, 'reps': 20},
          'ex6': {'sets': 3, 'reps': 15},
          'ex7': {'sets': 5, 'reps': 10},
        },
      ),
      Routine(
        id: 'routine3',
        name: 'Débutant full-body',
        description: 'Routine complète pour débutants',
        difficulty: 'Facile',
        estimatedDurationMinutes: 35,
        exerciseIds: ['ex1', 'ex8', 'ex9'],
        exerciseDetails: {
          'ex1': {'sets': 2, 'reps': 10},
          'ex8': {'sets': 2, 'reps': 12},
          'ex9': {'sets': 2, 'reps': 15},
        },
      ),
    ];
    
    for (var routine in routinesList) {
      routines[routine.id] = routine;
    }
    
    // Créer des utilisateurs fictifs
    final usersList = {
      'user1': 'Jean Dupont',
      'user2': 'Marie Martin',
      'user3': 'Pierre Dubois',
      'user4': 'Sophie Lefebvre',
      'user5': 'Thomas Bernard',
    };
    
    userNames.addAll(usersList);
    
    // Générer des routines utilisateur
    final now = DateTime.now();
    final List<String> statuses = ['completed', 'validated', 'rejected'];
    
    for (int i = 0; i < 15; i++) {
      final userId = 'user${(i % 5) + 1}';
      final routineId = 'routine${(i % 3) + 1}';
      final status = statuses[i % 3];
      final assignedDate = now.subtract(Duration(days: 30 - i));
      final completedDate = status != 'completed' ? assignedDate.add(const Duration(days: 5)) : null;
      final isValidated = status == 'validated';
      
      userRoutines.add(UserRoutine(
        id: 'userRoutine$i',
        userId: userId,
        routineId: routineId,
        assignedDate: assignedDate,
        dueDate: assignedDate.add(const Duration(days: 7)),
        status: status,
        isValidatedByCoach: isValidated,
        completedDate: completedDate,
        exercisesCompleted: {
          'ex1': true,
          'ex2': true,
          'ex3': i % 2 == 0,
          'ex4': i % 3 == 0,
          'ex5': true,
          'ex6': i % 2 != 0,
          'ex7': true,
          'ex8': i % 3 != 0,
          'ex9': true,
        },
      ));
    }
    
    return {
      'userRoutines': userRoutines,
      'routines': routines,
      'userNames': userNames,
    };
  }
  
  Future<void> _validateRoutine(UserRoutine userRoutine, bool isValidated) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Simuler une requête réseau
      await Future.delayed(const Duration(seconds: 1));
      
      // Mettre à jour l'état de la routine
      final index = _allUserRoutines.indexWhere((r) => r.id == userRoutine.id);
      if (index != -1) {
        setState(() {
          _allUserRoutines[index] = _allUserRoutines[index].copyWith(
            status: isValidated ? 'validated' : 'rejected',
            isValidatedByCoach: isValidated,
          );
        });
        
        // Mettre à jour la liste filtrée
        _filterRoutines();
        
        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValidated 
              ? 'Routine validée avec succès!' 
              : 'Routine rejetée!'),
            backgroundColor: isValidated ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showFeedbackDialog(UserRoutine userRoutine, bool isValidating) {
    final TextEditingController feedbackController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isValidating ? 'Valider la routine' : 'Rejeter la routine'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Routine: ${_routinesCache[userRoutine.routineId]?.name ?? 'Inconnue'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Utilisateur: ${_userNames[userRoutine.userId] ?? 'Inconnu'}'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ajoutez un retour pour l\'utilisateur...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _validateRoutine(userRoutine, isValidating);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isValidating ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(isValidating ? 'Valider' : 'Rejeter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des routines'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'En attente'),
            Tab(text: 'Validées'),
            Tab(text: 'Rejetées'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRoutines,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement des routines...')
          : _errorMessage != null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadRoutines,
                )
              : Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    // Vérifier si l'utilisateur est admin
                    final user = authProvider.currentUser;
                    if (user == null || user.role != 'admin') {
                      return const Center(
                        child: Text('Accès restreint - Zone administrateur'),
                      );
                    }
                    
                    return Column(
                      children: [
                        // Compteur de routines
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_filteredRoutines.length} routine${_filteredRoutines.length > 1 ? "s" : ""}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _currentFilter == "pending" ? Colors.orange : null,
                                ),
                              ),
                              if (_currentFilter == "pending" && _filteredRoutines.isNotEmpty)
                                AppButton(
                                  text: 'Tout valider',
                                  onPressed: () {
                                    // Afficher une boîte de dialogue de confirmation
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Valider toutes les routines'),
                                        content: Text('Êtes-vous sûr de vouloir valider les ${_filteredRoutines.length} routines en attente?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: const Text('Annuler'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              // Valider toutes les routines en attente
                                              for (var routine in List.from(_filteredRoutines)) {
                                                _validateRoutine(routine, true);
                                              }
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Valider tout'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  type: AppButtonType.outline,
                                  size: AppButtonSize.small,
                                  icon: Icons.check_circle,
                                ),
                            ],
                          ),
                        ),
                        
                        // Liste des routines
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadRoutines,
                            child: _filteredRoutines.isEmpty
                                ? _buildEmptyState()
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _filteredRoutines.length,
                                    itemBuilder: (context, index) {
                                      final userRoutine = _filteredRoutines[index];
                                      return _buildUserRoutineCard(userRoutine);
                                    },
                                  ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
  
  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.check_circle;
    
    switch (_currentFilter) {
      case "pending":
        message = 'Aucune routine en attente de validation';
        icon = Icons.pending_actions;
        break;
      case "validated":
        message = 'Aucune routine validée';
        icon = Icons.check_circle;
        break;
      case "rejected":
        message = 'Aucune routine rejetée';
        icon = Icons.cancel;
        break;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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
          ),
          const SizedBox(height: 8),
          Text(
            _currentFilter == "pending"
                ? 'Toutes les routines ont été traitées!'
                : 'Les routines apparaîtront ici une fois traitées',
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
  
  Widget _buildUserRoutineCard(UserRoutine userRoutine) {
    final routine = _routinesCache[userRoutine.routineId];
    final userName = _userNames[userRoutine.userId] ?? 'Utilisateur inconnu';
    
    // Déterminer la couleur et l'icône en fonction du statut
    Color statusColor;
    IconData statusIcon;
    
    switch (userRoutine.status) {
      case 'validated':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'completed':
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        break;
    }
    
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom de routine et badge de statut
            Row(
              children: [
                Expanded(
                  child: Text(
                    routine?.name ?? 'Routine inconnue',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        userRoutine.status == 'validated'
                            ? 'Validée'
                            : (userRoutine.status == 'rejected' ? 'Rejetée' : 'En attente'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Informations sur l'utilisateur et la routine
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Par $userName',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  routine?.difficulty ?? 'Difficulté inconnue',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 4),
            
            // Date de complétion
            if (userRoutine.completedDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complétée le ${DateFormat('dd/MM/yyyy').format(userRoutine.completedDate!)}',
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            
            // Description de la routine
            if (routine?.description != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  routine!.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            
            // Progrès des exercices
            if (userRoutine.exercisesCompleted.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercices complétés: ${userRoutine.exercisesCompleted.values.where((v) => v).length}/${userRoutine.exercisesCompleted.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: userRoutine.exercisesCompleted.isEmpty 
                          ? 0.0 
                          : userRoutine.exercisesCompleted.values.where((v) => v).length / userRoutine.exercisesCompleted.length,
                      backgroundColor: Colors.grey[200],
                      color: statusColor,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_currentFilter == "pending") ...[
                  // Actions pour les routines en attente
                  TextButton.icon(
                    onPressed: () => _showFeedbackDialog(userRoutine, false),
                    icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                    label: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showFeedbackDialog(userRoutine, true),
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  // Actions pour les routines déjà traitées
                  TextButton.icon(
                    onPressed: () {
                      // Afficher les détails de la routine
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Fonctionnalité à implémenter: Voir les détails'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Détails'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}