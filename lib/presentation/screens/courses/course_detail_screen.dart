import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({super.key, required this.courseId});

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = false;
  Course? _course;
  List<MembershipCard> _validCards = [];
  String? _selectedCardId;
  String? _errorMessage;
  bool _bookingSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCourseDetails();
      _loadUserCards();
    });
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      // Récupérer tous les cours pour s'assurer que la liste est à jour
      await bookingProvider.fetchAvailableCourses(
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
      );

      // Trouver le cours dans la liste
      final course = bookingProvider.availableCourses.firstWhere(
        (c) => c.id == widget.courseId,
        orElse: () => throw Exception('Cours non trouvé'),
      );

      setState(() {
        _course = course;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement du cours: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserCards() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser != null) {
        await bookingProvider.fetchUserMembershipCards(
          authProvider.currentUser!.id,
        );

        // Filtrer les cartes valides
        if (_course != null) {
          _filterValidCards(bookingProvider.userMembershipCards, _course!);
        }
      }
    } catch (e) {
      // Gérer l'erreur
      debugPrint('Erreur lors du chargement des cartes: $e');
    }
  }

  void _filterValidCards(List<MembershipCard> allCards, Course course) {
    final now = DateTime.now();
    final validCards =
        allCards.where((card) {
          // Vérifier si la carte a des séances restantes et n'est pas expirée
          final bool hasRemainingSession = card.remainingSessions > 0;
          final bool notExpired = card.expiryDate.isAfter(now);

          // Vérifier que le type de carte correspond au type de cours
          bool validType = true;

          // Si c'est une carte individuelle, elle ne peut être utilisée que pour des cours individuels
          if (card.type == 'individuel' && course.type != 'individuel') {
            validType = false;
          }

          return hasRemainingSession && notExpired && validType;
        }).toList();

    setState(() {
      _validCards = validCards;

      // Présélectionner une carte si disponible
      if (_validCards.isNotEmpty && _selectedCardId == null) {
        _selectedCardId = _validCards.first.id;
      }
    });
  }

  Future<void> _bookCourse() async {
    if (_course == null || _selectedCardId == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une carte d\'abonnement';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final bookingProvider = Provider.of<BookingProvider>(
        context,
        listen: false,
      );

      if (authProvider.currentUser == null) {
        throw Exception('Vous devez être connecté pour réserver un cours');
      }

      final success = await bookingProvider.createBooking(
        userId: authProvider.currentUser!.id,
        courseId: _course!.id,
        membershipCardId: _selectedCardId!,
      );

      if (success) {
        setState(() {
          _bookingSuccess = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              bookingProvider.errorMessage ?? 'Erreur lors de la réservation';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la réservation: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails du cours')),
      body:
          _isLoading
              ? const LoadingIndicator(
                center: true,
                message: 'Chargement des détails...',
              )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null && _course == null) {
      return ErrorDisplay(
        message: _errorMessage!,
        type: ErrorType.general,
        actionLabel: 'Réessayer',
        onAction: _loadCourseDetails,
      );
    }

    if (_course == null) {
      return const Center(child: Text('Détails du cours non disponibles'));
    }

    if (_bookingSuccess) {
      return _buildBookingSuccessContent();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Carte d'information du cours
          _buildCourseInfoCard(),

          const SizedBox(height: 24),

          // Sélection de carte d'abonnement
          _buildMembershipCardSelection(),

          const SizedBox(height: 24),

          // Bouton de réservation
          _buildBookingButton(),

          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCourseInfoCard() {
    if (_course == null) return const SizedBox.shrink();

    final dateFormat = DateFormat('dd MMMM yyyy', 'fr_FR');
    final isCourseAvailable = _course!.currentParticipants < _course!.capacity;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre du cours et type
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _course!.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              _course!.type == 'individuel'
                                  ? Colors.indigo.withOpacity(0.1)
                                  : Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                _course!.type == 'individuel'
                                    ? Colors.indigo.withOpacity(0.3)
                                    : Colors.teal.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _course!.type == 'individuel'
                              ? 'Cours individuel'
                              : 'Cours collectif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color:
                                _course!.type == 'individuel'
                                    ? Colors.indigo
                                    : Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de disponibilité
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isCourseAvailable ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isCourseAvailable ? 'Disponible' : 'Complet',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              _course!.description,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Date et heure
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(_course!.date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Horaire
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  '${_course!.startTime} - ${_course!.endTime}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Capacité
            Row(
              children: [
                Icon(Icons.people, size: 18, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  'Places: ${_course!.currentParticipants}/${_course!.capacity}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembershipCardSelection() {
    // Si aucune carte valide n'est disponible
    if (_validCards.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.orange[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cartes d\'abonnement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vous n\'avez pas de carte d\'abonnement valide pour ce type de cours.',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              AppButton(
                text: 'Acheter un carnet',
                onPressed: () {
                  // Navigation vers la page d'achat de carnet
                  Navigator.pushNamed(context, '/membership');
                },
                type: AppButtonType.outline,
                icon: Icons.add_shopping_cart,
                fullWidth: true,
              ),
            ],
          ),
        ),
      );
    }

    // Liste des cartes disponibles
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisir une carte d\'abonnement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Liste des cartes sous forme de radio buttons
            ...List.generate(_validCards.length, (index) {
              final card = _validCards[index];
              return _buildCardOption(card);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCardOption(MembershipCard card) {
    final isSelected = _selectedCardId == card.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        title: Text(
          card.type == 'individuel'
              ? 'Carnet Coaching Individuel'
              : 'Carnet Coaching Collectif',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Séances restantes: ${card.remainingSessions}/${card.totalSessions}',
        ),
        value: card.id,
        groupValue: _selectedCardId,
        onChanged: (value) {
          setState(() {
            _selectedCardId = value;
          });
        },
        activeColor: Theme.of(context).colorScheme.primary,
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildBookingButton() {
    // Si le cours est complet, désactiver le bouton
    final isCourseFull =
        _course != null && _course!.currentParticipants >= _course!.capacity;

    // Si aucune carte valide, désactiver le bouton
    final hasValidCard = _validCards.isNotEmpty && _selectedCardId != null;

    final canBook = !isCourseFull && hasValidCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          text:
              isCourseFull
                  ? 'Cours complet'
                  : hasValidCard
                  ? 'Confirmer la réservation'
                  : 'Acheter un carnet pour réserver',
          onPressed: canBook ? _bookCourse : null,
          type: AppButtonType.primary,
          size: AppButtonSize.large,
          icon: Icons.check_circle,
        ),
        if (isCourseFull) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Ce cours est complet, veuillez essayer un autre horaire.',
              style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ] else if (!hasValidCard) ...[
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Vous devez avoir une carte d\'abonnement valide pour réserver ce cours.',
              style: TextStyle(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  // Dans CourseDetailScreen, modifie _buildBookingSuccessContent():

  Widget _buildBookingSuccessContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ...reste du code inchangé...
            AppButton(
              text: 'Voir mes réservations',
              onPressed: () async {
                // Rafraîchir les données
                final bookingProvider = Provider.of<BookingProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                if (authProvider.currentUser != null) {
                  await bookingProvider.fetchUserBookings(
                    authProvider.currentUser!.id,
                  );
                }

                // Revenir à l'écran précédent
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              type: AppButtonType.primary,
              size: AppButtonSize.large,
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 16),
            AppButton(
              text: 'Retour à la liste des cours',
              onPressed: () async {
                // Rafraîchir les données
                final bookingProvider = Provider.of<BookingProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );

                if (authProvider.currentUser != null) {
                  await bookingProvider.fetchAvailableCourses(
                    startDate: DateTime.now(),
                    endDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  await bookingProvider.fetchUserBookings(
                    authProvider.currentUser!.id,
                  );
                }

                // Revenir à l'écran précédent
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              type: AppButtonType.outline,
              size: AppButtonSize.large,
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }
}
