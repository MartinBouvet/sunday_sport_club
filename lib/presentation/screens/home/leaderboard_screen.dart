import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/utils/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

/// Service pour récupérer les données du classement
class LeaderboardService {
  // Méthode pour récupérer les utilisateurs triés
  Future<List<Map<String, dynamic>>> getLeaderboardData(String filter, String timeRange) async {
    try {
      // Requête à Supabase pour récupérer les utilisateurs triés
      dynamic response;
      
      switch (filter) {
        case 'xp':
          response = await supabase
              .from('profiles')
              .select()
              .order('experience_points', ascending: false)
              .limit(100);
          break;
        case 'level':
          response = await supabase
              .from('profiles')
              .select()
              .order('level', ascending: false)
              .limit(100);
          break;
        case 'strength':
          response = await supabase
              .from('profiles')
              .select()
              .order('strength', ascending: false)
              .limit(100);
          break;
        case 'endurance':
          response = await supabase
              .from('profiles')
              .select()
              .order('endurance', ascending: false)
              .limit(100);
          break;
        default:
          response = await supabase
              .from('profiles')
              .select()
              .order('experience_points', ascending: false)
              .limit(100);
      }

      // Convertir les données en List<Map<String, dynamic>>
      if (response is List) {
        return response.map((item) => item as Map<String, dynamic>).toList();
      } else if (response is PostgrestResponse) {
        return (response.data as List).map((item) => item as Map<String, dynamic>).toList();
      } else {
        print('Type de réponse inattendu: ${response.runtimeType}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des données de classement: $e');
      return [];
    }
  }
}

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late TabController _tabController;
  List<Map<String, dynamic>> _leaderboardData = [];
  String _filter = 'xp'; // Options: 'xp', 'level', 'strength', 'endurance'
  String _timeRange = 'all_time'; // Options: 'weekly', 'monthly', 'all_time'
  
  // Position de l'utilisateur actuel
  int _currentUserRank = 0;
  
