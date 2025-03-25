import 'package:flutter/material.dart';

/// Widget affichant un menu de navigation sous forme de carte.
///
/// Présente les principales sections de l'application sous forme de boutons
/// permettant à l'utilisateur d'accéder rapidement aux fonctionnalités clés.
class MenuCard extends StatelessWidget {
  /// Callback pour la navigation vers l'écran des routines
  final VoidCallback onRoutinesPressed;
  
  /// Callback pour la navigation vers l'écran des cours
  final VoidCallback onCoursesPressed;
  
  /// Callback pour la navigation vers l'écran des défis
  final VoidCallback onChallengesPressed;
  
  /// Callback pour la navigation vers l'écran de gestion des carnets
  final VoidCallback onMembershipPressed;

  /// Constructeur du widget MenuCard
  const MenuCard({
    Key? key,
    required this.onRoutinesPressed,
    required this.onCoursesPressed,
    required this.onChallengesPressed,
    required this.onMembershipPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
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
              'Menu principal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Première rangée d'options
            Row(
              children: [
                // Option Routines
                Expanded(
                  child: _buildMenuOption(
                    context: context,
                    title: 'Routines',
                    icon: Icons.fitness_center,
                    color: Colors.indigo,
                    onPressed: onRoutinesPressed,
                    description: 'Vos exercices',
                  ),
                ),
                const SizedBox(width: 16),
                // Option Cours
                Expanded(
                  child: _buildMenuOption(
                    context: context,
                    title: 'Cours',
                    icon: Icons.event_available,
                    color: Colors.orange,
                    onPressed: onCoursesPressed,
                    description: 'Réservations',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Deuxième rangée d'options
            Row(
              children: [
                // Option Défis
                Expanded(
                  child: _buildMenuOption(
                    context: context,
                    title: 'Défis',
                    icon: Icons.emoji_events,
                    color: Colors.green,
                    onPressed: onChallengesPressed,
                    description: 'Challenges',
                  ),
                ),
                const SizedBox(width: 16),
                // Option Carnets
                Expanded(
                  child: _buildMenuOption(
                    context: context,
                    title: 'Carnets',
                    icon: Icons.card_membership,
                    color: Colors.purple,
                    onPressed: onMembershipPressed,
                    description: 'Abonnements',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construit une option du menu avec titre, icône et action associée
  Widget _buildMenuOption({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String description,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec cercle de fond
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            // Titre de l'option
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Description de l'option
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}