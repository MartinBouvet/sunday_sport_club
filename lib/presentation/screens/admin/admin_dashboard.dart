import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/repositories/course_repository.dart';
import '../../../data/repositories/routine_repository.dart';
import '../../providers/auth_provider.dart';
import 'course_management_screen.dart';
import 'member_management_screen.dart';
import 'payment_management_screen.dart';
import 'routine_validation_screen.dart';

/// Tableau de bord administrateur
///
/// Présente une vue d'ensemble des statistiques du club, accès rapides
/// aux fonctionnalités administratives, et affiche des indicateurs clés.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // Référentiels pour accéder aux données
  final PaymentRepository _paymentRepository = PaymentRepository();
  final UserRepository _userRepository = UserRepository();
  final CourseRepository _courseRepository = CourseRepository();
  final RoutineRepository _routineRepository = RoutineRepository();

  // Statistiques du tableau de bord
  Map<String, dynamic> _paymentStats = {};
  int _activeMembers = 0;
  int _inactiveMembers = 0;
  int _upcomingCourses = 0;
  int _pendingRoutines = 0;
  double _monthlyRevenue = 0.0;
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Charger les statistiques de paiement
      final paymentStats = await _paymentRepository.getPaymentStatistics();
      _paymentStats = paymentStats;
      _monthlyRevenue = paymentStats['current_month_total'] ?? 0.0;

      // Compter les membres actifs et inactifs
      final users = await _userRepository.getAllUsers();
      _activeMembers = users.where((user) => user.isActive).length;
      _inactiveMembers = users.where((user) => !user.isActive).length;

      // Compter les cours à venir
      final upcomingCourses = await _courseRepository.getUpcomingCourses();
      _upcomingCourses = upcomingCourses.length;

      // Compter les routines en attente de validation
      _pendingRoutines = await _routineRepository.getPendingValidationCount();

      // Charger les activités récentes
      _recentActivities = await _loadRecentActivities();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des données: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentActivities() async {
    // Obtenir les activités récentes à partir de différentes sources de données
    List<Map<String, dynamic>> activities = [];

    try {
      // 1. Derniers paiements
      final recentPayments = await _paymentRepository.getRecentPayments(5);
      for (var payment in recentPayments) {
        final user = await _userRepository.getUser(payment.userId);
        activities.add({
          'type': 'payment',
          'description': 'Paiement de ${payment.amount}€ par ${user?.firstName ?? ''} ${user?.lastName ?? ''}',
          'timestamp': payment.date,
          'id': payment.id
        });
      }

      // 2. Derniers cours créés
      final recentCourses = await _courseRepository.getRecentCourses(3);
      for (var course in recentCourses) {
        activities.add({
          'type': 'course',
          'description': 'Nouveau cours: ${course.title}',
          'timestamp': course.date, // Nous utilisons la date du cours comme approximation
          'id': course.id
        });
      }

      // 3. Dernières inscriptions utilisateurs
      final recentUsers = await _userRepository.getRecentUsers(3);
      for (var user in recentUsers) {
        activities.add({
          'type': 'member',
          'description': 'Nouvel adhérent: ${user.firstName} ${user.lastName}',
          'timestamp': user.createdAt ?? DateTime.now(),
          'id': user.id
        });
      }

      // Trier toutes les activités par date (plus récent en premier)
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      // Limiter à 10 activités max
      if (activities.length > 10) {
        activities = activities.sublist(0, 10);
      }

      return activities;
    } catch (e) {
      debugPrint('Erreur lors du chargement des activités récentes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord administrateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Rafraîchir',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // Déconnexion
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).pop();
            },
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final User? user = authProvider.currentUser;
          
          // Vérifier si l'utilisateur est admin
          if (user == null || user.role != 'admin') {
            return const Center(
              child: Text('Accès non autorisé. Veuillez vous connecter en tant qu\'administrateur.'),
            );
          }
          
          if (_isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Chargement des données...',
            );
          }
          
          if (_errorMessage != null) {
            return ErrorDisplay(
              message: _errorMessage!,
              type: ErrorType.network,
              actionLabel: 'Réessayer',
              onAction: _loadDashboardData,
            );
          }
          
          return _buildDashboardContent(user);
        },
      ),
      drawer: _buildAdminDrawer(),
    );
  }

  Widget _buildDashboardContent(User admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(admin),
          const SizedBox(height: 24),
          
          // Statistiques globales
          _buildStatCards(),
          const SizedBox(height: 24),
          
          // Modules d'administration
          const Text(
            'Gestion du club',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminModules(),
          const SizedBox(height: 24),
          
          // Revenu mensuel
          _buildRevenueCard(),
          const SizedBox(height: 24),
          
          // Activité récente
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(User admin) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                admin.firstName.isNotEmpty ? admin.firstName.substring(0, 1) : 'A',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenue, ${admin.firstName}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Dashboard Admin - Sunday Sport Club',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Membres actifs',
          _activeMembers.toString(),
          Icons.people,
          Colors.blue,
          '$_inactiveMembers inactifs',
        ),
        _buildStatCard(
          'Cours programmés',
          _upcomingCourses.toString(),
          Icons.event_available,
          Colors.orange,
          'Pour ce mois',
        ),
        _buildStatCard(
          'Validations en attente',
          _pendingRoutines.toString(),
          Icons.pending_actions,
          Colors.purple,
          'Routines à valider',
        ),
        _buildStatCard(
          'Chiffre mensuel',
          '${_monthlyRevenue.toStringAsFixed(0)}€',
          Icons.euro,
          Colors.green,
          '${_paymentStats['month_over_month_change']?.toStringAsFixed(1) ?? "0.0"}% vs mois dernier',
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
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
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminModules() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildModuleCard(
          'Gestion des membres',
          Icons.people,
          Colors.blue,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MemberManagementScreen(),
            ),
          ).then((_) => _loadDashboardData()),
        ),
        _buildModuleCard(
          'Gestion des cours',
          Icons.event_note,
          Colors.orange,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CourseManagementScreen(),
            ),
          ).then((_) => _loadDashboardData()),
        ),
        _buildModuleCard(
          'Validation routines',
          Icons.fitness_center,
          Colors.purple,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const RoutineValidationScreen(),
            ),
          ).then((_) => _loadDashboardData()),
        ),
        _buildModuleCard(
          'Gestion des paiements',
          Icons.payments,
          Colors.green,
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentManagementScreen(),
            ),
          ).then((_) => _loadDashboardData()),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueCard() {
    final individualTotal = _paymentStats['individual_course_total'] ?? 0.0;
    final membershipTotal = _paymentStats['membership_total'] ?? 0.0;
    final estimatedAnnual = (_monthlyRevenue * 12);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenus mensuels',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildRevenueInfoItem(
                  'Total collectif',
                  '${individualTotal.toStringAsFixed(0)}€',
                  Colors.blue,
                ),
                _buildRevenueInfoItem(
                  'Total individuel',
                  '${membershipTotal.toStringAsFixed(0)}€',
                  Colors.purple,
                ),
                _buildRevenueInfoItem(
                  'Estimation annuelle',
                  '${estimatedAnnual.toStringAsFixed(0)}€',
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentManagementScreen(),
                ),
              ),
              icon: const Icon(Icons.bar_chart),
              label: const Text('Voir statistiques détaillées'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueInfoItem(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityCard() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Activité récente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _recentActivities.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Aucune activité récente',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: _recentActivities
                        .map((activity) => _buildActivityItem(activity))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    IconData icon;
    Color color;
    
    switch (activity['type']) {
      case 'payment':
        icon = Icons.payments;
        color = Colors.green;
        break;
      case 'course':
        icon = Icons.event_note;
        color = Colors.orange;
        break;
      case 'member':
        icon = Icons.person_add;
        color = Colors.blue;
        break;
      case 'routine':
        icon = Icons.fitness_center;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    final DateTime timestamp = activity['timestamp'] ?? DateTime.now();
    final Duration difference = DateTime.now().difference(timestamp);
    String timeAgo;
    
    if (difference.inDays > 0) {
      timeAgo = 'Il y a ${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      timeAgo = 'Il y a ${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      timeAgo = 'Il y a ${difference.inMinutes} minute(s)';
    } else {
      timeAgo = 'À l\'instant';
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['description'] ?? 'Activité non définie',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
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
    );
  }

  Drawer _buildAdminDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Sunday Sport Club',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administration',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final user = authProvider.currentUser;
                    return Text(
                      user != null ? '${user.firstName} ${user.lastName}' : 'Admin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de bord'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Gestion des membres'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberManagementScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.event_note),
            title: const Text('Gestion des cours'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CourseManagementScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.fitness_center),
            title: const Text('Validation routines'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineValidationScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Gestion des paiements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaymentManagementScreen(),
                ),
              ).then((_) => _loadDashboardData());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Paramètres'),
            onTap: () {
              Navigator.pop(context);
              // Navigation vers les paramètres
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}