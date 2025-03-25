/// Fichier contenant les exceptions personnalisées pour l'application Sunday Sport Club.
/// Ces exceptions permettent une gestion plus précise et plus typée des erreurs.
library;

/// Exception de base pour toutes les exceptions de l'application
/// Toutes les autres exceptions héritent de celle-ci pour permettre
/// un traitement unifié des erreurs.
class AppException implements Exception {
  /// Message explicatif de l'erreur
  final String message;
  
  /// Code d'erreur optionnel pour catégoriser les erreurs
  final String? code;
  
  /// Erreur technique sous-jacente qui a causé cette exception
  final Object? cause;

  const AppException(this.message, {this.code, this.cause});

  @override
  String toString() => 'AppException: [$code] $message${cause != null ? ' (Cause: $cause)' : ''}';
}

/// Exception liée à l'authentification (login, signup, etc.)
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Utilisateur non trouvé
  factory AuthException.userNotFound() => const AuthException(
    'Utilisateur non trouvé.',
    code: 'auth/user-not-found',
  );
  
  /// Identifiants incorrects
  factory AuthException.invalidCredentials() => const AuthException(
    'Email ou mot de passe incorrect.',
    code: 'auth/invalid-credentials',
  );
  
  /// Email déjà utilisé
  factory AuthException.emailAlreadyInUse() => const AuthException(
    'Cet email est déjà utilisé par un autre compte.',
    code: 'auth/email-already-in-use',
  );
  
  /// Mot de passe faible
  factory AuthException.weakPassword() => const AuthException(
    'Le mot de passe doit contenir au moins 6 caractères.',
    code: 'auth/weak-password',
  );
  
  /// Email mal formaté
  factory AuthException.invalidEmail() => const AuthException(
    'Format d\'email invalide.',
    code: 'auth/invalid-email',
  );
  
  /// Session expirée
  factory AuthException.sessionExpired() => const AuthException(
    'Votre session a expiré, veuillez vous reconnecter.',
    code: 'auth/session-expired',
  );
  
  /// Utilisateur désactivé
  factory AuthException.userDisabled() => const AuthException(
    'Ce compte a été désactivé.',
    code: 'auth/user-disabled',
  );
}

/// Exception liée au réseau (connexion Internet, timeout, etc.)
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Pas de connexion Internet
  factory NetworkException.noConnection() => const NetworkException(
    'Pas de connexion Internet.',
    code: 'network/no-connection',
  );
  
  /// Timeout de requête
  factory NetworkException.timeout() => const NetworkException(
    'La requête a pris trop de temps. Veuillez réessayer.',
    code: 'network/timeout',
  );
  
  /// Erreur serveur
  factory NetworkException.serverError({int? statusCode, Object? cause}) => NetworkException(
    'Erreur serveur${statusCode != null ? ' (code $statusCode)' : ''}.',
    code: 'network/server-error',
    cause: cause,
  );
}

/// Exception liée à la base de données (Supabase, SQLite, etc.)
class DatabaseException extends AppException {
  const DatabaseException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Erreur de lecture
  factory DatabaseException.readError({Object? cause}) => DatabaseException(
    'Erreur lors de la lecture des données.',
    code: 'db/read-error',
    cause: cause,
  );
  
  /// Erreur d'écriture
  factory DatabaseException.writeError({Object? cause}) => DatabaseException(
    'Erreur lors de l\'enregistrement des données.',
    code: 'db/write-error',
    cause: cause,
  );
  
  /// Données non trouvées
  factory DatabaseException.notFound({String? entity}) => DatabaseException(
    '${entity ?? 'Donnée'} non trouvée.',
    code: 'db/not-found',
  );
  
  /// Données en doublon
  factory DatabaseException.duplicate({String? entity}) => DatabaseException(
    '${entity ?? 'Donnée'} en doublon.',
    code: 'db/duplicate',
  );
  
  /// Contrainte de clé étrangère violée
  factory DatabaseException.foreignKeyConstraint({Object? cause}) => DatabaseException(
    'Contrainte de référence violée.',
    code: 'db/foreign-key-constraint',
    cause: cause,
  );
  
  /// Erreur de transaction
  factory DatabaseException.transactionFailed({Object? cause}) => DatabaseException(
    'La transaction a échoué.',
    code: 'db/transaction-failed',
    cause: cause,
  );
}

