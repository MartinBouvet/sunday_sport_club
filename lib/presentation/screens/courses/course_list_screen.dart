// lib/presentation/screens/courses/course_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import 'course_detail_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _startDate = DateTime.now();
  String _selectedType = 'all'; // 'all', 'individuel', 'collectif'
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    // Utilisez WidgetsBinding.instance.addPostFrameCallback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourses();
    });
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
          case 0: // Cette semaine
            _startDate = DateTime.now();
            break;
          case 1: // Semaine prochaine
            _startDate = DateTime.now().add(const Duration(days: 7));
            break;
          case 2: // Mois prochain
            _startDate = DateTime.now().add(const Duration(days: 30));
            break;
        }
      });
      _loadCourses();
    }
  }

  Future<void> _loadCourses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      // Définir la période de filtrage selon l'onglet sélectionné
      final DateTime endDate =
          _tabController.index == 2
              ? _startDate.add(const Duration(days: 30)) // Mois
              : _startDate.add(const Duration(days: 7)); // Semaine

      // Filtrer par type si nécessaire
      final String? type = _selectedType == 'all' ? null : _selectedType;

      // Charger les cours disponibles
      await bookingProvider.fetchAvailableCourses(
        startDate: _startDate,
        endDate: endDate,
        type: type,
      );

      // Charger les cartes d'abonnement de l'utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        await bookingProvider.fetchUserMembershipCards(
          authProvider.currentUser!.id,
        );
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des cours: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours disponibles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cette semaine'),
            Tab(text: 'Semaine prochaine'),
            Tab(text: 'Mois prochain'),
          ],
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Veuillez vous connecter pour accéder aux cours'),
            );
          }

          return Column(
            children: [
              // Filtres de type de cours
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Text('Type de cours:'),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Tous'),
                      selected: _selectedType == 'all',
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType = 'all';
                          });
                          _loadCourses();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Individuel'),
                      selected:
                          _selectedType ==
                          AppConstants.membershipTypeIndividual,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType =
                                AppConstants.membershipTypeIndividual;
                          });
                          _loadCourses();
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Collectif'),
                      selected:
                          _selectedType ==
                          AppConstants.membershipTypeCollective,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedType =
                                AppConstants.membershipTypeCollective;
                          });
                          _loadCourses();
                        }
                      },
                    ),
                  ],
                ),
              ),

              // Liste des cours
              Expanded(
                child:
                    _isLoading
                        ? const LoadingIndicator(
                          center: true,
                          message: 'Chargement des cours...',
                        )
                        : Consumer<BookingProvider>(
                          builder: (context, bookingProvider, _) {
                            if (bookingProvider.hasError) {
                              return ErrorDisplay(
                                message: bookingProvider.errorMessage!,
                                type: ErrorType.network,
                                actionLabel: 'Réessayer',
                                onAction: _loadCourses,
                              );
                            }

                            final courses = bookingProvider.availableCourses;

                            if (courses.isEmpty) {
                              return _buildEmptyState();
                            }

                            return RefreshIndicator(
                              onRefresh: _loadCourses,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: courses.length,
                                itemBuilder: (context, index) {
                                  final course = courses[index];
                                  return _buildCourseCard(
                                    course,
                                    bookingProvider,
                                  );
                                },
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Aucun cours disponible pour cette période',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez de changer de date ou de type de cours',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course, BookingProvider bookingProvider) {
    final bool isIndividual =
        course.type == AppConstants.membershipTypeIndividual;
    final Color cardColor = isIndividual ? Colors.indigo : Colors.teal;
    final bool isFull = course.currentParticipants >= course.capacity;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(courseId: course.id),
            ),
          ).then((_) => _loadCourses());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardColor.withOpacity(0.3), width: 1),
          ),
          child: Column(
            children: [
              // En-tête avec type de cours et capacité
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: cardColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isIndividual ? Icons.person : Icons.group,
                          color: cardColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isIndividual ? 'Cours individuel' : 'Cours collectif',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cardColor,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: isFull ? Colors.red : Colors.grey[600],
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${course.currentParticipants}/${course.capacity}',
                          style: TextStyle(
                            color: isFull ? Colors.red : Colors.grey[600],
                            fontWeight:
                                isFull ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre et date
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(course.date),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.startTime} - ${course.endTime}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),

                    // Statut et bouton
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (isFull)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.3),
                              ),
                            ),
                            child: const Text(
                              'Complet',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                        ElevatedButton.icon(
                          onPressed:
                              isFull
                                  ? null
                                  : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => CourseDetailScreen(
                                              courseId: course.id,
                                            ),
                                      ),
                                    );
                                  },
                          icon: const Icon(Icons.visibility, size: 16),
                          label: const Text('Détails'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
}