  // Service de classement
  final LeaderboardService _leaderboardService = LeaderboardService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _loadLeaderboardData();
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
          case 0:
            _timeRange = 'weekly';
            break;
          case 1:
            _timeRange = 'monthly';
            break;
          case 2:
            _timeRange = 'all_time';
            break;
        }
      });
      _loadLeaderboardData();
    }
  }

  Future<void> _loadLeaderboardData() async {
    setState(() {
      _isLoading = true;
    });

    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Charger les données depuis Supabase
      final leaderboardData = await _leaderboardService.getLeaderboardData(_filter, _timeRange);
      
      // Trouver le rang de l'utilisateur actuel
      if (authProvider.currentUser != null) {
        final userId = authProvider.currentUser!.id;
        for (int i = 0; i < leaderboardData.length; i++) {
          if (leaderboardData[i]['id'] == userId) {
            _currentUserRank = i + 1;
            break;
          }
        }
      }
      
      setState(() {
        _leaderboardData = leaderboardData;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement du classement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Classement'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cette semaine'),
            Tab(text: 'Ce mois'),
            Tab(text: 'Tous les temps'),
          ],
          labelColor: Colors.white, // Couleur du texte sélectionné
    unselectedLabelColor: Colors.white.withOpacity(0.7), // Couleur du texte non sélectionné
    labelStyle: const TextStyle(fontWeight: FontWeight.bold), // Texte en gras quand sélectionné
    indicatorColor: Colors.white, // Couleur de l'indicateur (ligne sous l'onglet)
    indicatorWeight: 3.0,
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement du classement...')
          : provider.Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                
                return Column(
                  children: [
                    // Options de filtrage
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Classer par :',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildFilterChip('Points XP', 'xp'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Niveau', 'level'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Force', 'strength'),
                                const SizedBox(width: 8),
                                _buildFilterChip('Endurance', 'endurance'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // En-têtes du tableau
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 40, child: Text('Rang', style: TextStyle(fontWeight: FontWeight.bold))),
                          const SizedBox(width: 8),
                          const Expanded(child: Text('Membre', style: TextStyle(fontWeight: FontWeight.bold))),
                          SizedBox(
                            width: 80,
                            child: Text(
                              _getFilterLabel(),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste des utilisateurs
                    Expanded(
                      child: ListView.builder(
                        itemCount: _leaderboardData.length,
                        itemBuilder: (context, index) {
                          final userData = _leaderboardData[index];
                          final rank = index + 1;
                          final isCurrentUser = user != null && userData['id'] == user.id;
                          
                          return InkWell(
                            onTap: () {
                              // Ouvrir le profil de l'utilisateur
                              if (isCurrentUser) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isCurrentUser ? theme.colorScheme.primary.withOpacity(0.1) : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.withOpacity(0.2)),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Rang
                                  SizedBox(
                                    width: 40,
                                    child: _buildRankIndicator(rank),
                                  ),
                                  const SizedBox(width: 8),
                                  // Avatar
                                  AvatarDisplay(
                                    gender: userData['gender'] ?? 'homme',
                                    skinColor: userData['skin_color'] ?? 'blanc',
                                    stage: userData['avatar_stage'] ?? 'mince',
                                    size: 40,
                                    showBorder: rank <= 3,
                                    borderColor: rank <= 3 ? _getMedalColor(rank) : null,
                                  ),
                                  const SizedBox(width: 12),
                                  // Nom de l'utilisateur
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              '${userData['first_name'] ?? 'Non'} ${userData['last_name'] ?? 'Défini'}',
                                              style: TextStyle(
                                                fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                                color: isCurrentUser ? theme.colorScheme.primary : null,
                                              ),
                                            ),
                                            if (isCurrentUser)
                                              Container(
                                                margin: const EdgeInsets.only(left: 8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: theme.colorScheme.primary.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Vous',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                        Text(
                                          'Niveau ${userData['level'] ?? 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Valeur selon le filtre
                                  SizedBox(
                                    width: 80,
                                    child: Column(
                                      children: [
                                        Text(
                                          _getFormattedValue(userData),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isCurrentUser ? theme.colorScheme.primary : null,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_filter != 'level')
                                          Text(
                                            _getSecondaryValue(userData),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Statistiques de l'utilisateur actuel
                    if (user != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          border: Border(
                            top: BorderSide(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                AvatarDisplay(
                                  gender: user.gender,
                                  skinColor: user.skinColor,
                                  stage: user.avatarStage,
                                  size: 50,
                                  showBorder: true,
                                  borderColor: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Votre position : ${_currentUserRank}${_getOrdinalSuffix(_currentUserRank)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                      Text(
                                        '${user.firstName} ${user.lastName} - Niveau ${user.level}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                  ],
                                )
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatBox('XP', '${user.experiencePoints}', Icons.auto_awesome),
                                _buildStatBox('Force', '${user.strength}', Icons.fitness_center),
                                _buildStatBox('Endurance', '${user.endurance}', Icons.speed),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  // Widget pour afficher une puce de filtre
  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filter == filterValue;
    
    return ChoiceChip(
      label: Text(label),
      selected:
      isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = filterValue;
          });
          _loadLeaderboardData();
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
    );
  }

  // Widget pour afficher l'indicateur de rang
  Widget _buildRankIndicator(int rank) {
    // Style spécial pour les 3 premiers
    if (rank <= 3) {
      Color color = _getMedalColor(rank);
      IconData icon = Icons.emoji_events;
      
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: color,
          size: 16,
        ),
      );
    } else {
      // Affichage normal du rang
      return Text(
        '$rank',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  // Détermine la couleur de la médaille en fonction du rang
  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Or
      case 2:
        return Colors.blueGrey[300]!; // Argent
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.grey;
    }
  }

  // Obtient le libellé du filtre actuel
  String _getFilterLabel() {
    switch (_filter) {
      case 'xp':
        return 'Points XP';
      case 'level':
        return 'Niveau';
      case 'strength':
        return 'Force';
      case 'endurance':
        return 'Endurance';
      default:
        return 'Points XP';
    }
  }

  // Formate la valeur à afficher selon le filtre
  String _getFormattedValue(Map<String, dynamic> user) {
    switch (_filter) {
      case 'xp':
        return NumberFormat.compact().format(user['experience_points'] ?? 0);
      case 'level':
        return 'Nv. ${user['level'] ?? 1}';
      case 'strength':
        return '${user['strength'] ?? 0}';
      case 'endurance':
        return '${user['endurance'] ?? 0}';
      default:
        return '${user['experience_points'] ?? 0}';
    }
  }

  // Affiche une valeur secondaire selon le filtre
  String _getSecondaryValue(Map<String, dynamic> user) {
    switch (_filter) {
      case 'xp':
        return 'Nv. ${user['level'] ?? 1}';
      case 'strength':
        return '$_timeRange';
      case 'endurance':
        return '$_timeRange';
      default:
        return '';
    }
  }

  // Obtient le suffixe ordinal (1er, 2ème, etc.)
  String _getOrdinalSuffix(int rank) {
    if (rank == 1) {
      return 'er';
    } else {
      return 'ème';
    }
  }

  // Widget pour afficher une statistique dans un conteneur
  Widget _buildStatBox(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}