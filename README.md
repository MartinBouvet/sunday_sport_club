# sunday_sport_club

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Architecture 
# Architecture du projet Sunday Sport Club

## Structure des répertoires

```
ssc_app/
│
├── android/                # Configuration Android
├── ios/                    # Configuration iOS
├── web/                    # Configuration Web (optionnel)
│
├── assets/                 # Ressources statiques
│   ├── fonts/              # Polices personnalisées
│   ├── images/             # Images génériques
│   │   └── logo.png        
│   └── avatars/            # Images des avatars
│       ├── homme_blanc_mince.png
│       ├── homme_blanc_moyen.png
│       ├── homme_blanc_muscle.png
│       └── ... (18 variantes au total)
│
├── lib/                    # Code source principal
│   ├── main.dart           # Point d'entrée de l'application
│   │
│   ├── config/             # Configuration de l'application
│   ├── core/               # Fonctionnalités de base partagées
│   ├── data/               # Couche d'accès aux données
│   ├── domain/             # Logique métier
│   └── presentation/       # Interface utilisateur
│
├── test/                   # Tests unitaires et d'intégration
└── pubspec.yaml            # Configuration du projet et dépendances
```

## Détail des modules

### 1. Configuration (`config/`)

```
config/
├── routes.dart             # Configuration des routes
├── themes.dart             # Thèmes de l'application
└── firebase_options.dart   # Configuration Firebase
```

### 2. Core (`core/`)

```
core/
├── constants/              # Constantes de l'application
│   ├── app_constants.dart  # Constantes générales
│   └── api_constants.dart  # URLs et endpoints
│
├── errors/                 # Gestion des erreurs
│   └── exceptions.dart     # Exceptions personnalisées
│
├── utils/                  # Utilitaires
│   ├── date_utils.dart     # Manipulation des dates
│   ├── validators.dart     # Validateurs (formulaires)
│   └── constants.dart      # Constantes (couleurs, styles)
│
└── widgets/                # Widgets réutilisables
    ├── app_button.dart     # Bouton personnalisé
    ├── app_text_field.dart # Champ texte personnalisé
    ├── loading_indicator.dart  # Indicateur de chargement
    ├── avatar_display.dart # Affichage de l'avatar
    └── error_display.dart  # Affichage des erreurs
```

### 3. Data (`data/`)

```
data/
├── models/                 # Modèles de données
│   ├── user.dart           # Modèle utilisateur
│   ├── course.dart         # Modèle cours
│   ├── booking.dart        # Modèle réservation
│   ├── membership_card.dart  # Modèle carnet de coaching
│   ├── exercise.dart       # Modèle exercice
│   ├── routine.dart        # Modèle routine
│   ├── user_routine.dart   # Modèle routine utilisateur
│   ├── daily_challenge.dart  # Modèle défi quotidien
│   ├── user_challenge.dart   # Modèle défi utilisateur
│   ├── progress_tracking.dart  # Modèle suivi progression
│   └── payment.dart        # Modèle paiement
│
├── repositories/           # Repositories (gestion des données)
│   ├── user_repository.dart      # Gestion utilisateurs
│   ├── course_repository.dart    # Gestion cours
│   ├── booking_repository.dart   # Gestion réservations
│   ├── membership_repository.dart  # Gestion carnets
│   ├── exercise_repository.dart  # Gestion exercices
│   ├── routine_repository.dart   # Gestion routines
│   ├── challenge_repository.dart # Gestion défis
│   ├── progress_repository.dart  # Gestion progression
│   └── payment_repository.dart   # Gestion paiements
│
└── datasources/            # Sources de données
    ├── firebase/           # Implémentation Firebase
    │   ├── firebase_user_datasource.dart
    │   ├── firebase_course_datasource.dart
    │   └── ...
    │
    └── local/              # Stockage local
        ├── shared_prefs_helper.dart
        └── local_storage_helper.dart
```

### 4. Domain (`domain/`)

```
domain/
└── services/               # Services métier
    ├── auth_service.dart          # Service d'authentification
    ├── user_service.dart          # Service utilisateur
    ├── course_service.dart        # Service cours
    ├── booking_service.dart       # Service réservation
    ├── gamification_service.dart  # Service gamification
    ├── progress_service.dart      # Service progression
    ├── notification_service.dart  # Service notifications
    └── payment_service.dart       # Service paiements
```

### 5. Presentation (`presentation/`)

