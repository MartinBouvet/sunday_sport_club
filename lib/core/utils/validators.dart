import '../constants/app_constants.dart';

/// Utilitaires de validation pour les formulaires et entrées utilisateur
/// 
/// Cette classe fournit des méthodes statiques pour valider différents types de données
/// et retourne des messages d'erreur appropriés ou null si la validation réussit.
class Validators {
  // Constructeur privé pour empêcher l'instanciation
  Validators._();
  
  // Expression régulière pour valider un email
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  
  // Expression régulière pour valider un numéro de téléphone français
  static final RegExp _phoneRegex = RegExp(
    r'^(?:(?:\+|00)33|0)\s*[1-9](?:[\s.-]*\d{2}){4}$',
  );
  
  // Expression régulière pour valider un code postal français
  static final RegExp _zipCodeRegex = RegExp(
    r'^[0-9]{5}$',
  );
  
  // Expression régulière pour valider un mot de passe fort
  // Doit contenir au moins 8 caractères, une majuscule, une minuscule et un chiffre
  static final RegExp _strongPasswordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d\w\W]{8,}$',
  );
  
  /// Valide si une chaîne n'est pas vide
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null 
          ? 'Le champ $fieldName est requis.' 
          : 'Ce champ est requis.';
    }
    return null;
  }
  
  /// Valide si une chaîne est un email valide
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? email(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier le format de l'email
    if (!_emailRegex.hasMatch(value!)) {
      return 'Veuillez entrer une adresse email valide.';
    }
    
    return null;
  }
  
  /// Valide si une chaîne est un numéro de téléphone français valide
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? phone(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Normaliser et vérifier le format du téléphone
    final normalizedPhone = value!.replaceAll(RegExp(r'[\s.-]'), '');
    if (!_phoneRegex.hasMatch(normalizedPhone)) {
      return 'Veuillez entrer un numéro de téléphone valide.';
    }
    
    return null;
  }
  
  /// Valide si une chaîne est un code postal français valide
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? zipCode(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier le format du code postal
    if (!_zipCodeRegex.hasMatch(value!)) {
      return 'Veuillez entrer un code postal valide (5 chiffres).';
    }
    
    return null;
  }
  
  /// Valide si une chaîne respecte une longueur minimale
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? minLength(String? value, int minLength, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier la longueur minimale
    if (value!.length < minLength) {
      return 'Ce champ doit contenir au moins $minLength caractère${minLength > 1 ? 's' : ''}.';
    }
    
    return null;
  }
  
  /// Valide si une chaîne respecte une longueur maximale
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? maxLength(String? value, int maxLength) {
    if (value != null && value.length > maxLength) {
      return 'Ce champ ne doit pas dépasser $maxLength caractère${maxLength > 1 ? 's' : ''}.';
    }
    
    return null;
  }
  
  /// Valide si une chaîne est un mot de passe respectant les critères minimaux
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? password(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier la longueur minimale
    if (value!.length < AppConstants.minPasswordLength) {
      return 'Le mot de passe doit contenir au moins ${AppConstants.minPasswordLength} caractères.';
    }
    
    return null;
  }
  
  /// Valide si une chaîne est un mot de passe fort
  /// 
  /// Retourne null si valide, sinon un message d'erreur détaillé
  static String? strongPassword(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier les critères de complexité
    final List<String> errors = [];
    
    if (value!.length < 8) {
      errors.add('au moins 8 caractères');
    }
    
    if (!value.contains(RegExp(r'[A-Z]'))) {
      errors.add('une lettre majuscule');
    }
    
    if (!value.contains(RegExp(r'[a-z]'))) {
      errors.add('une lettre minuscule');
    }
    
    if (!value.contains(RegExp(r'[0-9]'))) {
      errors.add('un chiffre');
    }
    
    if (errors.isNotEmpty) {
      return 'Le mot de passe doit contenir ${errors.join(', ')}.';
    }
    
    return null;
  }
  
  /// Valide si deux chaînes sont identiques (ex: confirmation de mot de passe)
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? mustMatch(String? value, String? valueToMatch, {String fieldName = 'Les champs'}) {
    if (value != valueToMatch) {
      return '$fieldName ne correspondent pas.';
    }
    
    return null;
  }
  
  /// Valide si une valeur est un nombre
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? isNumeric(String? value, {bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier si la valeur est un nombre
    if (num.tryParse(value!) == null) {
      return 'Veuillez entrer un nombre valide.';
    }
    
    return null;
  }
  
  /// Valide si un nombre est dans une plage donnée
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? numberRange(String? value, {double? min, double? max, bool required = true}) {
    // Vérifier si le champ est requis
    if (required) {
      final requiredError = Validators.required(value);
      if (requiredError != null) return requiredError;
    } else if (value == null || value.isEmpty) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier si la valeur est un nombre
    final numValue = num.tryParse(value!);
    if (numValue == null) {
      return 'Veuillez entrer un nombre valide.';
    }
    
    // Vérifier la plage
    if (min != null && max != null) {
      if (numValue < min || numValue > max) {
        return 'La valeur doit être comprise entre $min et $max.';
      }
    } else if (min != null) {
      if (numValue < min) {
        return 'La valeur doit être supérieure ou égale à $min.';
      }
    } else if (max != null) {
      if (numValue > max) {
        return 'La valeur doit être inférieure ou égale à $max.';
      }
    }
    
    return null;
  }
  
  /// Valide si une date est dans une plage donnée
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? dateRange(DateTime? value, {DateTime? minDate, DateTime? maxDate, bool required = true}) {
    // Vérifier si le champ est requis
    if (required && value == null) {
      return 'Une date est requise.';
    } else if (!required && value == null) {
      return null; // Champ optionnel vide
    }
    
    // Vérifier la plage de dates
    if (minDate != null && maxDate != null) {
      if (value!.isBefore(minDate) || value.isAfter(maxDate)) {
        return 'La date doit être comprise entre le ${minDate.day}/${minDate.month}/${minDate.year} et le ${maxDate.day}/${maxDate.month}/${maxDate.year}.';
      }
    } else if (minDate != null) {
      if (value!.isBefore(minDate)) {
        return 'La date doit être postérieure au ${minDate.day}/${minDate.month}/${minDate.year}.';
      }
    } else if (maxDate != null) {
      if (value!.isAfter(maxDate)) {
        return 'La date doit être antérieure au ${maxDate.day}/${maxDate.month}/${maxDate.year}.';
      }
    }
    
    return null;
  }
  
  /// Valide l'âge à partir d'une date de naissance
  /// 
  /// Retourne null si valide, sinon un message d'erreur
  static String? ageLimit(DateTime? birthDate, {int? minAge, int? maxAge, bool required = true}) {
    // Vérifier si le champ est requis
    if (required && birthDate == null) {
      return 'La date de naissance est requise.';
    } else if (!required && birthDate == null) {
      return null; // Champ optionnel vide
    }
    
    // Calculer l'âge
    final today = DateTime.now();
    int age = today.year - birthDate!.year;
    final birthdayThisYear = DateTime(today.year, birthDate.month, birthDate.day);
    
    if (birthdayThisYear.isAfter(today)) {
      age--;
    }
    
    // Vérifier les limites d'âge
    if (minAge != null && maxAge != null) {
      if (age < minAge || age > maxAge) {
        return 'L\'âge doit être compris entre $minAge et $maxAge ans.';
      }
    } else if (minAge != null) {
      if (age < minAge) {
        return 'Vous devez avoir au moins $minAge ans.';
      }
    } else if (maxAge != null) {
      if (age > maxAge) {
        return 'Vous devez avoir au maximum $maxAge ans.';
      }
    }
    
    return null;
  }
  
  /// Combinaison de plusieurs validateurs
  /// 
  /// Exécute les validateurs dans l'ordre et retourne la première erreur trouvée
  static String? compose(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    
    return null;
  }
}