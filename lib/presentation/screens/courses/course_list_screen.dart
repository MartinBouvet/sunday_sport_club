import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import 'course_detail_screen.dart';
import 'user_bookings_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({Key? key}) : super(key: key);

  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now();
  String _selectedType = 'all'; // 'all', 'individuel', 'collectif'
  int _weekOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculer les dates de début et fin de la semaine sélectionnée
      DateTime startDate = _getStartOfWeek(_selectedDate);
      DateTime endDate = startDate.add(const Duration(days: 6));

      // Charger les cours pour cette période
      await Provider.of<BookingProvider>(
        context,
        listen: false,
      ).fetchAvailableCourses(
        startDate: startDate,
        endDate: endDate,
        type: _selectedType == 'all' ? null : _selectedType,
      );
    } catch (e) {
      // L'erreur est gérée par le provider
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime _getStartOfWeek(DateTime date) {
    // Trouver le lundi de la semaine
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _changeWeek(int offset) {
    setState(() {
      _weekOffset += offset;
      _selectedDate = DateTime.now().add(Duration(days: _weekOffset * 7));
    });
    _loadCourses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cours disponibles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              // Sélectionner une date spécifique
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (pickedDate != null && pickedDate != _selectedDate) {
                setState(() {
                  _selectedDate = pickedDate;
                  _weekOffset = 0; // Réinitialiser l'offset
                });
                _loadCourses();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UserBookingsScreen(),
                ),
              );
            },
            tooltip: 'Mes réservations',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et sélecteur de semaine
          _buildFilters(),

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

                        // Organiser les cours par jour
                        final Map<String, List<Course>> coursesByDay = {};
                        for (var course in courses) {
                          final dateString = DateFormat(
                            'yyyy-MM-dd',
                          ).format(course.date);
                          if (!coursesByDay.containsKey(dateString)) {
                            coursesByDay[dateString] = [];
                          }
                          coursesByDay[dateString]!.add(course);
                        }

                        // Trier les jours
                        final sortedDays = coursesByDay.keys.toList()..sort();

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedDays.length,
                          itemBuilder: (context, index) {
                            final day = sortedDays[index];
                            final coursesForDay = coursesByDay[day]!;

                            // Formater la date d'affichage (ex: Lundi 1 Janvier)
                            final date = DateTime.parse(day);
                            final formattedDate = DateFormat.yMMMMEEEEd()
                                .format(date);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // En-tête du jour
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
                                  child: Text(
                                    formattedDate,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                // Cours du jour
                                ...coursesForDay.map(
                                  (course) => _buildCourseCard(course),
                                ),

                                // Séparateur entre les jours
                                const SizedBox(height: 16),
                              ],
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final DateTime startOfWeek = _getStartOfWeek(_selectedDate);
    final DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    return Column(
      children: [
        // Sélecteur de semaine
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeWeek(-1),
              ),
              Text(
                '${DateFormat.MMMd().format(startOfWeek)} - ${DateFormat.MMMd().format(endOfWeek)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeWeek(1),
              ),
            ],
          ),
        ),

        // Filtres par type
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('Filtrer par type:'),
              const SizedBox(width: 16),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Tous', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Individuels', 'individuel'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Collectifs', 'collectif'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedType == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = value;
        });
        _loadCourses();
      },
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun cours disponible pour cette période',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez une autre semaine ou modifiez vos filtres',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final bool isAvailable =
        course.status == 'available' &&
        course.currentParticipants < course.capacity;

    // Déterminer couleur en fonction du type de cours
    Color courseColor =
        course.type == 'individuel' ? Colors.indigo : Colors.teal;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailScreen(course: course),
            ),
          ).then((_) => _loadCourses());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Heure du cours
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    course.startTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    course.endTime,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              // Séparateur vertical
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 2,
                height: 60,
                color: courseColor.withOpacity(0.2),
              ),

              // Détails du cours
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: courseColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            course.type == 'individuel'
                                ? 'Individuel'
                                : 'Collectif',
                            style: TextStyle(
                              fontSize: 12,
                              color: courseColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${course.currentParticipants}/${course.capacity} places',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAvailable ? Colors.grey[600] : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Badge de disponibilité
              Container(
                margin: const EdgeInsets.only(left: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
