import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../home/avatar_customization_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Si nécessaire, actualiser les données utilisateur
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser != null) {
        await authProvider.refreshUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      // Rediriger vers l'écran de connexion
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(
              center: true,
              message: 'Chargement du profil...',
            )
          : Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final user = authProvider.currentUser;
                if (user == null) {
                  return const Center(
                    child: Text('Veuillez vous connecter pour accéder à votre profil'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section avatar et informations principales
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 5,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: AvatarDisplay(
                                        gender: user.gender,
                                        skinColor: user.skinColor,
                                        stage: user.avatarStage,
                                        size: 120,
                                        showBorder: true,
                                        borderWidth: 3.0,
                                      ),
                                    ),
                                    CircleAvatar(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      radius: 18,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => const AvatarCustomizationScreen(),
                                            ),
                                          ).then((_) {
                                            // Rafraîchir les données au retour
                                            _loadUserData();
                                          });
                                        },
                                        tooltip: 'Personnaliser avatar',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '${user.firstName} ${user.lastName}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    'Niveau ${user.level}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Barre de progression du niveau
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${user.experiencePoints % 100}/100 XP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        Text(
                                          'Prochain niveau: ${user.level + 1}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: (user.experiencePoints % 100) / 100,
                                      minHeight: 10,
                                      backgroundColor: Colors.grey[200],
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                
                                // Points d'expérience totaux
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.auto_awesome, color: Colors.amber),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Points d\'expérience: ${user.experiencePoints}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section des informations personnelles
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Informations personnelles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildInfoItem(
                                  icon: Icons.email,
                                  label: 'Email',
                                  value: user.email,
                                ),
                                const Divider(),
                                _buildInfoItem(
                                  icon: Icons.phone,
                                  label: 'Téléphone',
                                  value: user.phone ?? 'Non renseigné',
                                ),
                                const Divider(),
                                _buildInfoItem(
                                  icon: Icons.cake,
                                  label: 'Date de naissance',
                                  value: user.birthDate != null 
                                      ? '${user.birthDate!.day}/${user.birthDate!.month}/${user.birthDate!.year}'
                                      : 'Non renseignée',
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: AppButton(
                                    text: 'Modifier mes informations',
                                    onPressed: () {
                                      // Naviguer vers la page d'édition du profil
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const SettingsScreen(),
                                        ),
                                      ).then((_) {
                                        // Rafraîchir les données au retour
                                        _loadUserData();
                                      });
                                    },
                                    type: AppButtonType.outline,
                                    size: AppButtonSize.medium,
                                    icon: Icons.edit,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section des statistiques physiques
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Statistiques physiques',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    AppButton(
                                      text: 'Détails',
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => const StatsScreen(),
                                          ),
                                        );
                                      },
                                      type: AppButtonType.text,
                                      size: AppButtonSize.small,
                                      icon: Icons.arrow_forward,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildStatItem(
                                      icon: Icons.monitor_weight,
                                      label: 'Poids',
                                      value: user.weight != null ? '${user.weight!.toStringAsFixed(1)} kg' : 'N/A',
                                      backgroundColor: Colors.blue.shade50,
                                      iconColor: Colors.blue,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.speed,
                                      label: 'Endurance',
                                      value: '${user.endurance}/100',
                                      backgroundColor: Colors.orange.shade50,
                                      iconColor: Colors.orange,
                                    ),
                                    _buildStatItem(
                                      icon: Icons.fitness_center,
                                      label: 'Force',
                                      value: '${user.strength}/100',
                                      backgroundColor: Colors.red.shade50,
                                      iconColor: Colors.red,
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 16),
                                Center(
                                  child: AppButton(
                                    text: 'Mettre à jour mes statistiques',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const StatsScreen(),
                                        ),
                                      ).then((_) {
                                        // Rafraîchir les données au retour
                                        _loadUserData();
                                      });
                                    },
                                    type: AppButtonType.outline,
                                    size: AppButtonSize.medium,
                                    icon: Icons.update,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section achievements/succès
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Succès débloqués',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Liste des succès
                                if (user.achievements.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Vous n\'avez pas encore de succès débloqués',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                else
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: user.achievements.map((achievement) {
                                      return _buildAchievementBadge(achievement);
                                    }).toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section admin (seulement pour les administrateurs)
                        if (user.role == AppConstants.roleAdmin)
                          Card(
                            elevation: 4,
                            color: Colors.amber.shade50,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.admin_panel_settings,
                                        color: Colors.amber.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Fonctionnalités administrateur',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    text: 'Tableau de bord administrateur',
                                    onPressed: () {
                                      // Naviguer vers le tableau de bord administrateur
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => const AdminDashboardScreen(), // À implémenter
                                        ),
                                      );
                                    },
                                    type: AppButtonType.primary,
                                    size: AppButtonSize.medium,
                                    fullWidth: true,
                                    icon: Icons.dashboard,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                        const SizedBox(height: 24),
                        
                        // Bouton de déconnexion
                        AppButton(
                          text: 'Se déconnecter',
                          onPressed: _logout,
                          type: AppButtonType.outline,
                          size: AppButtonSize.large,
                          fullWidth: true,
                          icon: Icons.logout,
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  // Widget pour afficher un élément d'information personnel
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey[600],
            size: 22,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Widget pour afficher une statistique
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget pour afficher un badge d'accomplissement
  Widget _buildAchievementBadge(String achievement) {
    // Nous pourrions personnaliser les badges en fonction de l'accomplissement
    // Pour l'instant, on crée un badge générique
    IconData iconData;
    Color color;
    
    // Attribuer différentes icônes et couleurs selon le type d'accomplissement
    if (achievement.contains('poids')) {
      iconData = Icons.monitor_weight;
      color = Colors.green;
    } else if (achievement.contains('niveau')) {
      iconData = Icons.arrow_upward;
      color = Colors.purple;
    } else if (achievement.contains('défi')) {
      iconData = Icons.emoji_events;
      color = Colors.amber;
    } else if (achievement.contains('cours')) {
      iconData = Icons.school;
      color = Colors.blue;
    } else if (achievement.contains('routine')) {
      iconData = Icons.fitness_center;
      color = Colors.red;
    } else {
      iconData = Icons.star;
      color = Colors.orange;
    }
    
    return Tooltip(
      message: achievement,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              iconData,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.length > 20 ? '${achievement.substring(0, 17)}...' : achievement,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Classe d'écran placeholder pour le tableau de bord administrateur
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord Admin'),
      ),
      body: const Center(
        child: Text('Tableau de bord administrateur'),
      ),
    );
  }
}
                              