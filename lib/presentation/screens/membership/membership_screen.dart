import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/membership_card.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import 'payment_screen.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  
  // Liste des cartes de coaching (à récupérer depuis un provider dans une implémentation réelle)
  List<MembershipCard> _membershipCards = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMembershipCards();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  // Chargement des cartes de coaching
  Future<void> _loadMembershipCards() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Dans une implémentation réelle, on récupèrerait les données depuis le repository
      // Pour cette démo, on simule des données
      await Future.delayed(const Duration(milliseconds: 800));
      
      final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
      if (user != null) {
        // Simuler des cartes de membership
        _membershipCards = _generateMockMembershipCards(user.id);
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des carnets: $e';
        _isLoading = false;
      });
    }
  }
  
  // Génère des cartes de membership fictives pour la démo
  List<MembershipCard> _generateMockMembershipCards(String userId) {
    final now = DateTime.now();
    return [
      MembershipCard(
        id: 'card1',
        userId: userId,
        type: AppConstants.membershipTypeIndividual,
        totalSessions: 10,
        remainingSessions: 5,
        purchaseDate: now.subtract(const Duration(days: 45)),
        expiryDate: now.add(const Duration(days: 90)),
        price: 350.0,
        paymentStatus: 'completed',
      ),
      MembershipCard(
        id: 'card2',
        userId: userId,
        type: AppConstants.membershipTypeCollective,
        totalSessions: 20,
        remainingSessions: 15,
        purchaseDate: now.subtract(const Duration(days: 15)),
        expiryDate: now.add(const Duration(days: 180)),
        price: 280.0,
        paymentStatus: 'completed',
      ),
      // Carte expirée
      MembershipCard(
        id: 'card3',
        userId: userId,
        type: AppConstants.membershipTypeIndividual,
        totalSessions: 10,
        remainingSessions: 0,
        purchaseDate: now.subtract(const Duration(days: 180)),
        expiryDate: now.subtract(const Duration(days: 30)),
        price: 350.0,
        paymentStatus: 'completed',
      ),
    ];
  }
  
  // Acheter un nouveau carnet
  void _purchaseNewCard(String type) {
  // Détermination du montant et du nombre de séances en fonction du type
  double amount;
  int sessions;
  
  if (type == AppConstants.membershipTypeIndividual) {
    amount = 350.0;  // Prix pour un carnet individuel
    sessions = 10;   // 10 séances pour un carnet individuel
  } else {
    amount = 250.0;  // Prix pour un carnet collectif
    sessions = 10;   // 10 séances pour un carnet collectif
  }
  
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentScreen(
        membershipType: type,
        amount: amount,
        sessions: sessions,
      ),
    ),
  ).then((_) => _loadMembershipCards());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes carnets'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Carnets actifs'),
            Tab(text: 'Historique'),
          ],
        ),
      ),
      body: _isLoading 
          ? const LoadingIndicator(center: true, message: 'Chargement des carnets...')
          : _errorMessage != null
              ? ErrorDisplay(
                  message: _errorMessage!,
                  type: ErrorType.network,
                  actionLabel: 'Réessayer',
                  onAction: _loadMembershipCards,
                )
              : Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.currentUser;
                    
                    if (user == null) {
                      return const Center(
                        child: Text('Veuillez vous connecter pour accéder à cette page'),
                      );
                    }
                    
                    // Filtrer les cartes selon l'onglet
                    final now = DateTime.now();
                    final activeCards = _membershipCards.where((card) => 
                      card.remainingSessions > 0 && card.expiryDate.isAfter(now)).toList();
                    
                    final expiredOrEmptyCards = _membershipCards.where((card) => 
                      card.remainingSessions <= 0 || card.expiryDate.isBefore(now)).toList();
                    
                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Onglet Carnets actifs
                        _buildActiveCardsTab(activeCards),
                        
                        // Onglet Historique
                        _buildHistoryTab(expiredOrEmptyCards),
                      ],
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showPurchaseOptions(context);
        },
        label: const Text('Acheter un carnet'),
        icon: const Icon(Icons.add),
      ),
    );
  }
  
  // Construit l'onglet des carnets actifs
  Widget _buildActiveCardsTab(List<MembershipCard> activeCards) {
    if (activeCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.card_membership,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              const Text(
                'Vous n\'avez aucun carnet actif',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Achetez un carnet pour commencer votre parcours sportif',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Acheter un carnet',
                onPressed: () => _showPurchaseOptions(context),
                type: AppButtonType.primary,
                size: AppButtonSize.medium,
                icon: Icons.add_shopping_cart,
              ),
            ],
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadMembershipCards,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activeCards.length,
        itemBuilder: (context, index) {
          final card = activeCards[index];
          return _buildMembershipCard(card, isActive: true);
        },
      ),
    );
  }
  
  // Construit l'onglet historique
  Widget _buildHistoryTab(List<MembershipCard> expiredCards) {
    if (expiredCards.isEmpty) {
      return Center(
        child: Text(
          'Aucun historique disponible',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expiredCards.length,
      itemBuilder: (context, index) {
        final card = expiredCards[index];
        return _buildMembershipCard(card, isActive: false);
      },
    );
  }
  
  // Construit une carte de membership
  Widget _buildMembershipCard(MembershipCard card, {required bool isActive}) {
    final remainingPercentage = card.totalSessions > 0 
        ? card.remainingSessions / card.totalSessions 
        : 0.0;
    
    final isExpired = card.expiryDate.isBefore(DateTime.now());
    
    // Couleur selon le type de coaching
    final Color cardColor = card.type == AppConstants.membershipTypeIndividual
        ? Colors.indigo
        : Colors.teal;
    
    final String cardTitle = card.type == AppConstants.membershipTypeIndividual
        ? 'Carnet Coaching Individuel'
        : 'Carnet Coaching Collectif';
        
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isActive
                ? [cardColor.withOpacity(0.3), cardColor.withOpacity(0.1)]
                : [Colors.grey.shade300, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                      cardTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isActive ? cardColor : Colors.grey[600],
                      ),
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Expiré',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (card.remainingSessions <= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Épuisé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Dates d'achat et d'expiration
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Acheté le',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(card.purchaseDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expire le',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy').format(card.expiryDate),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpired ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Sessions restantes
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sessions restantes',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${card.remainingSessions}/${card.totalSessions}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive ? cardColor : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: remainingPercentage,
                      backgroundColor: Colors.grey[300],
                      color: isActive ? cardColor : Colors.grey,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Prix et actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${card.price.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isActive)
                    AppButton(
                      text: 'Renouveler',
                      onPressed: () => _purchaseNewCard(card.type),
                      type: AppButtonType.outline,
                      size: AppButtonSize.small,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Affiche les options d'achat de carnets
  void _showPurchaseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisissez un type de carnet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Option carnet individuel
            _buildPurchaseOption(
              title: 'Carnet Coaching Individuel',
              description: '10 séances individuelles avec votre coach',
              price: '350 €',
              icon: Icons.person,
              color: Colors.indigo,
              onTap: () {
                Navigator.pop(context);
                _purchaseNewCard(AppConstants.membershipTypeIndividual);
              },
            ),
            
            const SizedBox(height: 16),
            
            // Option carnet collectif
            _buildPurchaseOption(
              title: 'Carnet Coaching Collectif',
              description: '20 séances en groupe avec votre coach',
              price: '280 €',
              icon: Icons.people,
              color: Colors.teal,
              onTap: () {
                Navigator.pop(context);
                _purchaseNewCard(AppConstants.membershipTypeCollective);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  
  // Construit une option d'achat
  Widget _buildPurchaseOption({
    required String title,
    required String description,
    required String price,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}