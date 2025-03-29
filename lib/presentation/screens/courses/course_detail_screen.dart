import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/course.dart';
import 'course_booking_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAvailable =
        course.status == 'available' &&
        course.currentParticipants < course.capacity;
    final bool isFull = course.currentParticipants >= course.capacity;
    final bool isCancelled = course.status == 'cancelled';
    final bool isPast = course.date.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du cours')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildCourseHeader(context),

            const SizedBox(height: 24),

            // Détails du cours
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
                    const Text(
                      'Détails du cours',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailItem(
                      Icons.calendar_today,
                      'Date',
                      DateFormat.yMMMMd().format(course.date),
                    ),
                    const SizedBox(height: 12),

                    _buildDetailItem(
                      Icons.access_time,
                      'Horaire',
                      '${course.startTime} - ${course.endTime}',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailItem(
                      course.type == 'individuel' ? Icons.person : Icons.group,
                      'Type de cours',
                      course.type == 'individuel' ? 'Individuel' : 'Collectif',
                    ),
                    const SizedBox(height: 12),

                    _buildDetailItem(
                      Icons.people,
                      'Participants',
                      '${course.currentParticipants}/${course.capacity}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Description du cours
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
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      course.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Information sur la disponibilité
            _buildAvailabilityInfo(isAvailable, isFull, isCancelled, isPast),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(
        context,
        isAvailable,
        isFull,
        isCancelled,
        isPast,
      ),
    );
  }

  Widget _buildCourseHeader(BuildContext context) {
    // Icône en fonction du type de cours
    IconData courseIcon =
        course.type == 'individuel' ? Icons.person : Icons.group;
    Color courseColor =
        course.type == 'individuel' ? Colors.indigo : Colors.teal;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icône du cours
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: courseColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(courseIcon, color: courseColor, size: 32),
        ),
        const SizedBox(width: 16),

        // Titre et détails rapides
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                course.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
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
                      color:
                          course.type == 'individuel'
                              ? Colors.indigo.withOpacity(0.1)
                              : Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      course.type == 'individuel' ? 'Individuel' : 'Collectif',
                      style: TextStyle(
                        color:
                            course.type == 'individuel'
                                ? Colors.indigo
                                : Colors.teal,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${DateFormat.yMd().format(course.date)}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.blue, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvailabilityInfo(
    bool isAvailable,
    bool isFull,
    bool isCancelled,
    bool isPast,
  ) {
    IconData icon;
    Color color;
    String message;

    if (isCancelled) {
      icon = Icons.cancel;
      color = Colors.red;
      message = 'Ce cours a été annulé';
    } else if (isPast) {
      icon = Icons.history;
      color = Colors.grey;
      message = 'Ce cours est déjà passé';
    } else if (isFull) {
      icon = Icons.group_off;
      color = Colors.orange;
      message = 'Ce cours est complet';
    } else {
      icon = Icons.check_circle;
      color = Colors.green;
      message = 'Ce cours est disponible à la réservation';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    bool isAvailable,
    bool isFull,
    bool isCancelled,
    bool isPast,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: AppButton(
        text:
            isPast
                ? 'Cours déjà passé'
                : isCancelled
                ? 'Cours annulé'
                : isFull
                ? 'Cours complet'
                : 'Réserver ce cours',
        onPressed:
            isAvailable
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseBookingScreen(course: course),
                    ),
                  );
                }
                : null,
        type: AppButtonType.primary,
        size: AppButtonSize.large,
        fullWidth: true,
        icon: isAvailable ? Icons.event_available : Icons.event_busy,
      ),
    );
  }
}
