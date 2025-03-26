import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/course.dart';
import '../../../data/models/membership_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';

class BookingScreen extends StatefulWidget {
  final String courseId;
  final List<MembershipCard> availableCards;

  const BookingScreen({
    Key? key,
    required this.courseId,
    required this.availableCards,
  }) : super(key: key);

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  bool _isLoading = true;
  bool _isBooking = false;
  Course? _course;
  String? _errorMessage;
  MembershipCard? _selectedCard;
  bool _acceptTerms = false;

  @override
  void initState() {
    super.initState();
    _loadCourseDetails();
    // Sélectionner automatiquement la première carte si disponible
    if (widget.availableCards.isNotEmpty) {
      _selectedCard = widget.availableCards.first;
    }
  }

  Future<void> _loadCourseDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      
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

  Future<void> _bookCourse() async {
    if (_selectedCard == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner un carnet';
      });
      return;
    }

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Veuillez accepter les conditions';
      });
      return;
    }

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      final success = await bookingProvider.createBooking(
        userId: authProvider.currentUser!.id,
        courseId: widget.courseId,
        membershipCardId: _selectedCard!.id,
      );
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Réservation effectuée avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Retour à l'écran précédent
          Navigator.pop(context);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la réservation: ${e.toString()}';
        _isBooking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservation de cours'),
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement des informations...')
          : _errorMessage != null && _course == null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadCourseDetails,
                )
              : _buildBookingForm(),
    );
  }

  Widget _buildBookingForm() {
    if (_course == null) {
      return const Center(
        child: Text('Cours introuvable'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé du cours
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
                    'Récapitulatif du cours',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    _course!.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
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
                    'Places: ${_course!.currentParticipants}/${_course!.capacity}',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Sélection du carnet
          const Text(
            'Choisir un carnet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          if (widget.availableCards.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: const Text(
                'Vous n\'avez pas de carnet valide pour ce type de cours',
                style: TextStyle(color: Colors.orange),
              ),
            )
          else
            Column(
              children: widget.availableCards.map((card) => _buildCardOption(card)).toList(),
            ),
          
          const SizedBox(height: 24),
          
          // Conditions de réservation
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
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
            ),
          
          Row(
            children: [
              Checkbox(
                value: _acceptTerms,
                onChanged: (value) {
                  setState(() {
                    _acceptTerms = value ?? false;
                  });
                },
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _acceptTerms = !_acceptTerms;
                    });
                  },
                  child: const Text(
                    'J\'accepte les conditions de réservation et d\'annulation',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Vous pouvez annuler jusqu\'à 24h avant le cours sans perdre votre séance.',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.grey[600],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton de réservation
          AppButton(
            text: 'Confirmer la réservation',
            onPressed: _isBooking ? null : _bookCourse,
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.check_circle,
            isLoading: _isBooking,
          ),
        ],
      ),
    );
  }

  Widget _buildCardOption(MembershipCard card) {
    final isSelected = _selectedCard?.id == card.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCard = card;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Radio<String>(
                value: card.id,
                groupValue: _selectedCard?.id,
                onChanged: (value) {
                  setState(() {
                    _selectedCard = card;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.type == 'individuel' ? 'Carnet individuel' : 'Carnet collectif',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Séances restantes: ${card.remainingSessions}/${card.totalSessions}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      'Expire le: ${DateFormat('dd/MM/yyyy').format(card.expiryDate)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}