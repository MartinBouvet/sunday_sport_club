import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import 'booking_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;

  const CourseDetailScreen({Key? key, required this.courseId})
    : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  bool _isLoading = true;
  Course? _course;
  String? _errorMessage;
  bool _userHasValidCard = false;
  List<MembershipCard> _availableCards = [];

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Rechercher le cours parmi les cours disponibles
      if (bookingProvider.availableCourses.isEmpty) {
        await bookingProvider.fetchAvailableCourses(
          startDate: DateTime.now(),
          endDate: DateTime.now().add(const Duration(days: 90)),
        );
      }

      final coursesList = bookingProvider.availableCourses;
      _course = coursesList.firstWhere(
        (course) => course.id == widget.courseId,
        orElse: () => throw Exception('Cours introuvable'),
      );

      // Vérifier si l'utilisateur a une carte d'abonnement valide pour ce type de cours
      if (authProvider.currentUser != null) {
        await bookingProvider.fetchUserMembershipCards(
          authProvider.currentUser!.id,
        );

        // Filtrer les cartes valides pour ce type de cours
        final now = DateTime.now();
        _availableCards =
            bookingProvider.userMembershipCards.where((card) {
              // Une carte est valide si elle a des séances restantes, n'est pas expirée
              // et est du bon type (individuel ou collectif)
              final bool hasRemainingSession = card.remainingSessions > 0;
              final bool notExpired = card.expiryDate.isAfter(now);
              final bool correctType =
                  _course!.type == AppConstants.membershipTypeCollective ||
                  (card.type == _course!.type);

              return hasRemainingSession && notExpired && correctType;
            }).toList();

        _userHasValidCard = _availableCards.isNotEmpty;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
                message: 'Chargement des détails du cours...',
              )
              : _errorMessage != null
              ? ErrorDisplay(
                message: _errorMessage!,
                type: ErrorType.network,
                actionLabel: 'Réessayer',
                onAction: _loadCourseDetails,
              )
              : _buildCourseDetails(),
    );
  }

  Widget _buildCourseDetails() {
    if (_course == null) {
      return const Center(child: Text('Cours introuvable'));
    }

    final bool isIndividual =
        _course!.type == AppConstants.membershipTypeIndividual;
    final Color themeColor = isIndividual ? Colors.indigo : Colors.teal;
    final bool isFull = _course!.currentParticipants >= _course!.capacity;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec image ou icône
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Center(
              child: Icon(
                isIndividual ? Icons.person : Icons.group,
                size: 80,
                color: themeColor.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Badge de type de cours
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: themeColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isIndividual ? Icons.person : Icons.group,
                  size: 16,
                  color: themeColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isIndividual ? 'Cours individuel' : 'Cours collectif',
                  style: TextStyle(
                    color: themeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Titre et infos principales
          Text(
            _course!.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.person, 'Coach: ${_getCoachName()}'),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.calendar_today,
            'Date: ${DateFormat('dd/MM/yyyy').format(_course!.date)}',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.access_time,
            'Horaire: ${_course!.startTime} - ${_course!.endTime}',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            Icons.people,
            'Participants: ${_course!.currentParticipants}/${_course!.capacity}',
            isFull ? Colors.red : null,
          ),

          const SizedBox(height: 24),

          // Description détaillée
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(_course!.description, style: const TextStyle(fontSize: 16)),

          const SizedBox(height: 32),

          // Indication pour la réservation
          if (isFull) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Cours complet',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Il n\'y a plus de places disponibles pour ce cours.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_userHasValidCard) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Pas de carnet valide',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Vous n\'avez pas de carnet valide pour réserver ce cours.',
                          style: TextStyle(color: Colors.orange),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Bouton de réservation
          AppButton(
            text: 'Réserver ce cours',
            onPressed:
                (!isFull && _userHasValidCard)
                    ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => BookingScreen(
                                courseId: _course!.id,
                                availableCards: _availableCards,
                              ),
                        ),
                      ).then((_) => _loadCourseDetails());
                    }
                    : null,
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.event_available,
          ),

          if (!_userHasValidCard)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: AppButton(
                text: 'Acheter un carnet',
                onPressed: () {
                  // Naviguer vers l'écran d'achat de carnet
                },
                type: AppButtonType.outline,
                size: AppButtonSize.medium,
                fullWidth: true,
                icon: Icons.card_membership,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, [Color? color]) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 14, color: color ?? Colors.grey[600]),
        ),
      ],
    );
  }

  String _getCoachName() {
    // Dans une implémentation réelle, on récupérerait le nom du coach via son ID
    return "Laurent Dubois";
  }
}
