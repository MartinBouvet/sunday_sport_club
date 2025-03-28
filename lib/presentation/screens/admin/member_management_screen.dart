import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/user_repository.dart';
import '../../providers/auth_provider.dart';

/// Écran de gestion des membres
///
/// Permet aux administrateurs de visualiser, filtrer, et gérer
/// tous les membres du club, avec options pour modifier leur statut,
/// informations personnelles, et suivre leurs activités.
class MemberManagementScreen extends StatefulWidget {
  const MemberManagementScreen({super.key});

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final UserRepository _userRepository = UserRepository();
  
  bool _isLoading = true;
  bool _isSearching = false;
  List<User> _allMembers = [];
  List<User> _filteredMembers = [];
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'active', 'inactive'
  String _sortBy = 'name'; // 'name', 'date', 'level'
  
  // Contrôleurs pour la recherche
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadMembers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Récupération de tous les membres depuis Supabase
      final allMembers = await _fetchAllMembers();
      
      setState(() {
        _allMembers = allMembers;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des membres: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<List<User>> _fetchAllMembers() async {
    try {
      // Exemple d'implémentation - à adapter selon votre structure
      // Cette fonction utiliserait normalement un repository dédié aux utilisateurs
      final response = await _userRepository.getAllUsers();
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des membres: $e');
      // Pour éviter de planter l'application, on retourne une liste vide
      return [];
    }
  }
  
  void _applyFilters() {
    // Filtrer par statut
    List<User> filtered = _allMembers;
    
    if (_statusFilter == 'active') {
      filtered = filtered.where((member) => member.isActive).toList();
    } else if (_statusFilter == 'inactive') {
      filtered = filtered.where((member) => !member.isActive).toList();
    }
    
    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((member) {
        return member.firstName.toLowerCase().contains(query) ||
               member.lastName.toLowerCase().contains(query) ||
               member.email.toLowerCase().contains(query);
      }).toList();
    }
    
    // Trier
    switch (_sortBy) {
      case 'name':
        filtered.sort((a, b) => '${a.firstName} ${a.lastName}'.compareTo('${b.firstName} ${b.lastName}'));
        break;
      case 'date':
        filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
        break;
      case 'level':
        filtered.sort((a, b) => b.level.compareTo(a.level));
        break;
    }
    
    setState(() {
      _filteredMembers = filtered;
    });
  }
  
  void _updateUserStatus(User user, bool isActive) async {
    // Montrer un indicateur de chargement
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Mettre à jour le statut de l'utilisateur
      await _userRepository.updateUser(user.id, {'is_active': isActive});
      
      // Mettre à jour la liste locale
      final index = _allMembers.indexWhere((m) => m.id == user.id);
      if (index != -1) {
        setState(() {
          _allMembers[index] = _allMembers[index].copyWith(isActive: isActive);
          _applyFilters();
        });
      }
      
      // Afficher un message de confirmation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut de ${user.firstName} mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du statut: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _applyFilters();
      }
    });
  }
  
  void _showMemberDetail(User member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec avatar et nom
                Row(
                  children: [
                    AvatarDisplay(
                      gender: member.gender,
                      skinColor: member.skinColor,
                      stage: member.avatarStage,
                      size: 80,
                      showBorder: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${member.firstName} ${member.lastName}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Niveau ${member.level}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: member.isActive ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  member.isActive ? 'Actif' : 'Inactif',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Informations personnelles
                const Text(
                  'Informations personnelles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Email', member.email),
                if (member.phone != null) _buildInfoRow('Téléphone', member.phone!),
                if (member.birthDate != null) _buildInfoRow(
                  'Date de naissance', 
                  DateFormat('dd/MM/yyyy').format(member.birthDate!),
                ),
                _buildInfoRow('Genre', member.gender == AppConstants.genderMale ? 'Homme' : 'Femme'),
                const SizedBox(height: 16),
                
                // Statistiques
                const Text(
                  'Statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatsGrid(member),
                const SizedBox(height: 24),
                
                // Historique
                const Text(
                  'Historique',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Inscription', member.createdAt != null 
                  ? DateFormat('dd/MM/yyyy').format(member.createdAt!) 
                  : 'Inconnue'
                ),
                _buildInfoRow('Dernière connexion', member.lastLogin != null 
                  ? DateFormat('dd/MM/yyyy').format(member.lastLogin!) 
                  : 'Jamais'
                ),
                const SizedBox(height: 24),
                
                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      text: 'Fermer',
                      onPressed: () => Navigator.pop(context),
                      type: AppButtonType.outline,
                      size: AppButtonSize.medium,
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      text: member.isActive ? 'Désactiver' : 'Activer',
                      onPressed: () {
                        Navigator.pop(context);
                        _updateUserStatus(member, !member.isActive);
                      },
                      type: member.isActive ? AppButtonType.secondary : AppButtonType.primary,
                      size: AppButtonSize.medium,
                      icon: member.isActive ? Icons.person_off : Icons.person_add,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsGrid(User member) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildStatItem('Expérience', '${member.experiencePoints} XP', Icons.star),
        _buildStatItem('Endurance', member.endurance.toString(), Icons.speed),
        _buildStatItem('Force', member.strength.toString(), Icons.fitness_center),
        _buildStatItem('Poids', member.weight != null ? '${member.weight} kg' : 'Non renseigné', Icons.monitor_weight),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Rechercher un membre...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFilters();
                  });
                },
                autofocus: true,
              )
            : const Text('Gestion des membres'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
            tooltip: _isSearching ? 'Annuler' : 'Rechercher',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMembers,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          // Vérifier si l'utilisateur est admin
          if (user == null || user.role != 'admin') {
            return const Center(
              child: Text('Accès non autorisé. Veuillez vous connecter en tant qu\'administrateur.'),
            );
          }
          
          if (_isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Chargement des membres...',
            );
          }
          
          return Column(
            children: [
              // Filtres et statistiques
              _buildFiltersSection(),
              
              // Liste des membres
              Expanded(
                child: _filteredMembers.isEmpty
                    ? _buildEmptyState()
                    : _buildMembersList(),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigation vers l'écran d'ajout de membre
        },
        tooltip: 'Ajouter un membre',
        child: const Icon(Icons.person_add),
      ),
    );
  }
  
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Compteur de membres
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: 'Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: '${_allMembers.length} membres',
                      ),
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: '${_allMembers.where((m) => m.isActive).length} actifs',
                        style: const TextStyle(color: Colors.green),
                      ),
                      const TextSpan(text: ' • '),
                      TextSpan(
                        text: '${_allMembers.where((m) => !m.isActive).length} inactifs',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Filtres
              DropdownButton<String>(
                value: _statusFilter,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _statusFilter = value;
                      _applyFilters();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'all',
                    child: Text('Tous'),
                  ),
                  DropdownMenuItem(
                    value: 'active',
                    child: Text('Actifs'),
                  ),
                  DropdownMenuItem(
                    value: 'inactive',
                    child: Text('Inactifs'),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _sortBy,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                      _applyFilters();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(
                    value: 'name',
                    child: Text('Trier par nom'),
                  ),
                  DropdownMenuItem(
                    value: 'date',
                    child: Text('Trier par date'),
                  ),
                  DropdownMenuItem(
                    value: 'level',
                    child: Text('Trier par niveau'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isNotEmpty)
            Row(
              children: [
                Icon(Icons.search, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Résultats pour "$_searchQuery": ${_filteredMembers.length} membre${_filteredMembers.length > 1 ? "s" : ""} trouvé${_filteredMembers.length > 1 ? "s" : ""}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    String message;
    
    if (_searchQuery.isNotEmpty) {
      message = 'Aucun membre ne correspond à votre recherche.';
    } else if (_statusFilter == 'active') {
      message = 'Aucun membre actif trouvé.';
    } else if (_statusFilter == 'inactive') {
      message = 'Aucun membre inactif trouvé.';
    } else {
      message = 'Aucun membre trouvé.';
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people,
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
          ),
          const SizedBox(height: 24),
          AppButton(
            text: 'Ajouter un membre',
            onPressed: () {
              // Navigation vers l'écran d'ajout de membre
            },
            type: AppButtonType.primary,
            size: AppButtonSize.medium,
            icon: Icons.person_add,
          ),
        ],
      ),
    );
  }
  
  Widget _buildMembersList() {
    return ListView.builder(
      itemCount: _filteredMembers.length,
      itemBuilder: (context, index) {
        final member = _filteredMembers[index];
        return _buildMemberListItem(member);
      },
    );
  }
  
  Widget _buildMemberListItem(User member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMemberDetail(member),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Avatar
              AvatarDisplay(
                gender: member.gender,
                skinColor: member.skinColor,
                stage: member.avatarStage,
                size: 50,
                showBorder: true,
              ),
              const SizedBox(width: 16),
              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${member.firstName} ${member.lastName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: member.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.isActive ? 'Actif' : 'Inactif',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.email,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          'Niveau ${member.level}',
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'Inscrit le ${member.createdAt != null ? DateFormat('dd/MM/yyyy').format(member.createdAt!) : 'inconnue'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      member.isActive ? Icons.person_off : Icons.person_add,
                      color: member.isActive ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _updateUserStatus(member, !member.isActive),
                    tooltip: member.isActive ? 'Désactiver' : 'Activer',
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showMemberDetail(member),
                    tooltip: 'Plus d\'options',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}