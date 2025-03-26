import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/daily_challenge.dart';
import '../../../data/models/user_challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../providers/auth_provider.dart';

class ChallengeValidationScreen extends StatefulWidget {
  final String challengeId;
  final String? userChallengeId;

  const ChallengeValidationScreen({
    super.key,
    required this.challengeId,
    this.userChallengeId,
  });

  @override
  State<ChallengeValidationScreen> createState() => _ChallengeValidationScreenState();
}

class _ChallengeValidationScreenState extends State<ChallengeValidationScreen> {
  bool _isLoading = false;
  DailyChallenge? _challenge;
  UserChallenge? _userChallenge;
  bool _isValidating = false;

  // Form controllers
  final _photoController = TextEditingController();
  final _commentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  // Photo selection
  bool _photoSelected = false;

  @override
  void initState() {
    super.initState();
    _loadChallengeDetails();
  }

  @override
  void dispose() {
    _photoController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadChallengeDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
      
      // Get challenge details
      final challenge = await challengeProvider.getChallenge(widget.challengeId);
      setState(() {
        _challenge = challenge;
      });
      
      // Get user challenge if exists
      if (widget.userChallengeId != null) {
        final userChallenge = challengeProvider.userChallenges
            .firstWhere((uc) => uc.id == widget.userChallengeId);
        setState(() {
          _userChallenge = userChallenge;
        });
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

  Future<void> _validateChallenge() async {
    // Form validation
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // In a real app, validate that photo is selected
    if (!_photoSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une photo comme preuve'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    
    if (authProvider.currentUser == null || _challenge == null) return;
    
    setState(() {
      _isValidating = true;
    });
    
    try {
      // In a real app, this would upload the photo and submit validation
      // Here we'll just simulate validation success
      
      // Add short delay to simulate processing
      await Future.delayed(const Duration(seconds: 1));
      
      // Complete the challenge
      final success = await challengeProvider.completeChallenge(
        _challenge!.id,
        authProvider.currentUser!.id,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation soumise! Défi complété (+${_challenge!.experiencePoints} XP)'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Pop back to the challenges screen
        Navigator.of(context).pop();
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
          _isValidating = false;
        });
      }
    }
  }

  void _selectPhoto() {
    // In a real app, this would open the camera or gallery
    // Here we'll just simulate photo selection
    setState(() {
      _photoSelected = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo sélectionnée avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du défi'),
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement du défi...')
          : _challenge == null
              ? ErrorDisplay(
                  message: 'Impossible de charger les détails du défi',
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadChallengeDetails,
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Challenge info card
                        _buildChallengeCard(),
                        
                        const SizedBox(height: 24),
                        
                        // Validation section
                        _buildValidationSection(),
                        
                        const SizedBox(height: 32),
                        
                        // Submit button
                        AppButton(
                          text: 'Soumettre ma validation',
                          onPressed: _validateChallenge,
                          type: AppButtonType.primary,
                          size: AppButtonSize.large,
                          fullWidth: true,
                          icon: Icons.check_circle,
                          isLoading: _isValidating,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildChallengeCard() {
    if (_challenge == null) return const SizedBox.shrink();
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _challenge!.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _challenge!.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${_challenge!.experiencePoints} XP',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(_challenge!.difficulty).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getDifficultyIcon(_challenge!.difficulty),
                        color: _getDifficultyColor(_challenge!.difficulty),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _challenge!.difficulty,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: _getDifficultyColor(_challenge!.difficulty),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidationSection() {
    return Card(
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
              'Validation du défi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pour valider ce défi, veuillez fournir une preuve de réalisation ainsi qu\'un commentaire.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            
            // Photo upload section
            const Text(
              'Photo de validation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            _buildPhotoUploadSection(),
            const SizedBox(height: 24),
            
            // Comment section
            const Text(
              'Commentaire',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Décrivez comment vous avez réalisé ce défi...',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez ajouter un commentaire';
                }
                if (value.length < 10) {
                  return 'Le commentaire doit contenir au moins 10 caractères';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUploadSection() {
    return GestureDetector(
      onTap: _selectPhoto,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _photoSelected ? Colors.green : Colors.grey[400]!,
            width: 2,
          ),
        ),
        child: _photoSelected
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Mock image
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    margin: const EdgeInsets.all(2),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.blue[800],
                      ),
                    ),
                  ),
                  
                  // Checkmark overlay
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prenez une photo qui montre que vous avez complété le défi',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'intermédiaire':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  IconData _getDifficultyIcon(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Icons.trip_origin;
      case 'intermédiaire':
        return Icons.copyright;
      case 'difficile':
        return Icons.change_history;
      default:
        return Icons.copyright;
    }
  }
}