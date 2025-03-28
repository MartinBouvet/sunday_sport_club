import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';
import '../../../data/datasources/supabase/supabase_payment_datasource.dart';

/// Écran de gestion des paiements pour l'administrateur
///
/// Permet à l'administrateur de visualiser, filtrer et gérer tous les paiements
/// effectués par les membres du club.
class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  State<PaymentManagementScreen> createState() => _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> with SingleTickerProviderStateMixin {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final UserRepository _userRepository = UserRepository();
  
  bool _isLoading = false;
  List<Payment> _allPayments = [];
  List<Payment> _filteredPayments = [];
  Map<String, User?> _usersCache = {};
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedStatus = 'all'; // 'all', 'completed', 'pending', 'failed', 'refunded'
  String _selectedType = 'all'; // 'all', 'membership', 'course'
  
  // Pour la vue détaillée
  Payment? _selectedPayment;
  
  // Pour le tri
  String _sortBy = 'date'; // 'date', 'amount', 'user'
  bool _sortAscending = false;
  
  // Pour la pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _totalPages = 1;
  
  late TabController _tabController;
  
  // Pour les statistiques
  Map<String, dynamic> _paymentStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Définir la plage de dates par défaut (dernier mois)
    final now = DateTime.now();
    _endDate = now;
    _startDate = DateTime(now.year, now.month - 1, now.day);
    
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0: // Tous
            _selectedStatus = 'all';
            break;
          case 1: // Complétés
            _selectedStatus = 'completed';
            break;
          case 2: // En attente
            _selectedStatus = 'pending';
            break;
        }
      });
      _filterPayments();
    }
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger tous les paiements depuis la base de données
      final payments = await _paymentRepository.getAllPayments();
      
      // Charger les statistiques
      final paymentStats = await _loadPaymentStatistics();
      
      setState(() {
        _allPayments = payments;
        _paymentStats = paymentStats;
        _filterPayments();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des paiements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<Map<String, dynamic>> _loadPaymentStatistics() async {
    try {
      // Utiliser le datasource directement pour obtenir des statistiques complètes
      final supabasePaymentDatasource = SupabasePaymentDatasource();
      return await supabasePaymentDatasource.getPaymentStatistics();
    } catch (e) {
      // En cas d'erreur, retourner des statistiques vides
      return {
        'current_month_total': 0.0,
        'last_month_total': 0.0,
        'month_over_month_change': 0.0,
        'membership_total': 0.0,
        'individual_course_total': 0.0,
      };
    }
  }

  void _filterPayments() {
    List<Payment> filtered = List.from(_allPayments);
    
    // Filtrer par statut
    if (_selectedStatus != 'all') {
      filtered = filtered.where((payment) => payment.status == _selectedStatus).toList();
    }
    
    // Filtrer par type
    if (_selectedType != 'all') {
      filtered = filtered.where((payment) => payment.type == _selectedType).toList();
    }
    
    // Filtrer par date
    if (_startDate != null) {
      filtered = filtered.where((payment) => payment.date.isAfter(_startDate!)).toList();
    }
    
    if (_endDate != null) {
      // Ajouter un jour pour inclure les paiements effectués le jour de fin
      final endDatePlusOne = _endDate!.add(const Duration(days: 1));
      filtered = filtered.where((payment) => payment.date.isBefore(endDatePlusOne)).toList();
    }
    
    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((payment) {
        final userId = payment.userId.toLowerCase();
        final query = _searchQuery.toLowerCase();
        
        // Si l'utilisateur est déjà dans le cache, utiliser son nom pour la recherche
        if (_usersCache.containsKey(userId) && _usersCache[userId] != null) {
          final user = _usersCache[userId]!;
          final userName = '${user.firstName} ${user.lastName}'.toLowerCase();
          if (userName.contains(query)) {
            return true;
          }
        }
        
        // Rechercher aussi par ID de transaction ou ID de paiement
        return payment.id.toLowerCase().contains(query) || 
               (payment.transactionId?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
    
    // Trier les résultats
    _sortFilteredPayments(filtered);
    
    // Mettre à jour les paiements filtrés et calculer le nombre total de pages
    setState(() {
      _filteredPayments = filtered;
      _totalPages = (filtered.length / _itemsPerPage).ceil();
      if (_currentPage > _totalPages && _totalPages > 0) {
        _currentPage = _totalPages;
      } else if (_totalPages == 0) {
        _currentPage = 1;
      }
    });
  }
  
  void _sortFilteredPayments(List<Payment> payments) {
    switch (_sortBy) {
      case 'date':
        payments.sort((a, b) => _sortAscending 
          ? a.date.compareTo(b.date) 
          : b.date.compareTo(a.date));
        break;
      case 'amount':
        payments.sort((a, b) => _sortAscending 
          ? a.amount.compareTo(b.amount) 
          : b.amount.compareTo(a.amount));
        break;
      case 'user':
        // Tri par nom d'utilisateur - nécessite de charger tous les utilisateurs au préalable
        // Ici, on trie simplement par userId comme alternative
        payments.sort((a, b) => _sortAscending 
          ? a.userId.compareTo(b.userId) 
          : b.userId.compareTo(a.userId));
        break;
    }
  }
  
  Future<User?> _getUserById(String userId) async {
    // Vérifier si l'utilisateur est déjà dans le cache
    if (_usersCache.containsKey(userId)) {
      return _usersCache[userId];
    }
    
    // Sinon, charger l'utilisateur depuis la base de données
    try {
      final user = await _userRepository.getUser(userId);
      setState(() {
        _usersCache[userId] = user;
      });
      return user;
    } catch (e) {
      // En cas d'erreur, ajouter null au cache pour éviter de réessayer
      setState(() {
        _usersCache[userId] = null;
      });
      return null;
    }
  }
  
  List<Payment> _getCurrentPageItems() {
    if (_filteredPayments.isEmpty) {
      return [];
    }
    
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage > _filteredPayments.length 
        ? _filteredPayments.length 
        : startIndex + _itemsPerPage;
    
    if (startIndex >= _filteredPayments.length) {
      return [];
    }
    
    return _filteredPayments.sublist(startIndex, endIndex);
  }
  
  void _updatePaymentStatus(String paymentId, String newStatus) async {
    try {
      await _paymentRepository.updatePaymentStatus(paymentId, newStatus);
      
      // Mettre à jour localement
      setState(() {
        final index = _allPayments.indexWhere((p) => p.id == paymentId);
        if (index != -1) {
          _allPayments[index] = _allPayments[index].copyWith(status: newStatus);
        }
        _filterPayments();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut du paiement mis à jour avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la mise à jour du statut: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showPaymentDetails(Payment payment) {
    setState(() {
      _selectedPayment = payment;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Détails du paiement'),
            content: FutureBuilder<User?>(
              future: _getUserById(payment.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final user = snapshot.data;
                
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Informations sur le paiement
                      _buildInfoRow('ID Transaction', payment.transactionId ?? 'N/A'),
                      _buildInfoRow('Date', DateFormat('dd/MM/yyyy HH:mm').format(payment.date)),
                      _buildInfoRow('Montant', '${payment.amount.toStringAsFixed(2)}€'),
                      _buildInfoRow('Méthode', _getPaymentMethodText(payment.paymentMethod)),
                      _buildInfoRow('Type', _getPaymentTypeText(payment.type)),
                      _buildInfoRow('Statut', _getStatusText(payment.status)),
                      
                      const Divider(),
                      
                      // Informations sur l'utilisateur
                      if (user != null) ...[
                        _buildInfoRow('Client', '${user.firstName} ${user.lastName}'),
                        _buildInfoRow('Email', user.email),
                        if (user.phone != null) _buildInfoRow('Téléphone', user.phone!),
                      ] else ...[
                        _buildInfoRow('Client ID', payment.userId),
                        const Text('Informations utilisateur non disponibles',
                          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                      ],
                      
                      const Divider(),
                      
                      // Actions sur le paiement
                      if (payment.status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updatePaymentStatus(payment.id, 'completed');
                              },
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Valider'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _updatePaymentStatus(payment.id, 'failed');
                              },
                              icon: const Icon(Icons.cancel),
                              label: const Text('Rejeter'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ] else if (payment.status == 'completed') ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _updatePaymentStatus(payment.id, 'refunded');
                          },
                          icon: const Icon(Icons.money_off),
                          label: const Text('Marquer comme remboursé'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label :',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'card':
        return 'Carte bancaire';
      case 'cash':
        return 'Espèces';
      case 'transfer':
        return 'Virement';
      default:
        return method;
    }
  }
  
  String _getPaymentTypeText(String type) {
    switch (type) {
      case 'membership':
        return 'Abonnement';
      case 'course':
        return 'Cours';
      case 'individual_course':
        return 'Cours individuel';
      default:
        return type;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'completed':
        return 'Terminé';
      case 'failed':
        return 'Échoué';
      case 'refunded':
        return 'Remboursé';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des paiements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous'),
            Tab(text: 'Terminés'),
            Tab(text: 'En attente'),
          ],
          labelColor: Colors.white, // Couleur du texte sélectionné
    unselectedLabelColor: Colors.white.withOpacity(0.7), // Couleur du texte non sélectionné
    labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Texte en gras quand sélectionné
    indicatorColor: Colors.white, // Couleur de l'indicateur (ligne sous l'onglet)
    indicatorWeight: 3.0,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtres',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          // Vérifier si l'utilisateur est admin
          if (user == null || user.role != AppConstants.roleAdmin) {
            return const Center(
              child: Text('Accès restreint - Zone administrateur'),
            );
          }
          
          if (_isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Chargement des paiements...',
            );
          }
          
          return Column(
            children: [
              // Statistiques rapides des paiements
              _buildPaymentStatsCards(),
              
              // Filtres et recherche
              _buildSearchBar(),
              
              // Liste des paiements
              Expanded(
                child: _filteredPayments.isEmpty
                    ? _buildEmptyState()
                    : _buildPaymentList(),
              ),
              
              // Pagination
              if (_filteredPayments.isNotEmpty)
                _buildPagination(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildPaymentStatsCards() {
    final currentMonthTotal = _paymentStats['current_month_total'] ?? 0.0;
    final lastMonthTotal = _paymentStats['last_month_total'] ?? 0.0;
    final monthChange = _paymentStats['month_over_month_change'] ?? 0.0;
    final membershipTotal = _paymentStats['membership_total'] ?? 0.0;
    final courseTotal = _paymentStats['individual_course_total'] ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques des paiements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatCard(
                  'Ce mois',
                  '${currentMonthTotal.toStringAsFixed(0)}€',
                  Icons.date_range,
                  Colors.blue,
                  monthChange >= 0 
                      ? '+${monthChange.toStringAsFixed(1)}%' 
                      : '${monthChange.toStringAsFixed(1)}%',
                  monthChange >= 0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Mois dernier',
                  '${lastMonthTotal.toStringAsFixed(0)}€',
                  Icons.history,
                  Colors.indigo,
                  '',
                  Colors.transparent,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Abonnements',
                  '${membershipTotal.toStringAsFixed(0)}€',
                  Icons.card_membership,
                  Colors.purple,
                  '${((membershipTotal / (membershipTotal + courseTotal)) * 100).toStringAsFixed(0)}%',
                  Colors.purple,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Cours',
                  '${courseTotal.toStringAsFixed(0)}€',
                  Icons.school,
                  Colors.orange,
                  '${((courseTotal / (membershipTotal + courseTotal)) * 100).toStringAsFixed(0)}%',
                  Colors.orange,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    Color subtitleColor,
  ) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: subtitleColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un paiement...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                isDense: true,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                _filterPayments();
              },
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<String>(
            tooltip: 'Trier par',
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              if (value == _sortBy) {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
              } else {
                setState(() {
                  _sortBy = value;
                  _sortAscending = true;
                });
              }
              _filterPayments();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'date' 
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) 
                          : Icons.calendar_today,
                      size: 18,
                      color: _sortBy == 'date' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Date'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'amount',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'amount' 
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) 
                          : Icons.euro,
                      size: 18,
                      color: _sortBy == 'amount' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Montant'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'user',
                child: Row(
                  children: [
                    Icon(
                      _sortBy == 'user' 
                          ? (_sortAscending ? Icons.arrow_upward : Icons.arrow_downward) 
                          : Icons.person,
                      size: 18,
                      color: _sortBy == 'user' ? Theme.of(context).colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Utilisateur'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message = '';
    IconData icon = Icons.payments;
    
    if (_searchQuery.isNotEmpty || _selectedType != 'all' || _startDate != null || _endDate != null) {
      message = 'Aucun paiement ne correspond à vos critères de recherche';
      icon = Icons.search_off;
    } else if (_selectedStatus == 'pending') {
      message = 'Aucun paiement en attente';
      icon = Icons.pending_actions;
    } else if (_selectedStatus == 'completed') {
      message = 'Aucun paiement terminé';
      icon = Icons.check_circle;
    } else {
      message = 'Aucun paiement disponible';
      icon = Icons.payments_outlined;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty || _selectedType != 'all' || _startDate != null || _endDate != null)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedType = 'all';
                  _startDate = null;
                  _endDate = null;
                });
                _filterPayments();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Effacer les filtres'),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPaymentList() {
    final currentPageItems = _getCurrentPageItems();
    
    return ListView.builder(
      itemCount: currentPageItems.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final payment = currentPageItems[index];
        return _buildPaymentCard(payment);
      },
    );
  }
  
  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPaymentDetails(payment),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec date et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy - HH:mm').format(payment.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(payment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(payment.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(payment.status),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Informations de paiement
              Row(
                children: [
                  // Avatar ou icône de l'utilisateur
                  FutureBuilder<User?>(
                    future: _getUserById(payment.userId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      
                      final user = snapshot.data;
                      
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: Text(
                          user != null 
                              ? user.firstName.substring(0, 1) + user.lastName.substring(0, 1)
                              : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<User?>(
                          future: _getUserById(payment.userId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Text('Chargement...');
                            }
                            
                            final user = snapshot.data;
                            
                            return Text(
                              user != null 
                                  ? '${user.firstName} ${user.lastName}'
                                  : 'Utilisateur ID: ${payment.userId}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getPaymentTypeText(payment.type)} - ${_getPaymentMethodText(payment.paymentMethod)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Montant
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${payment.amount.toStringAsFixed(2)}€',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              
              // Actions rapides pour les paiements en attente
              if (payment.status == 'pending') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _updatePaymentStatus(payment.id, 'failed'),
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Rejeter'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _updatePaymentStatus(payment.id, 'completed'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1 
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            'Page $_currentPage sur $_totalPages',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages 
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }
  
  void _showFilterDialog() {
    // Créer des contrôleurs temporaires pour les dates
    final startDateController = TextEditingController(
      text: _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '',
    );
    final endDateController = TextEditingController(
      text: _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : '',
    );
    
    // Variables temporaires pour les filtres
    String tempType = _selectedType;
    DateTime? tempStartDate = _startDate;
    DateTime? tempEndDate = _endDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Filtrer les paiements'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filtre par type
                  const Text('Type de paiement'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Tous'),
                        selected: tempType == 'all',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              tempType = 'all';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Abonnements'),
                        selected: tempType == 'membership',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              tempType = 'membership';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Cours'),
                        selected: tempType == 'course',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              tempType = 'course';
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Cours individuels'),
                        selected: tempType == 'individual_course',
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              tempType = 'individual_course';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Filtre par date
                  const Text('Période'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: startDateController,
                          decoration: const InputDecoration(
                            labelText: 'Date de début',
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: tempStartDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            
                            if (pickedDate != null) {
                              setDialogState(() {
                                tempStartDate = pickedDate;
                                startDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: endDateController,
                          decoration: const InputDecoration(
                            labelText: 'Date de fin',
                            suffixIcon: Icon(Icons.calendar_today),
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          onTap: () async {
                            final DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: tempEndDate ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                            );
                            
                            if (pickedDate != null) {
                              setDialogState(() {
                                tempEndDate = pickedDate;
                                endDateController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Périodes prédéfinies
                  Wrap(
                    spacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Aujourd\'hui'),
                        onPressed: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          
                          setDialogState(() {
                            tempStartDate = today;
                            tempEndDate = today;
                            startDateController.text = DateFormat('dd/MM/yyyy').format(today);
                            endDateController.text = DateFormat('dd/MM/yyyy').format(today);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Cette semaine'),
                        onPressed: () {
                          final now = DateTime.now();
                          final today = DateTime(now.year, now.month, now.day);
                          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
                          
                          setDialogState(() {
                            tempStartDate = startOfWeek;
                            tempEndDate = today;
                            startDateController.text = DateFormat('dd/MM/yyyy').format(startOfWeek);
                            endDateController.text = DateFormat('dd/MM/yyyy').format(today);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Ce mois'),
                        onPressed: () {
                          final now = DateTime.now();
                          final startOfMonth = DateTime(now.year, now.month, 1);
                          
                          setDialogState(() {
                            tempStartDate = startOfMonth;
                            tempEndDate = now;
                            startDateController.text = DateFormat('dd/MM/yyyy').format(startOfMonth);
                            endDateController.text = DateFormat('dd/MM/yyyy').format(now);
                          });
                        },
                      ),
                      ActionChip(
                        label: const Text('Tout effacer'),
                        onPressed: () {
                          setDialogState(() {
                            tempStartDate = null;
                            tempEndDate = null;
                            startDateController.clear();
                            endDateController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedType = tempType;
                    _startDate = tempStartDate;
                    _endDate = tempEndDate;
                  });
                  _filterPayments();
                  Navigator.pop(context);
                },
                child: const Text('Appliquer'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Écran factice pour la gestion des routines (à implémenter)
class RoutineManagementScreen extends StatelessWidget {
  const RoutineManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des routines'),
      ),
      body: const Center(
        child: Text('Écran de gestion des routines à implémenter'),
      ),
    );
  }
}