/// Exception liée à la validation des données (formulaires, etc.)
class ValidationException extends AppException {
  /// Map contenant les champs en erreur avec leurs messages
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.cause,
  });
  
  /// Champ requis manquant
  factory ValidationException.requiredField(String fieldName) => ValidationException(
    'Le champ $fieldName est requis.',
    fieldErrors: {fieldName: 'Ce champ est requis.'},
    code: 'validation/required-field',
  );
  
  /// Format invalide
  factory ValidationException.invalidFormat(String fieldName, String format) => ValidationException(
    'Le format de $fieldName est invalide. Format attendu: $format',
    fieldErrors: {fieldName: 'Format invalide. Format attendu: $format'},
    code: 'validation/invalid-format',
  );
  
  /// Valeur hors limites
  factory ValidationException.outOfRange(String fieldName, {dynamic min, dynamic max}) {
    String errorMsg = 'Valeur hors limites.';
    if (min != null && max != null) {
      errorMsg = 'La valeur doit être entre $min et $max.';
    } else if (min != null) {
      errorMsg = 'La valeur doit être supérieure à $min.';
    } else if (max != null) {
      errorMsg = 'La valeur doit être inférieure à $max.';
    }
    
    return ValidationException(
      'Le champ $fieldName est $errorMsg',
      fieldErrors: {fieldName: errorMsg},
      code: 'validation/out-of-range',
    );
  }
  
  /// Plusieurs erreurs de validation
  factory ValidationException.multiple(Map<String, String> fieldErrors) => ValidationException(
    'Plusieurs champs contiennent des erreurs.',
    fieldErrors: fieldErrors,
    code: 'validation/multiple-errors',
  );
}

/// Exception liée aux permissions/autorisations
class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Accès refusé
  factory PermissionException.accessDenied() => const PermissionException(
    'Vous n\'avez pas les droits nécessaires pour effectuer cette action.',
    code: 'permission/access-denied',
  );
  
  /// Rôle insuffisant
  factory PermissionException.insufficientRole(String requiredRole) => PermissionException(
    'Cette action nécessite le rôle: $requiredRole.',
    code: 'permission/insufficient-role',
  );
  
  /// Propriétaire uniquement
  factory PermissionException.ownerOnly() => const PermissionException(
    'Seul le propriétaire peut effectuer cette action.',
    code: 'permission/owner-only',
  );
  
  /// Connexion requise
  factory PermissionException.loginRequired() => const PermissionException(
    'Vous devez être connecté pour effectuer cette action.',
    code: 'permission/login-required',
  );
}

/// Exception liée aux fonctionnalités non implémentées
class NotImplementedException extends AppException {
  const NotImplementedException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Constructeur par défaut
  factory NotImplementedException.feature(String featureName) => NotImplementedException(
    'La fonctionnalité "$featureName" n\'est pas encore implémentée.',
    code: 'not-implemented',
  );
}

/// Exception liée au paiement (Stripe, etc.)
class PaymentException extends AppException {
  const PaymentException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Carte refusée
  factory PaymentException.cardDeclined() => const PaymentException(
    'Votre carte a été refusée.',
    code: 'payment/card-declined',
  );
  
  /// Fonds insuffisants
  factory PaymentException.insufficientFunds() => const PaymentException(
    'Fonds insuffisants.',
    code: 'payment/insufficient-funds',
  );
  
  /// Erreur de traitement
  factory PaymentException.processingError({Object? cause}) => PaymentException(
    'Erreur lors du traitement du paiement.',
    code: 'payment/processing-error',
    cause: cause,
  );
  
  /// Paiement déjà effectué
  factory PaymentException.alreadyPaid() => const PaymentException(
    'Ce paiement a déjà été effectué.',
    code: 'payment/already-paid',
  );
}

/// Exception liée au stockage (upload/download de fichiers)
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.cause,
  });
  
  /// Erreur d'upload
  factory StorageException.uploadFailed({Object? cause}) => StorageException(
    'Échec lors de l\'envoi du fichier.',
    code: 'storage/upload-failed',
    cause: cause,
  );
  
  /// Erreur de download
  factory StorageException.downloadFailed({Object? cause}) => StorageException(
    'Échec lors du téléchargement du fichier.',
    code: 'storage/download-failed',
    cause: cause,
  );
  
  /// Taille de fichier dépassée
  factory StorageException.fileTooLarge(int maxSizeInMB) => StorageException(
    'Le fichier dépasse la taille maximale autorisée ($maxSizeInMB MB).',
    code: 'storage/file-too-large',
  );
  
  /// Format de fichier non supporté
  factory StorageException.unsupportedFileType(String fileType, List<String> supportedTypes) => StorageException(
    'Le format de fichier $fileType n\'est pas supporté. Formats acceptés: ${supportedTypes.join(', ')}.',
    code: 'storage/unsupported-file-type',
  );
}