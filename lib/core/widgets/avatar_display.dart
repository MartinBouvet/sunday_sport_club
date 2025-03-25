import 'package:flutter/material.dart';

/// Widget d'affichage de l'avatar de l'utilisateur pour l'application Sunday Sport Club.
///
/// Ce widget gère l'affichage de l'avatar de l'utilisateur en fonction de son
/// genre, sa couleur de peau et son stade d'évolution physique.
class AvatarDisplay extends StatelessWidget {
  /// Genre de l'utilisateur ('homme' ou 'femme')
  final String gender;
  
  /// Couleur de peau de l'utilisateur ('blanc', 'metisse', 'noir')
  final String skinColor;
  
  /// Stade d'évolution physique ('mince', 'moyen', 'muscle')
  final String stage;
  
  /// Taille de l'avatar à afficher
  final double size;
  
  /// Si on doit afficher la bordure
  final bool showBorder;
  
  /// Couleur de la bordure (par défaut la couleur primaire du thème)
  final Color? borderColor;
  
  /// Épaisseur de la bordure
  final double borderWidth;
  
  /// Rayon de l'arrondi de l'avatar
  final double borderRadius;
  
  /// Si l'avatar doit être interactif (cliquable)
  final bool interactive;
  
  /// Fonction appelée lors du clic sur l'avatar
  final VoidCallback? onTap;

  const AvatarDisplay({
    Key? key,
    required this.gender,
    required this.skinColor,
    required this.stage,
    this.size = 100.0,
    this.showBorder = true,
    this.borderColor,
    this.borderWidth = 2.0,
    this.borderRadius = 16.0,
    this.interactive = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Valider et normaliser les entrées
    final normalizedGender = _normalizeGender(gender);
    final normalizedSkinColor = _normalizeSkinColor(skinColor);
    final normalizedStage = _normalizeStage(stage);
    
    // Construire le chemin de l'image
    final imagePath = 'assets/avatars/${normalizedGender}_${normalizedSkinColor}_${normalizedStage}.png';
    
    // Créer le widget d'image
    Widget avatarImage = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Afficher un avatar de secours en cas d'erreur
          return Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: Icon(
              Icons.person,
              size: size * 0.6,
              color: Colors.grey.shade400,
            ),
          );
        },
      ),
    );
    
    // Ajouter une bordure si demandé
    if (showBorder) {
      final themeColor = borderColor ?? Theme.of(context).colorScheme.primary;
      
      avatarImage = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: themeColor,
            width: borderWidth,
          ),
        ),
        child: avatarImage,
      );
    }
    
    // Ajouter l'interaction si demandé
    if (interactive) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: avatarImage,
      );
    }
    
    return avatarImage;
  }
  
  // Méthodes utilitaires pour normaliser les entrées
  
  String _normalizeGender(String value) {
    final normalized = value.toLowerCase().trim();
    return ['homme', 'femme'].contains(normalized) ? normalized : 'homme';
  }
  
  String _normalizeSkinColor(String value) {
    final normalized = value.toLowerCase().trim();
    return ['blanc', 'metisse', 'noir'].contains(normalized) 
        ? normalized 
        : 'blanc';
  }
  
  String _normalizeStage(String value) {
    final normalized = value.toLowerCase().trim();
    return ['mince', 'moyen', 'muscle'].contains(normalized) 
        ? normalized 
        : 'mince';
  }
}

/// Widget simplifié pour afficher un badge de niveau autour de l'avatar
class AvatarWithLevel extends StatelessWidget {
  /// L'avatar à afficher
  final AvatarDisplay avatar;
  
  /// Niveau actuel de l'utilisateur
  final int level;
  
  /// Couleur du badge de niveau (par défaut la couleur secondaire du thème)
  final Color? badgeColor;
  
  /// Taille du texte dans le badge
  final double badgeTextSize;

  const AvatarWithLevel({
    Key? key,
    required this.avatar,
    required this.level,
    this.badgeColor,
    this.badgeTextSize = 14.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeColor = badgeColor ?? Theme.of(context).colorScheme.secondary;
    
    return Stack(
      alignment: Alignment.center,
      children: [
        // Avatar
        avatar,
        
        // Badge de niveau
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.white,
                width: 2.0,
              ),
            ),
            child: Text(
              'Nv. $level',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: badgeTextSize,
              ),
            ),
          ),
        ),
      ],
    );
  }
}