import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      appBar: AppBar(
        title: const Text('Réservation confirmée'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 40),

            // Icône de succès
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ),
            ),
            const SizedBox(height: 32),

            // Titre et message
            const Text(
              'Réservation confirmée !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              'Votre place pour le cours "${course.title}" a été réservée.',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Détails du cours
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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

                    _buildDetailRow(
                      'Type de cours',
                      course.type == 'individuel'
                          ? 'Cours individuel'
                          : 'Cours collectif',
                    ),

                    _buildDetailRow(
                      'Date',
                      DateFormat('dd/MM/yyyy').format(course.date),
                    ),

                    _buildDetailRow(
                      'Horaire',
                      '${course.startTime} - ${course.endTime}',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Détails de la carte utilisée
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Détails du carnet utilisé',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildDetailRow(
                      'Type de carnet',
                      membershipCard.type == 'individuel'
                          ? 'Carnet individuel'
                          : 'Carnet collectif',
                    ),

                    _buildDetailRow(
                      'Séances restantes',
                      '${membershipCard.remainingSessions - 1}/${membershipCard.totalSessions}',
                    ),

                    _buildDetailRow(
                      'Expiration',
                      DateFormat(
                        'dd/MM/yyyy',
                      ).format(membershipCard.expiryDate),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

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
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),

            AppButton(
              text: 'Retour à la liste des cours',
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/courses'));
              },
              type: AppButtonType.outline,
              size: AppButtonSize.large,
              fullWidth: true,
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
