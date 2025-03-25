import 'package:flutter/material.dart';

/// Widget affichant les statistiques principales de l'utilisateur.
///
/// Présente les indicateurs de performance physique: poids actuel avec comparaison
/// au poids initial, niveaux d'endurance et de force avec visualisation graphique.
class StatsCard extends StatelessWidget {
  /// Poids actuel de l'utilisateur en kg
  final double weight;
  
  /// Poids initial de l'utilisateur en kg (pour comparaison)
  final double initialWeight;
  
  /// Niveau d'endurance actuel (échelle 0-100)
  final int endurance;
  
  /// Niveau de force actuel (échelle 0-100)
  final int strength;
  
  /// Callback appelé lorsque l'utilisateur souhaite mettre à jour ses statistiques
  final VoidCallback onUpdatePressed;

  /// Constructeur du widget StatsCard
  const StatsCard({
    Key? key,
    required this.weight,
    required this.initialWeight,
    required this.endurance,
    required this.strength,
    required this.onUpdatePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculer la différence de poids pour affichage
    final weightDifference = weight - initialWeight;
    final weightDifferenceText = weightDifference >= 0 
        ? '+${weightDifference.toStringAsFixed(1)}' 
        : '${weightDifference.toStringAsFixed(1)}';
    final weightDifferenceColor = weightDifference <= 0 
        ? Colors.green  // Perte de poids ou stable (vert)
        : Colors.red;   // Gain de poids (rouge)
    
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
            // En-tête avec titre et bouton de mise à jour
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mes statistiques',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: onUpdatePressed,
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Mettre à jour'),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Affichage du poids actuel et de la différence
            Row(
              children: [
                _buildStatIcon(Icons.monitor_weight, Colors.blue),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Poids actuel',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${weight.toStringAsFixed(1)} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$weightDifferenceText kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: weightDifferenceColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Niveau d'endurance
            Row(
              children: [
                _buildStatIcon(Icons.speed, Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Endurance',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(
                        context: context,
                        value: endurance / 100,
                        color: Colors.orange,
                        showPercentage: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Niveau de force
            Row(
              children: [
                _buildStatIcon(Icons.fitness_center, Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Force',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildProgressBar(
                        context: context,
                        value: strength / 100,
                        color: Colors.red,
                        showPercentage: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Indicateur de niveau de fitness global
            _buildFitnessIndicator(context),
          ],
        ),
      ),
    );
  }

  /// Construit l'icône circulaire pour chaque statistique
  Widget _buildStatIcon(IconData icon, Color color) {
    return Container(
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
    );
  }

  /// Construit une barre de progression avec pourcentage optionnel
  Widget _buildProgressBar({
    required BuildContext context,
    required double value,
    required Color color,
    bool showPercentage = false,
  }) {
    // Garantir que la valeur est bien dans l'intervalle [0,1]
    final clampedValue = value.clamp(0.0, 1.0);
    final percentage = (clampedValue * 100).toInt();
    
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clampedValue,
              backgroundColor: Colors.grey[200],
              color: color,
              minHeight: 8,
            ),
          ),
        ),
        if (showPercentage) ...[
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: percentage >= 70 ? color : Colors.grey[600],
            ),
          ),
        ],
      ],
    );
  }

  /// Construit l'indicateur global de fitness basé sur l'endurance et la force
  Widget _buildFitnessIndicator(BuildContext context) {
    // Calcul du niveau de fitness global (moyenne pondérée)
    final fitnessLevel = (endurance * 0.6 + strength * 0.4) / 100;
    String fitnessLabel;
    Color fitnessColor;
    
    // Déterminer la catégorie de fitness
    if (fitnessLevel >= 0.8) {
      fitnessLabel = 'Excellent';
      fitnessColor = Colors.green[700]!;
    } else if (fitnessLevel >= 0.6) {
      fitnessLabel = 'Bon';
      fitnessColor = Colors.green;
    } else if (fitnessLevel >= 0.4) {
      fitnessLabel = 'Moyen';
      fitnessColor = Colors.orange;
    } else if (fitnessLevel >= 0.2) {
      fitnessLabel = 'À améliorer';
      fitnessColor = Colors.orange[300]!;
    } else {
      fitnessLabel = 'Débutant';
      fitnessColor = Colors.red[300]!;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        const Text(
          'Niveau de fitness global',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildProgressBar(
                context: context,
                value: fitnessLevel,
                color: fitnessColor,
                showPercentage: false,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: fitnessColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: fitnessColor, width: 1),
              ),
              child: Text(
                fitnessLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: fitnessColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}