```
presentation/
├── providers/              # État global (Provider)
│   ├── user_provider.dart       # Provider utilisateur
│   ├── auth_provider.dart       # Provider authentification
│   ├── booking_provider.dart    # Provider réservation
│   ├── routine_provider.dart    # Provider routines
│   ├── challenge_provider.dart  # Provider défis
│   └── progress_provider.dart   # Provider progression
│
├── screens/                # Écrans de l'application
│   ├── auth/               # Authentification
│   │   ├── login_screen.dart          # Écran connexion
│   │   ├── signup_screen.dart         # Écran inscription
│   │   └── password_reset_screen.dart # Réinitialisation mdp
│   │
│   ├── home/               # Accueil
│   │   ├── home_screen.dart           # Écran d'accueil
│   │   ├── avatar_customization_screen.dart  # Customisation avatar
│   │   └── leaderboard_screen.dart    # Classement
│   │
│   ├── profile/            # Profil
│   │   ├── profile_screen.dart        # Écran profil
│   │   ├── stats_screen.dart          # Statistiques
│   │   └── settings_screen.dart       # Paramètres
│   │
│   ├── courses/            # Cours
│   │   ├── course_list_screen.dart    # Liste des cours
│   │   ├── course_detail_screen.dart  # Détail cours
│   │   └── booking_screen.dart        # Réservation
│   │
│   ├── routines/           # Routines
│   │   ├── routines_screen.dart       # Liste routines
│   │   ├── routine_detail_screen.dart # Détail routine
│   │   └── routine_execution_screen.dart  # Exécution routine
│   │
│   ├── challenges/         # Défis
│   │   ├── challenges_screen.dart     # Liste défis
│   │   ├── challenge_detail_screen.dart  # Détail défi
│   │   └── challenge_validation_screen.dart  # Validation défi
│   │
│   ├── membership/         # Carnets de coaching
│   │   ├── membership_screen.dart     # Gestion carnets
│   │   └── payment_screen.dart        # Paiement
│   │
│   └── admin/              # Administration (coach)
│       ├── admin_dashboard.dart       # Tableau de bord admin
│       ├── member_management_screen.dart  # Gestion membres
│       ├── course_management_screen.dart  # Gestion cours
│       ├── routine_validation_screen.dart  # Validation routines
│       └── payment_management_screen.dart  # Gestion paiements
│
└── widgets/                # Widgets spécifiques aux écrans
    ├── home/               # Widgets écran d'accueil
    │   ├── welcome_card.dart          # Carte de bienvenue
    │   ├── stats_card.dart            # Carte statistiques
    │   ├── menu_card.dart             # Carte menu
    │   └── daily_challenge_card.dart  # Carte défi quotidien
    │
    ├── profile/            # Widgets profil
    ├── courses/            # Widgets cours
    ├── routines/           # Widgets routines
    └── admin/              # Widgets admin
```

## Dépendances principales

### UI et affichage
- `flutter_svg`: Affichage de graphiques vectoriels
- `cached_network_image`: Chargement et mise en cache d'images
- `google_fonts`: Polices Google
- `flutter_spinkit`: Indicateurs de chargement
- `percent_indicator`: Affichage de progression

### Gestion d'état
- `provider`: Gestion d'état basée sur le modèle Observer
- `shared_preferences`: Stockage local de données simples

### Firebase
- `firebase_core`: Fonctionnalités de base Firebase
- `firebase_auth`: Authentification
- `cloud_firestore`: Base de données NoSQL
- `firebase_storage`: Stockage de fichiers
- `firebase_messaging`: Notifications push

### Paiement
- `flutter_stripe`: Intégration de Stripe pour les paiements

### Visualisation des données
- `fl_chart`: Graphiques et visualisations
- `syncfusion_flutter_charts`: Composants de graphiques avancés

### Animation
- `lottie`: Animations complexes au format Lottie
- `animations`: API d'animations Flutter

### Autres utilitaires
- `intl`: Internationalisation et formatage
- `url_launcher`: Ouverture d'URLs
- `image_picker`: Sélection d'images
- `logger`: Journalisation structurée

## Structure des modèles de données

### User (Utilisateur)
```dart
class User {
  String id;                // ID unique de l'utilisateur
  String email;             // Email de l'utilisateur
  String firstName;         // Prénom
  String lastName;          // Nom
  String phone;             // Numéro de téléphone
  DateTime birthDate;       // Date de naissance
  String gender;            // Genre (homme/femme)
  String skinColor;         // Couleur de peau (blanc/métisse/noir)
  bool isActive;            // Statut actif/inactif
  String role;              // Rôle (admin/user)
  
  // Informations de progression
  int level;                // Niveau actuel
  int experiencePoints;     // Points d'expérience
  String avatarStage;       // Stade de l'avatar (mince/moyen/musclé)
  
  // Statistiques physiques
  double weight;            // Poids actuel
  int endurance;            // Niveau d'endurance
  int strength;             // Niveau de force
}
```

### MembershipCard (Carnet de coaching)
```dart
class MembershipCard {
  String id;                // ID unique du carnet
  String userId;            // ID de l'utilisateur propriétaire
  String type;              // Type (individuel/collectif)
  int totalSessions;        // Nombre total de séances (ex: 10)
  int remainingSessions;    // Séances restantes
  DateTime purchaseDate;    // Date d'achat
  DateTime expiryDate;      // Date d'expiration
  double price;             // Prix payé
  String paymentStatus;     // Statut du paiement
}
```

### DailyChallenge (Défi quotidien)
```dart
class DailyChallenge {
  String id;                // ID unique du défi
  String title;             // Titre du défi
  String description;       // Description
  int experiencePoints;     // Points d'expérience gagnés
  DateTime date;            // Date du défi
  List<String> exerciseIds; // IDs des exercices liés au défi
}
```
