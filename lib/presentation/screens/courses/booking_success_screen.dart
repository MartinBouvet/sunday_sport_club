import 'package:flutter/material.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import 'user_bookings_screen.dart';

class BookingSuccessScreen extends StatelessWidget {
  final Course course;
  final MembershipCard membershipCard;

  const BookingSuccessScreen({
    Key? key,
    required this.course,
    required this.membershipCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animation de succès
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 80,
                ),
              ),
              const SizedBox(height: 24),

              // Message de succès
              const Text(
                'Réservation confirmée !',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Votre cours a été réservé avec succès.',
                style: TextStyle(fontSize: 16, color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Détails de la réservation
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      // Titre du cours
                      Text(
                        course.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Détails du cours
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date',
                        '${course.date.day}/${course.date.month}/${course.date.year}',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.access_time,
                        'Horaire',
                        '${course.startTime} - ${course.endTime}',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.credit_card,
                        'Carnet utilisé',
                        membershipCard.type == 'individuel'
                            ? 'Carnet Individuel'
                            : 'Carnet Collectif',
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow(
                        Icons.confirmation_number,
                        'Séances restantes',
                        '${membershipCard.remainingSessions - 1}/${membershipCard.totalSessions}',
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Boutons d'action
              AppButton(
                text: 'Voir mes réservations',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserBookingsScreen(),
                    ),
                  );
                },
                type: AppButtonType.primary,
                size: AppButtonSize.large,
                fullWidth: true,
              ),
              const SizedBox(height: 16),

              AppButton(
                text: 'Retour à l\'accueil',
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                type: AppButtonType.outline,
                size: AppButtonSize.large,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
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
}
