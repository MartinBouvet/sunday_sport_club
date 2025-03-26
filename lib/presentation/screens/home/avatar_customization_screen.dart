import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';

class AvatarCustomizationScreen extends StatefulWidget {
  const AvatarCustomizationScreen({Key? key}) : super(key: key);

  @override
  State<AvatarCustomizationScreen> createState() => _AvatarCustomizationScreenState();
}

class _AvatarCustomizationScreenState extends State<AvatarCustomizationScreen> with SingleTickerProviderStateMixin {
  String _selectedSkinColor = '';
  String _selectedGender = '';
  String _selectedStage = '';
  bool _isLoading = false;
  bool _isEditing = false;
  
  // Pour l'animation
  late TabController _tabController;
  final List<String> _stages = [
    AppConstants.avatarStageThin,
    AppConstants.avatarStageMedium,
    AppConstants.avatarStageMuscular,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      setState(() {
        _selectedSkinColor = user.skinColor;
        _selectedGender = user.gender;
        _selectedStage = user.avatarStage;
        
        // Initialise le tab controller sur la bonne position
        int index = _stages.indexOf(_selectedStage);
        if (index != -1) {
          _tabController.animateTo(index);
        }
      });
    }
  }

  Future<void> _updateAvatar() async {
    if (!_isEditing) return;
    
    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    try {
      // Mettre à jour le profil utilisateur avec les nouvelles valeurs
      if (authProvider.currentUser != null) {
        await userProvider.updateUserProfile(
          userId: authProvider.currentUser!.id,
          gender: _selectedGender,
          skinColor: _selectedSkinColor,
        );
        
        // Si l'utilisateur est admin ou a un niveau suffisant, on peut aussi changer l'étape de l'avatar
        final user = authProvider.currentUser!;
        if (user.role == AppConstants.roleAdmin || user.level >= AppConstants.minLevelForMediumAvatar) {
          await userProvider.updateAvatarStage(
            userId: user.id,
            stage: _selectedStage,
          );
        }
        
        // Rafraîchir les données utilisateur
        await authProvider.refreshUserData();
        
        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isEditing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personnalisation de l\'avatar'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updateAvatar,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading || _isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Chargement...',
            );
          }

          final user = authProvider.currentUser;
          if (user == null) {
            return const Center(
              child: Text('Veuillez vous connecter pour accéder à cette page'),
            );
          }

          bool canChangeStage = user.role == AppConstants.roleAdmin || user.level >= AppConstants.minLevelForMediumAvatar;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section avatar preview
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text(
                          'Aperçu de votre avatar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Avatar display
                        AvatarDisplay(
                          gender: _selectedGender,
                          skinColor: _selectedSkinColor,
                          stage: _selectedStage,
                          size: 200,
                          showBorder: true,
                          borderWidth: 3.0,
                        ),
                        const SizedBox(height: 16),
                        
                        // Nom de l'utilisateur et niveau
                        Text(
                          '${user.firstName} ${user.lastName}',
                          style: const TextStyle(
                            fontSize: 20,
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
                        
                        // Bouton d'édition
                        if (!_isEditing)
                          AppButton(
                            text: 'Modifier l\'avatar',
                            onPressed: () {
                              setState(() {
                                _isEditing = true;
                              });
                            },
                            type: AppButtonType.primary,
                            size: AppButtonSize.medium,
                            icon: Icons.edit,
                          ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Options de personnalisation
                if (_isEditing)
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
                            'Personnalisation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Genre
                          const Text(
                            'Genre',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Homme',
                                  icon: Icons.male,
                                  isSelected: _selectedGender == AppConstants.genderMale,
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = AppConstants.genderMale;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Femme',
                                  icon: Icons.female,
                                  isSelected: _selectedGender == AppConstants.genderFemale,
                                  onTap: () {
                                    setState(() {
                                      _selectedGender = AppConstants.genderFemale;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          // Couleur de peau
                          const Text(
                            'Couleur de peau',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Blanc',
                                  icon: Icons.face,
                                  iconColor: Colors.pink[100],
                                  isSelected: _selectedSkinColor == AppConstants.skinColorWhite,
                                  onTap: () {
                                    setState(() {
                                      _selectedSkinColor = AppConstants.skinColorWhite;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Métisse',
                                  icon: Icons.face,
                                  iconColor: Colors.brown[300],
                                  isSelected: _selectedSkinColor == AppConstants.skinColorMixed,
                                  onTap: () {
                                    setState(() {
                                      _selectedSkinColor = AppConstants.skinColorMixed;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSelectionCard(
                                  title: 'Noir',
                                  icon: Icons.face,
                                  iconColor: Colors.brown[800],
                                  isSelected: _selectedSkinColor == AppConstants.skinColorBlack,
                                  onTap: () {
                                    setState(() {
                                      _selectedSkinColor = AppConstants.skinColorBlack;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          // Stade avatar (seulement pour admin ou utilisateurs avec niveau suffisant)
                          if (canChangeStage) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Stade d\'évolution',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TabBar(
                              controller: _tabController,
                              onTap: (index) {
                                setState(() {
                                  _selectedStage = _stages[index];
                                });
                              },
                              tabs: const [
                                Tab(text: 'Débutant'),
                                Tab(text: 'Intermédiaire'),
                                Tab(text: 'Avancé'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 120,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Débutant
                                  _buildStageInfo(
                                    'Mince',
                                    'Stade initial - Niveau 1',
                                    'Déverrouillez le stade intermédiaire en atteignant le niveau ${AppConstants.minLevelForMediumAvatar}',
                                    AppConstants.avatarStageThin,
                                  ),
                                  // Intermédiaire
                                  _buildStageInfo(
                                    'Moyen',
                                    'Stade intermédiaire - Niveau ${AppConstants.minLevelForMediumAvatar}+',
                                    'Déverrouillez le stade avancé en atteignant le niveau ${AppConstants.minLevelForMuscleAvatar}',
                                    AppConstants.avatarStageMedium,
                                  ),
                                  // Avancé
                                  _buildStageInfo(
                                    'Musclé',
                                    'Stade avancé - Niveau ${AppConstants.minLevelForMuscleAvatar}+',
                                    'Félicitations ! Vous avez atteint le stade le plus avancé.',
                                    AppConstants.avatarStageMuscular,
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Évolution de l\'avatar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Votre avatar évoluera automatiquement à mesure que vous progressez dans votre parcours sportif.\n\n'
                                    '• Stade intermédiaire: Niveau ${AppConstants.minLevelForMediumAvatar}\n'
                                    '• Stade avancé: Niveau ${AppConstants.minLevelForMuscleAvatar}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Boutons d'action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              AppButton(
                                text: 'Annuler',
                                onPressed: () {
                                  setState(() {
                                    _isEditing = false;
                                    _initUserData(); // Réinitialiser les données
                                  });
                                },
                                type: AppButtonType.outline,
                                size: AppButtonSize.medium,
                              ),
                              const SizedBox(width: 16),
                              AppButton(
                                text: 'Enregistrer',
                                onPressed: _updateAvatar,
                                type: AppButtonType.primary,
                                size: AppButtonSize.medium,
                                isLoading: _isLoading,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Informations sur l'évolution de l'avatar
                if (!_isEditing) ...[
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
                            'Évolution de votre avatar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Progression actuelle
                          LinearProgressIndicator(
                            value: user.level >= AppConstants.minLevelForMuscleAvatar 
                                ? 1.0 
                                : user.level >= AppConstants.minLevelForMediumAvatar
                                  ? 0.66
                                  : (user.level / AppConstants.minLevelForMediumAvatar) * 0.33,
                            minHeight: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              user.level >= AppConstants.minLevelForMuscleAvatar
                                  ? Colors.purple
                                  : user.level >= AppConstants.minLevelForMediumAvatar
                                      ? Colors.orange
                                      : Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // Les étapes d'évolution
                          _buildEvolutionStage(
                            'Débutant',
                            'Niveau 1-${AppConstants.minLevelForMediumAvatar - 1}',
                            AppConstants.avatarStageThin,
                            user.avatarStage == AppConstants.avatarStageThin,
                            Colors.blue,
                            isCompleted: user.level >= 1,
                          ),
                          _buildEvolutionStage(
                            'Intermédiaire',
                            'Niveau ${AppConstants.minLevelForMediumAvatar}-${AppConstants.minLevelForMuscleAvatar - 1}',
                            AppConstants.avatarStageMedium,
                            user.avatarStage == AppConstants.avatarStageMedium,
                            Colors.orange,
                            isCompleted: user.level >= AppConstants.minLevelForMediumAvatar,
                          ),
                          _buildEvolutionStage(
                            'Avancé',
                            'Niveau ${AppConstants.minLevelForMuscleAvatar}+',
                            AppConstants.avatarStageMuscular,
                            user.avatarStage == AppConstants.avatarStageMuscular,
                            Colors.purple,
                            isCompleted: user.level >= AppConstants.minLevelForMuscleAvatar,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Conseils pour progresser
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
                            'Comment progresser plus vite ?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProgressTip('Complétez les défis quotidiens', Icons.flash_on, Colors.amber),
                          _buildProgressTip('Assistez régulièrement aux cours', Icons.event_available, Colors.blue),
                          _buildProgressTip('Terminez vos routines hebdomadaires', Icons.fitness_center, Colors.green),
                          _buildProgressTip('Atteignez vos objectifs de performance', Icons.trending_up, Colors.purple),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget pour afficher une carte de sélection
  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : (iconColor ?? Colors.grey),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour afficher les informations d'un stade d'avatar
  Widget _buildStageInfo(String title, String subtitle, String description, String stage) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedStage == stage 
            ? Colors.blue.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _selectedStage == stage
            ? Border.all(color: Colors.blue)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _selectedStage == stage
                  ? const Icon(Icons.check_circle, color: Colors.blue, size: 18)
                  : const Icon(Icons.circle_outlined, color: Colors.grey, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _selectedStage == stage ? Colors.blue : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedStage == stage ? Colors.blue.shade700 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget pour afficher une étape d'évolution
  Widget _buildEvolutionStage(
    String title,
    String subtitle,
    String stage,
    bool isCurrentStage,
    Color color, {
    required bool isCompleted,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur d'étape
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? color : Colors.grey.shade300,
                border: Border.all(
                  color: isCurrentStage ? Colors.blue : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? color : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Contenu de l'étape
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? color : Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isCompleted ? Colors.black87 : Colors.grey,
                ),
              ),
              if (isCurrentStage)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'Niveau actuel',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        // Petit aperçu d'avatar
        if (isCompleted)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: AvatarDisplay(
              gender: _selectedGender,
              skinColor: _selectedSkinColor,
              stage: stage,
              size: 40,
              showBorder: isCurrentStage,
              borderColor: isCurrentStage ? Colors.blue : null,
            ),
          ),
      ],
    );
  }

  // Widget pour afficher un conseil de progression
  Widget _buildProgressTip(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
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
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}