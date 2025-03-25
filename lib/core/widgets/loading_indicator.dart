import 'package:flutter/material.dart';

/// Un indicateur de chargement personnalisé pour l'application Sunday Sport Club.
///
/// Ce widget peut être utilisé partout où une opération asynchrone est en cours,
/// avec différentes tailles et options d'affichage.
class LoadingIndicator extends StatelessWidget {
  /// Taille de l'indicateur de chargement
  final double size;
  
  /// Couleur de l'indicateur (si null, utilise la couleur primaire du thème)
  final Color? color;
  
  /// Épaisseur de la ligne de l'indicateur
  final double strokeWidth;
  
  /// Texte optionnel à afficher sous l'indicateur
  final String? message;
  
  /// Détermine si l'indicateur est au centre de son parent
  final bool center;
  
  /// Détermine si l'arrière-plan doit être semi-transparent
  final bool overlay;

  const LoadingIndicator({
    Key? key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
    this.message,
    this.center = true,
    this.overlay = false,
  }) : super(key: key);

  /// Crée un indicateur de chargement en plein écran avec un arrière-plan semi-transparent
  factory LoadingIndicator.fullScreen({
    Color backgroundColor = Colors.black45,
    String? message,
    Color? color,
  }) {
    return LoadingIndicator(
      size: 60.0,
      color: color,
      strokeWidth: 6.0,
      message: message,
      center: true,
      overlay: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = color ?? Theme.of(context).colorScheme.primary;
    
    // Contenu de base de l'indicateur avec ou sans message
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            strokeWidth: strokeWidth,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 16.0),
          Text(
            message!,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w500,
              color: overlay ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
    
    // Centrer l'indicateur si demandé
    if (center) {
      content = Center(child: content);
    }
    
    // Ajouter un overlay si demandé
    if (overlay) {
      return Stack(
        children: [
          // Background semi-transparent
          Positioned.fill(
            child: Container(
              color: Colors.black45,
            ),
          ),
          // Conteneur pour améliorer la visibilité de l'indicateur sur l'overlay
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: content,
            ),
          ),
        ],
      );
    }
    
    return content;
  }
}

/// Extension du LoadingIndicator pour les widgets
extension LoadingOverlay on Widget {
  /// Ajoute un overlay de chargement sur ce widget si isLoading est true
  Widget withLoadingOverlay({
    required bool isLoading,
    String? message,
    Color? color,
  }) {
    return Stack(
      children: [
        this,
        if (isLoading)
          Positioned.fill(
            child: LoadingIndicator.fullScreen(
              message: message,
              color: color,
            ),
          ),
      ],
    );
  }
}