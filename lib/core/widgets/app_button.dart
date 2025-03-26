import 'package:flutter/material.dart';

/// Widget de bouton personnalisé pour l'application Sunday Sport Club.
/// 
/// Ce bouton offre plusieurs variantes (primaire, secondaire, etc.)
/// et s'adapte automatiquement à différentes tailles.
class AppButton extends StatelessWidget {
  /// Le texte affiché sur le bouton
  final String text;
  
  /// Fonction appelée lorsque le bouton est pressé
  final VoidCallback? onPressed;
  
  /// Style du bouton (primary, secondary, outline, text)
  final AppButtonType type;
  
  /// Taille du bouton (small, medium, large)
  final AppButtonSize size;
  
  /// Indique si le bouton occupe toute la largeur disponible
  final bool fullWidth;
  
  /// Icône optionnelle à afficher avant le texte
  final IconData? icon;
  
  /// Indique si le bouton est en état de chargement
  final bool isLoading;

  const AppButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.type = AppButtonType.primary,
    this.size = AppButtonSize.medium,
    this.fullWidth = false,
    this.icon,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Définir les couleurs et styles en fonction du type de bouton
    Color backgroundColor;
    Color textColor;
    Color borderColor = Colors.transparent;
    
    switch (type) {
      case AppButtonType.primary:
        backgroundColor = theme.colorScheme.primary;
        textColor = Colors.white;
        break;
      case AppButtonType.secondary:
        backgroundColor = theme.colorScheme.secondary;
        textColor = Colors.white;
        break;
      case AppButtonType.outline:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.primary;
        borderColor = theme.colorScheme.primary;
        break;
      case AppButtonType.text:
        backgroundColor = Colors.transparent;
        textColor = theme.colorScheme.primary;
        break;
    }
    
    // Désactiver visuellement le bouton s'il est désactivé ou en chargement
    if (onPressed == null || isLoading) {
      backgroundColor = backgroundColor.withOpacity(0.6);
      textColor = textColor.withOpacity(0.6);
    }
    
    // Définir les dimensions en fonction de la taille du bouton
    double height;
    double fontSize;
    double horizontalPadding;
    double borderRadius;
    
    switch (size) {
      case AppButtonSize.small:
        height = 36.0;
        fontSize = 14.0;
        horizontalPadding = 16.0;
        borderRadius = 6.0;
        break;
      case AppButtonSize.medium:
        height = 48.0;
        fontSize = 16.0;
        horizontalPadding = 24.0;
        borderRadius = 8.0;
        break;
      case AppButtonSize.large:
        height = 56.0;
        fontSize = 18.0;
        horizontalPadding = 32.0;
        borderRadius = 10.0;
        break;
    }
    
    // Construire le contenu du bouton
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                valueColor: AlwaysStoppedAnimation<Color>(textColor),
              ),
            ),
          )
        else if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(icon, color: textColor, size: fontSize + 2),
          ),
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    
    // Construire le bouton avec les paramètres définis
    return Container(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: content,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(backgroundColor),
          foregroundColor: MaterialStateProperty.all(textColor),
          padding: MaterialStateProperty.all(
            EdgeInsets.symmetric(horizontal: horizontalPadding),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: BorderSide(color: borderColor),
            ),
          ),
          elevation: type == AppButtonType.text 
              ? MaterialStateProperty.all(0) 
              : MaterialStateProperty.all(2),
        ),
      ),
    );
  }
}

/// Types de boutons disponibles
enum AppButtonType {
  primary,   // Bouton principal (couleur primaire)
  secondary, // Bouton secondaire
  outline,   // Bouton avec bordure sans fond
  text,      // Bouton texte sans fond ni bordure
}

/// Tailles de boutons disponibles
enum AppButtonSize {
  small,    // Petit bouton
  medium,   // Bouton de taille moyenne (par défaut)
  large,    // Grand bouton
}