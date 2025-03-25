/// Classe contenant les constantes globales de l'application Sunday Sport Club
class AppConstants {
  // Empêcher l'instanciation de cette classe
  AppConstants._();
  
  // Informations générales de l'application
  static const String appName = 'Sunday Sport Club';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Application de suivi sportif et coaching';
  
  // Configuration de l'interface utilisateur
  static const double defaultPadding = 16.0;
  static const double borderRadius = 8.0;
  static const double animationDuration = 300; // en millisecondes
  
  // Limites et règles business
  static const int minAgeLimit = 16; // Âge minimum pour s'inscrire
  static const int maxAgeLimit = 80; // Âge maximum pour s'inscrire
  static const int minPasswordLength = 6; // Longueur minimale du mot de passe
  static const int defaultSessionDuration = 60; // Durée de session en minutes
  static const int sessionExpirationDays = 30; // Durée de validité d'une carte
  
  // Niveaux et avancement
  static const int xpPerLevel = 100; // Points d'XP nécessaires par niveau
  static const int xpForCompletedRoutine = 25; // XP gagnée par routine terminée
  static const int xpForDailyChallenge = 15; // XP gagnée par défi quotidien
  static const int minLevelForMediumAvatar = 10; // Niveau pour avatar moyen
  static const int minLevelForMuscleAvatar = 30; // Niveau pour avatar musclé
  
  // Textes des niveaux avatar
  static const String avatarStageThin = 'mince';
  static const String avatarStageMedium = 'moyen';
  static const String avatarStageMuscular = 'muscle';
  
  // Valeurs pour les genres
  static const String genderMale = 'homme';
  static const String genderFemale = 'femme';
  
  // Valeurs pour les couleurs de peau
  static const String skinColorWhite = 'blanc';
  static const String skinColorMixed = 'metisse';
  static const String skinColorBlack = 'noir';
  
  // Types de cartes de coaching
  static const String membershipTypeIndividual = 'individuel';
  static const String membershipTypeCollective = 'collectif';
  
  // États des réservations
  static const String bookingStatusConfirmed = 'confirmé';
  static const String bookingStatusCancelled = 'annulé';
  static const String bookingStatusCompleted = 'terminé';
  
  // Rôles utilisateur
  static const String roleAdmin = 'admin';
  static const String roleUser = 'user';
  
  // Messages d'erreur communs
  static const String errorNetworkMessage = 'Problème de connexion internet';
  static const String errorSessionExpired = 'Votre session a expiré, veuillez vous reconnecter';
  static const String errorInvalidCredentials = 'Email ou mot de passe incorrect';
  static const String errorPermissionDenied = 'Vous n\'avez pas les droits nécessaires';
  static const String errorUnexpected = 'Une erreur inattendue est survenue';
  
  // Messages de succès
  static const String successProfileUpdated = 'Profil mis à jour avec succès';
  static const String successBookingConfirmed = 'Réservation confirmée';
  static const String successRoutineCompleted = 'Routine terminée avec succès !';
  static const String successChallengeCompleted = 'Défi terminé avec succès !';
  
  // Chemins d'assets
  static const String assetsAvatarsPath = 'assets/avatars/';
  static const String assetsImagesPath = 'assets/images/';
  static const String assetsFontsPath = 'assets/fonts/';
  static const String assetsLogoPath = 'assets/images/logo.png';
  
  // Clés de stockage local
  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeyLastLogin = 'last_login';
  static const String storageKeyCompletedChallenges = 'completed_challenges';
}