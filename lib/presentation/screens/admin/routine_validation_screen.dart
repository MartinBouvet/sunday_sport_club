import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/user_routine.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/exercise.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/exercise_repository.dart';
import '../../../data/datasources/supabase/supabase_routine_datasource.dart';
import '../../providers/auth_provider.dart';

class RoutineValidationScreen extends StatefulWidget {
  const RoutineValidationScreen({super.key});

  @override
  State<RoutineValidationScreen> createState() => _RoutineValidationScreenState();
}

class _RoutineValidationScreenState extends State<RoutineValidationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Les dépôts pour accéder aux données
  final RoutineRepository _routineRepository = RoutineRepository();
  final UserRepository _userRepository = UserRepository();
  final ExerciseRepository _exerciseRepository = ExerciseRepository();
  final SupabaseRoutineDatasource _routineDatasource = SupabaseRoutineDatasource();
  
  // Données récupérées
  List<UserRoutine> _userRoutines = [];
  List<UserRoutine> _filteredRoutines = [];
  Map<String, Routine> _routinesCache = {};
  Map<String, User> _usersCache = {};
  Map<String, List<Exercise>> _exercisesCache = {};
  
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
      _filteredRoutines = _userRoutines.where((routine) {
        switch (_currentFilter) {
          case "pending":
            return routine.status == 'completed';
          case "validated":
            return routine.status == 'validated';
          case "rejected":
            return routine.status == 'rejected';
          default:
            return true;
        }
      }).toList();
      
      // Tri par date (plus récent d'abord)
      _filteredRoutines.sort((a, b) => 
        b.completionDate?.compareTo(a.completionDate ?? DateTime.now()) ?? 0);
    });
  }

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Récupérer les routines en attente de validation
      final pendingRoutines = await _routineDatasource.getPendingValidationRoutines();
      
      _userRoutines = [];
      for (var data in pendingRoutines) {
        try {
          final userRoutine = UserRoutine.fromJson(data);
          _userRoutines.add(userRoutine);
          
          // Charger la routine associée si elle n'est pas déjà en cache
          if (!_routinesCache.containsKey(userRoutine.routineId)) {
            final routine = await _routineRepository.getRoutine(userRoutine.routineId);
            if (routine != null) {
              _routinesCache[userRoutine.routineId] = routine;
              
              // Précharger les exercices de la routine
              if (routine.exerciseIds.isNotEmpty) {
                _exercisesCache[routine.id] = [];
                for (var exerciseId in routine.exerciseIds) {
                  final exercise = await _exerciseRepository.getExercise(exerciseId);
                  if (exercise != null) {
                    _exercisesCache[routine.id]?.add(exercise);
                  }
                }
              }
            }
          }
          
          // Charger l'utilisateur associé si pas déjà en cache
          if (!_usersCache.containsKey(userRoutine.userId)) {
            final user = await _userRepository.getUser(userRoutine.userId);
            if (user != null) {
              _usersCache[userRoutine.userId] = user;
            }
          }
        } catch (e) {
          debugPrint('Erreur lors du traitement de la routine: $e');
        }
      }
      
      _filterRoutines();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des routines: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _validateRoutine(UserRoutine userRoutine, bool isValidated, String feedback) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Points d'expérience à accorder
      final int xpPoints = isValidated ? 25 : 0; // 25 XP pour une routine validée
      
      // Valider la routine via le datasource
      await _routineDatasource.validateUserRoutine(
        userRoutine.id,
        Provider.of<AuthProvider>(context, listen: false).currentUser!.id,
        feedback,
        xpPoints
      );
      
      // Mettre à jour l'affichage
      await _loadRoutines();
      
      // Afficher un message de confirmation
      if (mounted) {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
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
            Text('Utilisateur: ${_getUserName(userRoutine.userId)}'),
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
              _validateRoutine(
                userRoutine, 
                isValidating, 
                feedbackController.text.trim()
              );
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

  String _getUserName(String userId) {
    final user = _usersCache[userId];
    if (user != null) {
      return '${user.firstName} ${user.lastName}';
    }
    return 'Utilisateur inconnu';
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
          labelColor: Colors.white, // Couleur du texte sélectionné
    unselectedLabelColor: Colors.white.withOpacity(0.7), // Couleur du texte non sélectionné
    labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Texte en gras quand sélectionné
    indicatorColor: Colors.white, // Couleur de l'indicateur (ligne sous l'onglet)
    indicatorWeight: 3.0,
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
                                                _validateRoutine(routine, true, 'Validation groupée');
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
                  'Par ${_getUserName(userRoutine.userId)}',
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
            if (userRoutine.completionDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Complétée le ${DateFormat('dd/MM/yyyy').format(userRoutine.completionDate!)}',
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
            
            // Liste des exercices
            if (routine != null && _exercisesCache.containsKey(routine.id))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercices: ${_exercisesCache[routine.id]?.length ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _exercisesCache[routine.id]?.map((exercise) => 
                        Chip(
                          label: Text(exercise.name),
                          backgroundColor: Colors.blue.withOpacity(0.1),
                        )
                      ).toList() ?? [],
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
                      _showRoutineDetailsDialog(userRoutine);
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
  
  void _showRoutineDetailsDialog(UserRoutine userRoutine) {
    final routine = _routinesCache[userRoutine.routineId];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(routine?.name ?? 'Détails de la routine'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Utilisateur: ${_getUserName(userRoutine.userId)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Statut: ${userRoutine.status}'),
              const SizedBox(height: 8),
              Text('Date d\'assignation: ${DateFormat('dd/MM/yyyy').format(userRoutine.assignedDate)}'),
              if (userRoutine.completionDate != null)
                Text('Date de complétion: ${DateFormat('dd/MM/yyyy').format(userRoutine.completionDate!)}'),
              const SizedBox(height: 16),
              
              if (routine?.description != null) ...[
                const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(routine!.description),
                const SizedBox(height: 16),
              ],
              
              if (routine != null && _exercisesCache.containsKey(routine.id)) ...[
                const Text('Exercices:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._exercisesCache[routine.id]!.map((exercise) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.fitness_center, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${exercise.name} - ${exercise.description}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                ),
              ],
              
              if (userRoutine.feedback != null && userRoutine.feedback!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Commentaire:', style: TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(userRoutine.feedback!),
                ),
              ],
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
  }
}