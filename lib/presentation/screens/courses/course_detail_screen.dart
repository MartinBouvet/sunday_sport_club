import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import 'booking_success_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;

  const CourseDetailScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = false;
  String? _selectedCardId;

  @override
  void initState() {
    super.initState();
    _loadMembershipCards();
  }

  Future<void> _loadMembershipCards() async {
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
        await bookingProvider.fetchUserMembershipCards(
          authProvider.currentUser!.id,
        );
      }
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
      appBar: AppBar(title: const Text('Détails du cours')),
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
                  message: 'Chargement des informations...',
                );
              }

              if (bookingProvider.hasError) {
                return ErrorDisplay(
                  message: bookingProvider.errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadMembershipCards,
                );
              }

              final userCards =
                  bookingProvider.userMembershipCards.where((card) {
                    // Filtrer les cartes valides pour ce cours
                    final bool hasRemainingSessions =
                        card.remainingSessions > 0;
                    final bool notExpired = card.expiryDate.isAfter(
                      DateTime.now(),
                    );
                    final bool validType =
                        card.type == 'collectif' ||
                        card.type == widget.course.type;

                    return hasRemainingSessions && notExpired && validType;
                  }).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte d'informations du cours
                    _buildCourseCard(),

                    const SizedBox(height: 24),

                    // Sélection de la carte de membre
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sélectionner un carnet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            if (userCards.isEmpty) ...[
                              const Center(
                                child: Text(
                                  'Vous n\'avez pas de carnet valide pour ce cours',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AppButton(
                                text: 'Acheter un carnet',
                                onPressed: () {
                                  // Naviguer vers l'écran d'achat de carnet
                                  Navigator.of(context).pop();
                                },
                                type: AppButtonType.primary,
                                size: AppButtonSize.medium,
                                fullWidth: true,
                                icon: Icons.card_membership,
                              ),
                            ] else ...[
                              ...userCards.map(
                                (card) => _buildCardOption(card),
                              ),
                              const SizedBox(height: 24),
                              AppButton(
                                text: 'Confirmer la réservation',
                                onPressed:
                                    userCards.isEmpty || _selectedCardId == null
                                        ? null
                                        : () => _confirmBooking(
                                          user.id,
                                          widget.course.id,
                                          _selectedCardId!,
                                          bookingProvider,
                                        ),
                                type: AppButtonType.primary,
                                size: AppButtonSize.large,
                                fullWidth: true,
                                icon: Icons.check_circle,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCourseCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du cours
            Text(
              widget.course.title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              widget.course.description,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),

            // Détails du cours
            _buildDetailItem(
              icon: Icons.class_,
              label: 'Type',
              value:
                  widget.course.type == 'individuel'
                      ? 'Cours individuel'
                      : 'Cours collectif',
            ),

            _buildDetailItem(
              icon: Icons.event,
              label: 'Date',
              value: DateFormat('dd/MM/yyyy').format(widget.course.date),
            ),

            _buildDetailItem(
              icon: Icons.access_time,
              label: 'Horaire',
              value: '${widget.course.startTime} - ${widget.course.endTime}',
            ),

            _buildDetailItem(
              icon: Icons.people,
              label: 'Places',
              value:
                  '${widget.course.currentParticipants}/${widget.course.capacity}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCardOption(MembershipCard card) {
    final bool isSelected = _selectedCardId == card.id;
    final Color cardColor =
        card.type == 'individuel' ? Colors.indigo : Colors.teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCardId = card.id;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? cardColor : Colors.grey.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? cardColor.withOpacity(0.1) : null,
          ),
          child: Row(
            children: [
              Radio<String>(
                value: card.id,
                groupValue: _selectedCardId,
                onChanged: (String? value) {
                  setState(() {
                    _selectedCardId = value;
                  });
                },
                activeColor: cardColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.type == 'individuel'
                          ? 'Carnet individuel'
                          : 'Carnet collectif',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Séances restantes: ${card.remainingSessions}/${card.totalSessions}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Text(
                'Expire le ${DateFormat('dd/MM/yyyy').format(card.expiryDate)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
    String userId,
    String courseId,
    String membershipCardId,
    BookingProvider bookingProvider,
  ) async {
    print(
      "Confirming booking for course: $courseId with card: $membershipCardId",
    );
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await bookingProvider.createBooking(
        userId: userId,
        courseId: courseId,
        membershipCardId: membershipCardId,
      );

      if (success && mounted) {
        // Récupérer la carte mise à jour
        final selectedCard = bookingProvider.userMembershipCards.firstWhere(
          (card) => card.id == membershipCardId,
        );

        // Naviguer vers l'écran de succès
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => BookingSuccessScreen(
                  course: widget.course,
                  membershipCard: selectedCard,
                ),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
