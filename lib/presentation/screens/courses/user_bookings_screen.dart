import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/course.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({super.key});

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (authProvider.currentUser != null) {
        await bookingProvider.fetchUserBookings(authProvider.currentUser!.id);
      }
    } catch (e) {
      // Handled by provider
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
      appBar: AppBar(title: const Text('Mes réservations')),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Veuillez vous connecter pour accéder à cette page'),
            );
          }

          return Consumer<BookingProvider>(
            builder: (context, bookingProvider, _) {
              if (_isLoading || bookingProvider.isLoading) {
                return const LoadingIndicator(
                  center: true,
                  message: 'Chargement des réservations...',
                );
              }

              if (bookingProvider.hasError) {
                return ErrorDisplay(
                  message: bookingProvider.errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadBookings,
                );
              }

              final bookings = bookingProvider.userBookings;

              if (bookings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Vous n\'avez aucune réservation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Réservez un cours pour commencer votre entraînement',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'Voir les cours disponibles',
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        type: AppButtonType.primary,
                        size: AppButtonSize.medium,
                        icon: Icons.event_available,
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadBookings,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return _buildBookingCard(context, booking, bookingProvider);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    BookingProvider bookingProvider,
  ) {
    // Pour cette démo, on simule un objet Course
    final Course course = Course(
      id: booking.courseId,
      title: 'Cours de MMA',
      description: 'Description du cours',
      type: 'individuel',
      date: booking.bookingDate,
      startTime: '14:00',
      endTime: '15:00',
      capacity: 1,
      currentParticipants: 1,
      status: 'available',
      coachId: 'coach-1',
    );

    final bool isUpcoming = course.date.isAfter(DateTime.now());
    final bool isCancelled = booking.status == 'cancelled';

    // Couleur selon le statut
    Color statusColor;
    String statusText;

    if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Annulé';
    } else if (booking.status == 'completed') {
      statusColor = Colors.green;
      statusText = 'Terminé';
    } else {
      statusColor = Colors.blue;
      statusText = 'Confirmé';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du cours et statut
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Type de cours
            Text(
              'Type: ${course.type}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),

            // Date et heure
            Row(
              children: [
                Icon(Icons.event, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(course.date),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '${course.startTime} - ${course.endTime}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Boutons d'action (uniquement pour les cours à venir et non annulés)
            if (isUpcoming && !isCancelled)
              AppButton(
                text: 'Annuler la réservation',
                onPressed:
                    () => _cancelBooking(context, booking.id, bookingProvider),
                type: AppButtonType.outline,
                size: AppButtonSize.small,
                fullWidth: true,
                icon: Icons.cancel,
              ),
          ],
        ),
      ),
    );
  }

  void _cancelBooking(
    BuildContext context,
    String bookingId,
    BookingProvider bookingProvider,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Annuler la réservation'),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Non'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await bookingProvider.cancelBooking(bookingId);

                  if (bookingProvider.hasSuccess && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(bookingProvider.successMessage!),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (bookingProvider.hasError && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(bookingProvider.errorMessage!),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Oui, annuler'),
              ),
            ],
          ),
    );
  }
}
