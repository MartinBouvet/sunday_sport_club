import 'package:flutter/material.dart';

/// Widget affichant une carte de bienvenue pour l'utilisateur.
///
/// Affiche le nom de l'utilisateur, son niveau actuel, et sa progression
/// vers le niveau suivant sous forme de barre de progression.
class WelcomeCard extends StatelessWidget {
  /// Nom complet de l'utilisateur
  final String userName;
  
  /// Niveau actuel de l'utilisateur
  final int level;
  
  /// Progression en pourcentage vers le niveau suivant (0.0 à 1.0)
  final double progressPercentage;
  
  /// Points d'expérience actuels
  final int experiencePoints;
  
  /// Points d'expérience requis pour le niveau suivant
  final int nextLevelXP;

  /// Constructeur du widget WelcomeCard
  const WelcomeCard({
    Key? key,
    required this.userName,
    required this.level,
    required this.progressPercentage,
    required this.experiencePoints,
    required this.nextLevelXP,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcul des points d'expérience restants pour le prochain niveau
    final remainingXP = nextLevelXP - experiencePoints;
    
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
            // En-tête avec salutation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bonjour,',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Badge de niveau
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Niveau $level',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barre de progression
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progression',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$experiencePoints/$nextLevelXP XP',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progressPercentage.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    minHeight: 10,
                    color: _getProgressColor(context, level),
                  ),
                ),
                const SizedBox(height: 8),
                if (remainingXP > 0)
                  Text(
                    'Encore ${remainingXP}XP pour niveau ${level + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (remainingXP <= 0)
                  Text(
                    'Félicitations ! Vous pouvez passer au niveau ${level + 1} !',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            
            // Petit message motivationnel en bas de la carte
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildMotivationalMessage(context, level, progressPercentage),
          ],
        ),
      ),
    );
  }

  /// Détermine la couleur de la barre de progression en fonction du niveau
  Color _getProgressColor(BuildContext context, int level) {
    // Palette de couleurs évoluant selon le niveau
    if (level < 5) {
      return Colors.blue; // Niveaux débutants
    } else if (level < 10) {
      return Colors.green; // Niveaux intermédiaires
    } else if (level < 15) {
      return Colors.orange; // Niveaux avancés
    } else {
      return Colors.purple; // Niveaux experts
    }
  }

  /// Construit un message motivationnel basé sur le niveau et la progression
  Widget _buildMotivationalMessage(BuildContext context, int level, double progressPercentage) {
    String message;
    IconData icon;
    
    // Messages différents selon la progression et le niveau
    if (progressPercentage >= 0.9) {
      message = "Plus qu'un petit effort pour le niveau suivant !";
      icon = Icons.emoji_events;
    } else if (progressPercentage >= 0.7) {
      message = "Vous progressez très bien, continuez !";
      icon = Icons.trending_up;
    } else if (progressPercentage >= 0.3) {
      message = "Relevez de nouveaux défis pour progresser !";
      icon = Icons.fitness_center;
    } else {
      message = "Chaque entraînement vous rapproche de vos objectifs !";
      icon = Icons.directions_run;
    }
    
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}