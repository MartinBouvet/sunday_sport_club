import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../profile/profile_screen.dart';

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
  bool _showCurrentUserHighlight = false;

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

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Dans une implémentation réelle, nous chargerions les données depuis le backend
      // Pour cette démo, nous allons simuler les données
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Simuler les données
      List<Map<String, dynamic>> dummyData = _generateLeaderboardData();
      
      // Trier selon le filtre
      dummyData.sort((a, b) {
        switch (_filter) {
          case 'xp':
            return (b['experiencePoints'] as int).compareTo(a['experiencePoints'] as int);
          case 'level':
            return (b['level'] as int).compareTo(a['level'] as int);
          case 'strength':
            return (b['strength'] as int).compareTo(a['strength'] as int);
          case 'endurance':
            return (b['endurance'] as int).compareTo(a['endurance'] as int);
          default:
            return (b['experiencePoints'] as int).compareTo(a['experiencePoints'] as int);
        }
      });
      
      // Trouver le rang de l'utilisateur actuel
      if (authProvider.currentUser != null) {
        final userId = authProvider.currentUser!.id;
        for (int i = 0; i < dummyData.length; i++) {
          if (dummyData[i]['id'] == userId) {
            _currentUserRank = i + 1;
            break;
          }
        }
      }
      
      setState(() {
        _leaderboardData = dummyData;
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

  // Génère des données de classement fictives
  List<Map<String, dynamic>> _generateLeaderboardData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;
    
    // Créer une liste d'utilisateurs fictifs
    List<Map<String, dynamic>> users = [
      {
        'id': 'user1',
        'firstName': 'Thomas',
        'lastName': 'D.',
        'gender': 'homme',
        'skinColor': 'blanc',
        'avatarStage': 'muscle',
        'level': 42,
        'experiencePoints': 4250,
        'strength': 85,
        'endurance': 78,
      },
      {
        'id': 'user2',
        'firstName': 'Sophie',
        'lastName': 'M.',
        'gender': 'femme',
        'skinColor': 'blanc',
        'avatarStage': 'muscle',
        'level': 38,
        'experiencePoints': 3820,
        'strength': 72,
        'endurance': 90,
      },
      {
        'id': 'user3',
        'firstName': 'Karim',
        'lastName': 'B.',
        'gender': 'homme',
        'skinColor': 'metisse',
        'avatarStage': 'moyen',
        'level': 25,
        'experiencePoints': 2540,
        'strength': 65,
        'endurance': 60,
      },
      {
        'id': 'user4',
        'firstName': 'Léa',
        'lastName': 'T.',
        'gender': 'femme',
        'skinColor': 'metisse',
        'avatarStage': 'moyen',
        'level': 18,
        'experiencePoints': 1830,
        'strength': 45,
        'endurance': 70,
      },
      {
        'id': 'user5',
        'firstName': 'Maxime',
        'lastName': 'P.',
        'gender': 'homme',
        'skinColor': 'blanc',
        'avatarStage': 'mince',
        'level': 12,
        'experiencePoints': 1210,
        'strength': 40,
        'endurance': 35,
      },
      {
        'id': 'user6',
        'firstName': 'Nadia',
        'lastName': 'K.',
        'gender': 'femme',
        'skinColor': 'noir',
        'avatarStage': 'muscle',
        'level': 31,
        'experiencePoints': 3150,
        'strength': 68,
        'endurance': 75,
      },
      {
        'id': 'user7',
        'firstName': 'Antoine',
        'lastName': 'G.',
        'gender': 'homme',
        'skinColor': 'blanc',
        'avatarStage': 'moyen',
        'level': 22,
        'experiencePoints': 2210,
        'strength': 55,
        'endurance': 52,
      },
      {
        'id': 'user8',
        'firstName': 'Emma',
        'lastName': 'R.',
        'gender': 'femme',
        'skinColor': 'blanc',
        'avatarStage': 'moyen',
        'level': 27,
        'experiencePoints': 2710,
        'strength': 60,
        'endurance': 63,
      },
    ];
    
    // Ajouter l'utilisateur actuel s'il est connecté
    if (currentUser != null) {
      users.add({
        'id': currentUser.id,
        'firstName': currentUser.firstName,
        'lastName': currentUser.lastName,
        'gender': currentUser.gender,
        'skinColor': currentUser.skinColor,
        'avatarStage': currentUser.avatarStage,
        'level': currentUser.level,
        'experiencePoints': currentUser.experiencePoints,
        'strength': currentUser.strength,
        'endurance': currentUser.endurance,
      });
    }
    
    // Ajouter des variations en fonction de la période sélectionnée
    if (_timeRange == 'weekly') {
      // Simuler des données pour la semaine (moins de points)
      for (var user in users) {
        user['experiencePoints'] = (user['experiencePoints'] as int) ~/ 10;
      }
    } else if (_timeRange == 'monthly') {
      // Simuler des données pour le mois (environ un tiers des points totaux)
      for (var user in users) {
        user['experiencePoints'] = (user['experiencePoints'] as int) ~/ 3;
      }
    }
    
    return users;
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
        ),
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement du classement...')
          : Column(
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
                  child: Stack(
                    children: [
                      ListView.builder(
                        itemCount: _leaderboardData.length,
                        itemBuilder: (context, index) {
                          final user = _leaderboardData[index];
                          final rank = index + 1;
                          final isCurrentUser = Provider.of<AuthProvider>(context, listen: false).currentUser != null && 
                              user['id'] == Provider.of<AuthProvider>(context, listen: false).currentUser!.id;
                          
                          return InkWell(
                            onTap: () {
                              // Ouvrir le profil de l'utilisateur (sauf pour les démos)
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
                                    gender: user['gender'],
                                    skinColor: user['skinColor'],
                                    stage: user['avatarStage'],
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
                                              '${user['firstName']} ${user['lastName']}',
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
                                          'Niveau ${user['level']}',
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
                                          _getFormattedValue(user),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isCurrentUser ? theme.colorScheme.primary : null,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_filter != 'level')
                                          Text(
                                            _getSecondaryValue(user),
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
                      
                      // Bouton pour aller à la position de l'utilisateur
                      if (_currentUserRank > 0 && _leaderboardData.length > 10)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton(
                            heroTag: 'findMe',
                            onPressed: () {
                              setState(() {
                                _showCurrentUserHighlight = true;
                              });
                              // Faire défiler jusqu'à la position de l'utilisateur
                              // Dans une implémentation réelle, vous utiliseriez un ScrollController
                              
                              // Désactiver la surbrillance après 2 secondes
                              Future.delayed(const Duration(seconds: 2), () {
                                if (mounted) {
                                  setState(() {
                                    _showCurrentUserHighlight = false;
                                  });
                                }
                              });
                            },
                            child: const Icon(Icons.person_search),
                            tooltip: 'Trouver ma position',
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Statistiques de l'utilisateur actuel
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final currentUser = authProvider.currentUser;
                    if (currentUser == null) return const SizedBox.shrink();
                    
                    return Container(
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
                                gender: currentUser.gender,
                                skinColor: currentUser.skinColor,
                                stage: currentUser.avatarStage,
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
                                      '${currentUser.firstName} ${currentUser.lastName} - Niveau ${currentUser.level}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatBox('XP', '${currentUser.experiencePoints}', Icons.auto_awesome),
                              _buildStatBox('Force', '${currentUser.strength}', Icons.fitness_center),
                              _buildStatBox('Endurance', '${currentUser.endurance}', Icons.speed),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }

  // Widget pour afficher une puce de filtre
  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filter == filterValue;
    
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
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
        return NumberFormat.compact().format(user['experiencePoints']);
      case 'level':
        return 'Nv. ${user['level']}';
      case 'strength':
        return '${user['strength']}';
      case 'endurance':
        return '${user['endurance']}';
      default:
        return '${user['experiencePoints']}';
    }
  }

  // Affiche une valeur secondaire selon le filtre
  String _getSecondaryValue(Map<String, dynamic> user) {
    switch (_filter) {
      case 'xp':
        return 'Nv. ${user['level']}';
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