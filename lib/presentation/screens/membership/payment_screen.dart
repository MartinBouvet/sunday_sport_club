import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/membership_card.dart';
import '../../../data/models/payment.dart';
import '../../../domain/services/payment_service.dart';
import '../../providers/auth_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String membershipType;
  final int sessions;
  final String? membershipCardId;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.membershipType,
    required this.sessions,
    this.membershipCardId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs du formulaire
  final _cardNumberController = TextEditingController();
  final _cardHolderNameController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  
  // Variables d'état
  bool _isLoading = false;
  bool _paymentSuccess = false;
  String _selectedPaymentMethod = 'card'; // 'card', 'paypal', etc.
  String? _errorMessage;
  MembershipCard? _createdMembershipCard;
  
  // Service de paiement
  final PaymentService _paymentService = PaymentService();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cardHolderNameController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Traitement du paiement
  Future<void> _processPayment() async {
    // Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Créer la carte d'abonnement après le paiement
      _createdMembershipCard = await _paymentService.createMembershipCardAfterPayment(
        userId: userId,
        type: widget.membershipType,
        totalSessions: widget.sessions,
        price: widget.amount,
      );
      
      if (_createdMembershipCard != null) {
        setState(() {
          _paymentSuccess = true;
        });
      } else {
        throw Exception('Échec de la création de l\'abonnement');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du paiement: ${e.toString()}';
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
      appBar: AppBar(
        title: const Text('Paiement'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Traitement du paiement...')
          : _paymentSuccess
              ? _buildPaymentSuccessScreen()
              : _buildPaymentForm(),
    );
  }

  // Widget pour le formulaire de paiement
  Widget _buildPaymentForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Détails du paiement
            _buildPaymentDetails(),
            
            const SizedBox(height: 24),
            
            // Méthodes de paiement
            _buildPaymentMethods(),
            
            const SizedBox(height: 24),
            
            // Formulaire de carte
            if (_selectedPaymentMethod == 'card') _buildCardForm(),
            
            const SizedBox(height: 24),
            
            // Message d'erreur
            if (_errorMessage != null)
              ErrorDisplay(
                message: _errorMessage!,
                type: ErrorType.general,
                actionLabel: 'Réessayer',
                onAction: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
              ),
            
            const SizedBox(height: 24),
            
            // Bouton de paiement
            AppButton(
              text: 'Payer ${widget.amount.toStringAsFixed(2)}€',
              onPressed: _processPayment,
              type: AppButtonType.primary,
              size: AppButtonSize.large,
              fullWidth: true,
              icon: Icons.payment,
            ),
            
            const SizedBox(height: 16),
            
            // Texte de sécurité
            const Text(
              'Toutes les transactions sont sécurisées et cryptées.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour les détails du paiement
  Widget _buildPaymentDetails() {
    return Card(
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
              'Récapitulatif',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPaymentDetailRow(
              'Type d\'abonnement',
              widget.membershipType == AppConstants.membershipTypeIndividual
                  ? 'Carnet individuel'
                  : 'Carnet collectif',
            ),
            
            _buildPaymentDetailRow(
              'Nombre de séances',
              '${widget.sessions} séances',
            ),
            
            const Divider(height: 24),
            
            _buildPaymentDetailRow(
              'Total à payer',
              '${widget.amount.toStringAsFixed(2)}€',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne de détail de paiement
  Widget _buildPaymentDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.black : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour les méthodes de paiement
  Widget _buildPaymentMethods() {
    return Card(
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
              'Méthode de paiement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Option Carte de crédit
            _buildPaymentMethodOption(
              'card',
              'Carte de crédit',
              Icons.credit_card,
              'Visa, Mastercard, etc.',
            ),
            
            const SizedBox(height: 12),
            
            // Option PayPal (désactivée pour la démo)
            _buildPaymentMethodOption(
              'paypal',
              'PayPal',
              Icons.account_balance_wallet,
              'Paiement via PayPal',
              enabled: false,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une option de méthode de paiement
  Widget _buildPaymentMethodOption(
    String value,
    String title,
    IconData icon,
    String subtitle, {
    bool enabled = true,
  }) {
    return InkWell(
      onTap: enabled
          ? () {
              setState(() {
                _selectedPaymentMethod = value;
              });
            }
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == value && enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.5),
            width: _selectedPaymentMethod == value && enabled ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: enabled
              ? _selectedPaymentMethod == value
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                  : null
              : Colors.grey.withOpacity(0.1),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: _selectedPaymentMethod,
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    }
                  : null,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            Icon(
              icon,
              color: enabled
                  ? _selectedPaymentMethod == value
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[700]
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: enabled ? Colors.grey[700] : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (!enabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Bientôt',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Widget pour le formulaire de carte
  Widget _buildCardForm() {
    return Card(
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
              'Informations de carte',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Numéro de carte
            AppTextField(
              label: 'Numéro de carte',
              controller: _cardNumberController,
              hintText: '1234 5678 9012 3456',
              keyboardType: TextInputType.number,
              prefixIcon: Icons.credit_card,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le numéro de carte';
                }
                // Validation simplifiée pour la démo
                if (value.replaceAll(' ', '').length != 16) {
                  return 'Le numéro de carte doit contenir 16 chiffres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Nom du titulaire
            AppTextField(
              label: 'Nom du titulaire',
              controller: _cardHolderNameController,
              hintText: 'JEAN DUPONT',
              keyboardType: TextInputType.name,
              prefixIcon: Icons.person,
              isRequired: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer le nom du titulaire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Date d'expiration et CVV
            Row(
              children: [
                // Date d'expiration
                Expanded(
                  child: AppTextField(
                    label: 'Date d\'expiration',
                    controller: _expiryDateController,
                    hintText: 'MM/AA',
                    keyboardType: TextInputType.datetime,
                    prefixIcon: Icons.calendar_today,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      // Validation simplifiée pour la démo
                      if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) {
                        return 'Format: MM/AA';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // CVV
                Expanded(
                  child: AppTextField(
                    label: 'CVV',
                    controller: _cvvController,
                    hintText: '123',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.lock,
                    isRequired: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Requis';
                      }
                      if (value.length != 3) {
                        return '3 chiffres';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour l'écran de succès
  Widget _buildPaymentSuccessScreen() {
    return SingleChildScrollView(
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
            'Paiement réussi !',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          Text(
            'Votre paiement de ${widget.amount.toStringAsFixed(2)}€ a été effectué avec succès.',
            style: const TextStyle(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Détails de l'abonnement
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
                    'Détails de votre carnet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSuccessDetailRow(
                    'Type d\'abonnement',
                    widget.membershipType == AppConstants.membershipTypeIndividual
                        ? 'Carnet individuel'
                        : 'Carnet collectif',
                  ),
                  
                  _buildSuccessDetailRow(
                    'Nombre de séances',
                    '${widget.sessions} séances',
                  ),
                  
                  _buildSuccessDetailRow(
                    'Date d\'achat',
                    _createdMembershipCard?.purchaseDate != null
                        ? '${_createdMembershipCard!.purchaseDate.day}/${_createdMembershipCard!.purchaseDate.month}/${_createdMembershipCard!.purchaseDate.year}'
                        : 'Aujourd\'hui',
                  ),
                  
                  _buildSuccessDetailRow(
                    'Date d\'expiration',
                    _createdMembershipCard?.expiryDate != null
                        ? '${_createdMembershipCard!.expiryDate.day}/${_createdMembershipCard!.expiryDate.month}/${_createdMembershipCard!.expiryDate.year}'
                        : '-',
                  ),
                  
                  const Divider(height: 24),
                  
                  _buildSuccessDetailRow(
                    'Montant payé',
                    '${widget.amount.toStringAsFixed(2)}€',
                    isBold: true,
                  ),
                  
                  _buildSuccessDetailRow(
                    'Référence',
                    _createdMembershipCard?.id ?? '-',
                    isBold: false,
                    isSmall: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
          
          // Boutons d'action
          AppButton(
            text: 'Voir mes carnets',
            onPressed: () {
              // Naviguer vers la page des carnets
              Navigator.pop(context);
            },
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.card_membership,
          ),
          const SizedBox(height: 16),
          
          AppButton(
            text: 'Retour à l\'accueil',
            onPressed: () {
              // Naviguer vers la page d'accueil
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            type: AppButtonType.outline,
            size: AppButtonSize.large,
            fullWidth: true,
            icon: Icons.home,
          ),
        ],
      ),
    );
  }

  // Widget pour une ligne de détail dans l'écran de succès
  Widget _buildSuccessDetailRow(
    String label,
    String value, {
    bool isBold = false,
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isSmall ? 12 : 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isSmall ? 12 : 14,
            ),
          ),
        ],
      ),
    );
  }
}