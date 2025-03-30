import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../providers/routine_provider.dart';
import '../../providers/auth_provider.dart';
import 'routine_detail_screen.dart';
import '../home/home_screen.dart';
import '../courses/course_list_screen.dart';
import '../profile/profile_screen.dart';
import '../../../data/models/routine.dart';
import '../../../data/models/user_routine.dart';

int _currentTabIndex = 0;


class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Chargement asynchrone à l'initialisation du widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRoutines();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tabController.removeListener(_handleTabSelection);
    super.dispose();
  }

  void _handleTabSelection() {
  if (_tabController.indexIsChanging) {
    setState(() {
      _currentTabIndex = _tabController.index;
    });
    _loadRoutines();
  }
}

  Future<void> _loadRoutines() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final routineProvider = Provider.of<RoutineProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser != null) {
        debugPrint(
          "Récupération des routines pour l'utilisateur: ${authProvider.currentUser!.id}",
        );

        // Chargement des routines disponibles d'abord (toutes les routines)
        await routineProvider.fetchAvailableRoutines();

        // Charger les routines de l'utilisateur
        await routineProvider.fetchUserRoutines(authProvider.currentUser!.id);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des routines: $e');
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
        title: const Text('Mes routines'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mes Routines'),
            Tab(text: 'En cours'),
            Tab(text: 'Terminées'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          indicatorColor: Colors.white,
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

          return Consumer<RoutineProvider>(
            builder: (context, routineProvider, _) {
              if (_isLoading || routineProvider.isLoading) {
                return const LoadingIndicator(
                  center: true,
                  message: 'Chargement des routines...',
                );
              }

              if (routineProvider.hasError) {
                return ErrorDisplay(
                  message: routineProvider.errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadRoutines,
                );
              }

              // Déterminer le contenu à afficher en fonction de l'onglet sélectionné
              switch (_tabController.index) {
                case 0: // Toutes les routines disponibles
                  final availableRoutines = routineProvider.availableRoutines;
                  if (availableRoutines.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildAvailableRoutinesList(availableRoutines, routineProvider);
                
                case 1: // Routines en cours de l'utilisateur
                  final userRoutinesInProgress = routineProvider.userRoutines
                    .where((routine) => routine.status == 'pending' || routine.status == 'in_progress')
                    .toList();
                  if (userRoutinesInProgress.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildUserRoutinesList(userRoutinesInProgress, routineProvider);
                
                case 2: // Routines terminées de l'utilisateur
                  final userRoutinesCompleted = routineProvider.userRoutines
                    .where((routine) => routine.status == 'completed' || routine.status == 'validated')
                    .toList();
                  if (userRoutinesCompleted.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildUserRoutinesList(userRoutinesCompleted, routineProvider);
                
                default:
                  return _buildEmptyState();
              }
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // Routines
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Routines',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_available),
            label: 'Cours',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 1:
              // Déjà sur l'écran routines
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseListScreen(),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
              break;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRoutines,
        tooltip: 'Rafraîchir',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message = '';

    switch (_tabController.index) {
      case 0:
        message = 'Aucune routine disponible actuellement';
        break;
      case 1:
        message = 'Vous n\'avez pas de routines en cours';
        break;
      case 2:
        message = 'Vous n\'avez pas encore terminé de routines';
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Les routines sont des programmes d\'entraînement personnalisés.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Liste des routines disponibles (toutes les routines)
  Widget _buildAvailableRoutinesList(List<Routine> routines, RoutineProvider provider) {
    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          
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
                    builder: (context) => RoutineDetailScreen(
                      routineId: routine.id,
                    ),
                  ),
                ).then((_) => _loadRoutines());
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre de la routine
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            routine.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Indicateur de difficulté
                        _buildDifficultyBadge(routine.difficulty),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Description de la routine
                    Text(
                      routine.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Informations supplémentaires
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.timer,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${routine.estimatedDurationMinutes} min',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '2 exercices',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Bouton de démarrage
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoutineDetailScreen(
                                routineId: routine.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Voir les détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Liste des routines de l'utilisateur (en cours ou terminées)
  Widget _buildUserRoutinesList(List<UserRoutine> routines, RoutineProvider provider) {
    return RefreshIndicator(
      onRefresh: _loadRoutines,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final userRoutine = routines[index];
          
          // Récupérer les détails de la routine associée
          final associatedRoutine = provider.availableRoutines
              .firstWhere((r) => r.id == userRoutine.routineId, 
                           orElse: () => Routine(
                            id: 'unknown',
                            name: 'Routine inconnue',
                            description: 'Détails non disponibles',
                            difficulty: 'Intermédiaire',
                            estimatedDurationMinutes: 0,
                            exerciseIds: [],
                            exerciseDetails: {},
                            createdBy: 'system',
                            createdAt: DateTime.now(),
                            isPublic: true,
                          ));
          
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
                    builder: (context) => RoutineDetailScreen(
                      routineId: userRoutine.routineId,
                      userRoutineId: userRoutine.id,
                    ),
                  ),
                ).then((_) => _loadRoutines());
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
                            associatedRoutine.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(userRoutine.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Date d'assignation
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Assignée le: ${_formatDate(userRoutine.assignedDate)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description de la routine
                    Text(
                      associatedRoutine.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Barre de progression pour les routines en cours
                    if (userRoutine.status == 'in_progress' || userRoutine.status == 'pending')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progression',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                userRoutine.status == 'in_progress' ? '50%' : '0%',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: userRoutine.status == 'in_progress' ? 0.5 : 0.0,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    
                    // Date de complétion pour les routines terminées
                    if (userRoutine.completionDate != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Terminée le: ${_formatDate(userRoutine.completionDate!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (userRoutine.status == 'pending' || userRoutine.status == 'in_progress')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoutineDetailScreen(
                                    routineId: userRoutine.routineId,
                                    userRoutineId: userRoutine.id,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.play_arrow, size: 16),
                            label: const Text('Commencer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        
                        if (userRoutine.status == 'completed' || userRoutine.status == 'validated')
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoutineDetailScreen(
                                    routineId: userRoutine.routineId,
                                    userRoutineId: userRoutine.id,
                                  ),
                                ),
                              );
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
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    String label;
    Color color;

    switch (status) {
      case 'pending':
        label = 'À faire';
        color = Colors.orange;
        break;
      case 'in_progress':
        label = 'En cours';
        color = Colors.blue;
        break;
      case 'completed':
        label = 'Terminée';
        color = Colors.green;
        break;
      case 'validated':
        label = 'Validée';
        color = Colors.purple;
        break;
      default:
        label = status;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(String difficulty) {
    Color color;
    
    switch (difficulty.toLowerCase()) {
      case 'débutant':
      case 'facile':
        color = Colors.green;
        break;
      case 'intermédiaire':
        color = Colors.orange;
        break;
      case 'avancé':
      case 'difficile':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        difficulty,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}