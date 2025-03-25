import 'package:flutter/material.dart';

/// Widget d'affichage d'erreur pour l'application Sunday Sport Club.
///
/// Ce widget permet d'afficher différents types d'erreurs de manière
/// cohérente dans toute l'application, avec des options de style et
/// des actions possibles.
class ErrorDisplay extends StatelessWidget {
  /// Message d'erreur principal à afficher
  final String message;
  
  /// Message détaillé optionnel (affichable/masquable)
  final String? details;
  
  /// Type d'erreur déterminant l'apparence
  final ErrorType type;
  
  /// Icône personnalisée (si null, utilise l'icône par défaut du type d'erreur)
  final IconData? icon;
  
  /// Action principale optionnelle (texte du bouton)
  final String? actionLabel;
  
  /// Fonction appelée si l'action principale est pressée
  final VoidCallback? onAction;
  
  /// Action secondaire optionnelle (ex: réessayer)
  final String? secondaryActionLabel;
  
  /// Fonction appelée si l'action secondaire est pressée
  final VoidCallback? onSecondaryAction;
  
  /// Détermine si l'erreur doit occuper tout l'espace disponible
  final bool fullScreen;

  const ErrorDisplay({
    Key? key,
    required this.message,
    this.details,
    this.type = ErrorType.general,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.fullScreen = false,
  }) : super(key: key);

  /// Crée un affichage d'erreur de connexion réseau avec action "Réessayer"
  factory ErrorDisplay.network({
    String message = 'Problème de connexion',
    String? details,
    VoidCallback? onRetry,
    bool fullScreen = false,
  }) {
    return ErrorDisplay(
      message: message,
      details: details,
      type: ErrorType.network,
      actionLabel: 'Réessayer',
      onAction: onRetry,
      fullScreen: fullScreen,
    );
  }

  /// Crée un affichage d'erreur "Pas de données" avec action personnalisable
  factory ErrorDisplay.noData({
    String message = 'Aucune donnée disponible',
    String? actionLabel,
    VoidCallback? onAction,
    bool fullScreen = false,
  }) {
    return ErrorDisplay(
      message: message,
      type: ErrorType.noData,
      actionLabel: actionLabel,
      onAction: onAction,
      fullScreen: fullScreen,
    );
  }

  /// Crée un affichage d'erreur de permission avec message personnalisé
  factory ErrorDisplay.permission({
    String message = 'Accès non autorisé',
    String? details,
    String? actionLabel,
    VoidCallback? onAction,
    bool fullScreen = false,
  }) {
    return ErrorDisplay(
      message: message,
      details: details,
      type: ErrorType.permission,
      actionLabel: actionLabel,
      onAction: onAction,
      fullScreen: fullScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Déterminer l'icône et la couleur selon le type d'erreur
    IconData errorIcon;
    Color errorColor;
    
    switch (type) {
      case ErrorType.general:
        errorIcon = Icons.error_outline;
        errorColor = theme.colorScheme.error;
        break;
      case ErrorType.network:
        errorIcon = Icons.wifi_off;
        errorColor = Colors.orange;
        break;
      case ErrorType.noData:
        errorIcon = Icons.inbox;
        errorColor = Colors.grey;
        break;
      case ErrorType.permission:
        errorIcon = Icons.lock;
        errorColor = Colors.red;
        break;
      case ErrorType.validation:
        errorIcon = Icons.warning_amber;
        errorColor = Colors.amber;
        break;
    }
    
    // Utiliser l'icône personnalisée si fournie
    final displayIcon = icon ?? errorIcon;
    
    // Contenu principal de l'affichage d'erreur
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icône
        Icon(
          displayIcon,
          size: 64,
          color: errorColor,
        ),
        const SizedBox(height: 16),
        
        // Message principal
        Text(
          message,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        // Message détaillé si disponible
        if (details != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () {
              // Afficher une boîte de dialogue avec les détails
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Détails de l\'erreur'),
                    content: SingleChildScrollView(
                      child: Text(details!),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Fermer'),
                      ),
                    ],
                  );
                },
              );
            },
            child: Text(
              'Voir les détails',
              style: TextStyle(
                color: theme.colorScheme.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 24),
        
        // Boutons d'action si disponibles
        if (actionLabel != null || secondaryActionLabel != null)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (secondaryActionLabel != null)
                OutlinedButton(
                  onPressed: onSecondaryAction,
                  child: Text(secondaryActionLabel!),
                ),
              if (actionLabel != null && secondaryActionLabel != null)
                const SizedBox(width: 16),
              if (actionLabel != null)
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: errorColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(actionLabel!),
                ),
            ],
          ),
      ],
    );
    
    // Si plein écran, centrer le contenu avec un padding
    if (fullScreen) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: content,
        ),
      );
    }
    
    // Sinon, simplement retourner le contenu avec padding
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: content,
    );
  }
}

/// Types d'erreur supportés par le widget ErrorDisplay
enum ErrorType {
  /// Erreur générale (par défaut)
  general,
  
  /// Erreur de connexion réseau
  network,
  
  /// Aucune donnée disponible
  noData,
  
  /// Problème de permission/autorisation
  permission,
  
  /// Erreur de validation de formulaire
  validation,
}

/// Extension pour afficher facilement une erreur en tant que Scaffold
extension ErrorScaffold on ErrorDisplay {
  /// Transforme cet affichage d'erreur en un Scaffold complet
  Widget asScaffold({
    String title = 'Erreur',
    bool showAppBar = true,
    Color? backgroundColor,
  }) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: showAppBar ? AppBar(title: Text(title)) : null,
          body: this,
        );
      },
    );
  }
}