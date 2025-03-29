import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../providers/course_provider.dart';
import '../../providers/auth_provider.dart';
import 'course_detail_screen.dart';
import 'user_bookings_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  String _filter = 'all'; // 'all', 'individuel', 'collectif'
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourses();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final courseProvider = Provider.of<CourseProvider>(
        context,
        listen: false,
      );
      await courseProvider.fetchAvailableCourses(
        startDate: _startDate,
        endDate: _endDate,
        type: _filter == 'all' ? null : _filter,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours disponibles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Disponibles'), Tab(text: 'Mes réservations')],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrer',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Available Courses
          _buildAvailableCoursesTab(),

          // Tab 2: User's Bookings
          _navigateToBookingsScreen(),
        ],
      ),
    );
  }

  Widget _buildAvailableCoursesTab() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;

        if (user == null) {
          return const Center(
            child: Text('Veuillez vous connecter pour accéder à cette page'),
          );
        }

        return Consumer<CourseProvider>(
          builder: (context, courseProvider, _) {
            if (_isLoading || courseProvider.isLoading) {
              return const LoadingIndicator(
                center: true,
                message: 'Chargement des cours...',
              );
            }

            if (courseProvider.hasError) {
              return ErrorDisplay(
                message: courseProvider.errorMessage!,
                type: ErrorType.network,
                actionLabel: 'Réessayer',
                onAction: _loadCourses,
              );
            }

            final courses = courseProvider.availableCourses;

            if (courses.isEmpty) {
              return const Center(
                child: Text('Aucun cours disponible pour le moment'),
              );
            }

            return RefreshIndicator(
              onRefresh: _loadCourses,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: courses.length,
                itemBuilder: (context, index) {
                  final course = courses[index];
                  return _buildCourseCard(context, course);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _navigateToBookingsScreen() {
    // When this tab is selected, navigate to the bookings screen
    WidgetsBinding.instance?.addPostFrameCallback((_) {
      if (_tabController.index == 1) {
        _tabController.animateTo(0); // Switch back to first tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const UserBookingsScreen()),
        );
      }
    });

    // Return empty container as placeholder
    return Container();
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final Color cardColor =
        course.type == 'individuel' ? Colors.blue : Colors.green;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course title and type badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      course.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cardColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      course.type == 'individuel' ? 'Individuel' : 'Collectif',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                course.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Date, time and availability
              Row(
                children: [
                  // Date
                  Icon(Icons.event, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy').format(course.date),
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),

                  // Time
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${course.startTime} - ${course.endTime}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),

                  const Spacer(),

                  // Availability
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getAvailabilityColor(course).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${course.currentParticipants}/${course.capacity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getAvailabilityColor(course),
                      ),
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

  Color _getAvailabilityColor(Course course) {
    if (course.currentParticipants >= course.capacity) {
      return Colors.red;
    } else if (course.currentParticipants >= course.capacity * 0.8) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrer les cours'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type filter
                  const Text(
                    'Type de cours',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildFilterChip(
                        'Tous',
                        _filter == 'all',
                        () => setState(() => _filter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Individuel',
                        _filter == 'individuel',
                        () => setState(() => _filter = 'individuel'),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Collectif',
                        _filter == 'collectif',
                        () => setState(() => _filter = 'collectif'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Date range
                  const Text(
                    'Période',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                if (_startDate.isAfter(_endDate)) {
                                  _endDate = _startDate.add(
                                    const Duration(days: 30),
                                  );
                                }
                              });
                            }
                          },
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_startDate),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('au'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Text(
                            DateFormat('dd/MM/yyyy').format(_endDate),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadCourses();
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
