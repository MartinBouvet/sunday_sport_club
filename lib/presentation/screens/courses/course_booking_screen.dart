import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import '../../providers/booking_provider.dart';
import '../../providers/auth_provider.dart';
import 'booking_success_screen.dart';

class CourseBookingScreen extends StatefulWidget {
  final Course course;

  const CourseBookingScreen({Key? key, required this.course}) : super(key: key);

  @override
  State<CourseBookingScreen> createState() => _CourseBookingScreenState();
}

class _CourseBookingScreenState extends State<CourseBookingScreen> {
  bool _isLoading = false;
  MembershipCard? _selectedCard;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserCards();
  }

  Future<void> _loadUserCards() async {
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
        ).fetchUserMembershipCards(userId);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des carnets: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _bookCourse() async {
    if (_selectedCard == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner un carnet';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Vérifier que l'utilisateur est connecté
      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Créer la réservation
      final success = await bookingProvider.createBooking(
        userId: authProvider.currentUser!.id,
        courseId: widget.course.id,
        membershipCardId: _selectedCard!.id,
      );

      if (success && mounted) {
        // Rediriger vers l'écran de succès
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => BookingSuccessScreen(
                  course: widget.course,
                  membershipCard: _selectedCard!,
                ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la réservation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réserver un cours')),
      body:
          _isLoading
              ? const LoadingIndicator(
                center: true,
                message: 'Chargement des carnets...',
              )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Détails du cours
          _buildCourseDetails(),

          const SizedBox(height: 24),

          // Sélection du carnet
          _buildCardSelection(),

          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            ErrorDisplay(
              message: _errorMessage!,
              type: ErrorType.general,
              actionLabel: 'Réessayer',
              onAction: _loadUserCards,
            ),
          ],

          const SizedBox(height: 24),

          // Bouton de réservation
          AppButton(
            text: 'Confirmer la réservation',
            onPressed: _selectedCard != null ? _bookCourse : null,
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.check_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.course.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  'Date',
                  '${widget.course.date.day}/${widget.course.date.month}/${widget.course.date.year}',
                ),
                _buildInfoItem(
                  Icons.access_time,
                  'Horaire',
                  '${widget.course.startTime} - ${widget.course.endTime}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  Icons.group,
                  'Type',
                  widget.course.type == 'individuel'
                      ? 'Individuel'
                      : 'Collectif',
                ),
                _buildInfoItem(
                  Icons.person,
                  'Places',
                  '${widget.course.currentParticipants}/${widget.course.capacity}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCardSelection() {
    final bookingProvider = Provider.of<BookingProvider>(context);
    final cards = bookingProvider.userMembershipCards;

    // Filtrer les cartes utilisables pour ce cours
    final filteredCards =
        cards.where((card) {
          final bool hasRemainingSession = card.remainingSessions > 0;
          final bool notExpired = card.expiryDate.isAfter(DateTime.now());
          final bool validType =
              card.type == 'collectif' || card.type == widget.course.type;
          return hasRemainingSession && notExpired && validType;
        }).toList();

    if (filteredCards.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Carnets disponibles',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.credit_card_off,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun carnet disponible pour ce cours',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Achetez un nouveau carnet pour participer à ce cours',
                    style: TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    text: 'Acheter un carnet',
                    onPressed: () {
                      // Naviguer vers l'écran d'achat de carnet
                      Navigator.pushNamed(context, '/membership');
                    },
                    type: AppButtonType.primary,
                    size: AppButtonSize.medium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez un carnet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez un carnet pour réserver ce cours',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        ...filteredCards.map((card) => _buildCardItem(card)),
      ],
    );
  }

  Widget _buildCardItem(MembershipCard card) {
    final isSelected = _selectedCard?.id == card.id;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCard = card;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border:
                isSelected
                    ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icône de type de carnet
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color:
                        card.type == 'individuel'
                            ? Colors.indigo.withOpacity(0.1)
                            : Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.type == 'individuel' ? Icons.person : Icons.people,
                    color:
                        card.type == 'individuel' ? Colors.indigo : Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                // Informations du carnet
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.type == 'individuel'
                            ? 'Carnet Individuel'
                            : 'Carnet Collectif',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Séances restantes: ${card.remainingSessions}/${card.totalSessions}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Expire le: ${card.expiryDate.day}/${card.expiryDate.month}/${card.expiryDate.year}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // Radio de sélection
                Radio<String>(
                  value: card.id,
                  groupValue: _selectedCard?.id,
                  onChanged: (value) {
                    setState(() {
                      _selectedCard = card;
                    });
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
