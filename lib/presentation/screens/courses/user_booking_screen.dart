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
import 'course_list_screen.dart';

class UserBookingsScreen extends StatefulWidget {
  const UserBookingsScreen({Key? key}) : super(key: key);

  @override
  State<UserBookingsScreen> createState() => _UserBookingsScreenState();
}

class _UserBookingsScreenState extends State<UserBookingsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId != null) {
        await Provider.of<BookingProvider>(
          context,
          listen: false,
        ).fetchUserBookings(userId);
      }
    } catch (e) {
      // L'erreur est gérée par le provider
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'À venir'), Tab(text: 'Passées')],
        ),
      ),
      body:
          _isLoading
              ? const LoadingIndicator(
                center: true,
                message: 'Chargement des réservations...',
              )
              : Consumer<BookingProvider>(
                builder: (context, bookingProvider, _) {
                  if (bookingProvider.hasError) {
                    return ErrorDisplay(
                      message: bookingProvider.errorMessage!,
                      type: ErrorType.network,
                      actionLabel: 'Réessayer',
                      onAction: _loadBookings,
                    );
                  }

                  final now = DateTime.now();

                  // Séparer les réservations à venir et passées
                  final upcomingBookings =
                      bookingProvider.userBookings.where((booking) {
                        // Trouver le cours associé à la réservation
                        final course = bookingProvider.availableCourses
                            .firstWhere(
                              (course) => course.id == booking.courseId,
                              orElse:
                                  () => Course(
                                    id: '',
                                    title: 'Cours inconnu',
                                    description: '',
                                    type: '',
                                    date: DateTime.now(),
                                    startTime: '',
                                    endTime: '',
                                    capacity: 0,
                                    currentParticipants: 0,
                                    status: '',
                                    coachId: '',
                                  ),
                            );

                        return booking.status != 'cancelled' &&
                            course.date.isAfter(now);
                      }).toList();

                  final pastBookings =
                      bookingProvider.userBookings.where((booking) {
                        final course = bookingProvider.availableCourses
                            .firstWhere(
                              (course) => course.id == booking.courseId,
                              orElse:
                                  () => Course(
                                    id: '',
                                    title: 'Cours inconnu',
                                    description: '',
                                    type: '',
                                    date: DateTime.now(),
                                    startTime: '',
                                    endTime: '',
                                    capacity: 0,
                                    currentParticipants: 0,
                                    status: '',
                                    coachId: '',
                                  ),
                            );

                        return booking.status == 'cancelled' ||
                            course.date.isBefore(now);
                      }).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Onglet des réservations à venir
                      _buildBookingsList(
                        upcomingBookings,
                        bookingProvider,
                        true,
                        'Vous n\'avez aucune réservation à venir',
                      ),

                      // Onglet des réservations passées
                      _buildBookingsList(
                        pastBookings,
                        bookingProvider,
                        false,
                        'Vous n\'avez aucune réservation passée',
                      ),
                    ],
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CourseListScreen()),
          );
        },
        label: const Text('Réserver un cours'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBookingsList(
    List<Booking> bookings,
    BookingProvider provider,
    bool showCancelButton,
    String emptyMessage,
  ) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Voir les cours disponibles',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CourseListScreen(),
                  ),
                );
              },
              type: AppButtonType.primary,
              size: AppButtonSize.medium,
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

          // Trouver le cours associé à la réservation
          final course = provider.availableCourses.firstWhere(
            (course) => course.id == booking.courseId,
            orElse:
                () => Course(
                  id: '',
                  title: 'Cours inconnu',
                  description: '',
                  type: '',
                  date: DateTime.now(),
                  startTime: '',
                  endTime: '',
                  capacity: 0,
                  currentParticipants: 0,
                  status: '',
                  coachId: '',
                ),
          );

          return _buildBookingCard(booking, course, provider, showCancelButton);
        },
      ),
    );
  }

  Widget _buildBookingCard(
    Booking booking,
    Course course,
    BookingProvider provider,
    bool showCancelButton,
  ) {
    final bool isCancelled = booking.status == 'cancelled';
    final bool isCompleted = booking.status == 'completed';

    Color statusColor;
    String statusText;

    if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Annulé';
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Terminé';
    } else {
      statusColor = Colors.blue;
      statusText = 'Confirmé';
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Text(
              course.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            // Informations sur le cours
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().format(course.date),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      '${course.startTime} - ${course.endTime}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    course.type == 'individuel' ? 'Individuel' : 'Collectif',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          course.type == 'individuel'
                              ? Colors.indigo
                              : Colors.teal,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Réservé le ${DateFormat.yMd().format(booking.bookingDate)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),

            // Bouton d'annulation (seulement pour les réservations à venir)
            if (showCancelButton && !isCancelled && !isCompleted) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _showCancellationDialog(booking, provider),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Annuler'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showCancellationDialog(Booking booking, BookingProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Annuler la réservation'),
            content: const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation ? '
              'Si l\'annulation est effectuée au moins 24h avant le cours, '
              'votre séance sera recréditée.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Non'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    final success = await provider.cancelBooking(booking.id);
                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Réservation annulée avec succès'),
                          backgroundColor: Colors.green,
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
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                    _loadBookings();
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
