import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Champ de texte personnalisé pour l'application Sunday Sport Club.
///
/// Ce widget encapsule un TextField avec une apparence cohérente
/// et des fonctionnalités supplémentaires comme les validations.
class AppTextField extends StatefulWidget {
  /// Label affiché au-dessus du champ
  final String label;
  
  /// Texte d'aide affiché sous le champ
  final String? hintText;
  
  /// Contrôleur pour accéder et manipuler le texte du champ
  final TextEditingController controller;
  
  /// Type de clavier à afficher (email, téléphone, etc.)
  final TextInputType keyboardType;
  
  /// Fonction de validation du contenu (retourne un message d'erreur ou null)
  final String? Function(String?)? validator;
  
  /// Indique si le champ est obligatoire
  final bool isRequired;
  
  /// Indique si le champ est en lecture seule
  final bool readOnly;
  
  /// Indique si le texte doit être masqué (pour les mots de passe)
  final bool obscureText;
  
  /// Icône affichée à gauche du champ
  final IconData? prefixIcon;
  
  /// Icône affichée à droite du champ (ou action supplémentaire)
  final Widget? suffixIcon;
  
  /// Nombre maximal de caractères
  final int? maxLength;
  
  /// Formatage du texte pendant la saisie
  final List<TextInputFormatter>? inputFormatters;
  
  /// Fonction appelée lorsque le texte change
  final Function(String)? onChanged;
  
  /// Fonction appelée lorsque le champ perd le focus
  final Function(String)? onFieldSubmitted;

  const AppTextField({
    Key? key,
    required this.label,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isRequired = false,
    this.readOnly = false,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLength,
    this.inputFormatters,
    this.onChanged,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _hasError = false;
  String? _errorText;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Appliquer la validation si fournie
    String? validateField(String? value) {
      if (widget.isRequired && (value == null || value.isEmpty)) {
        return 'Ce champ est obligatoire';
      }
      
      if (widget.validator != null) {
        return widget.validator!(value);
      }
      
      return null;
    }
    
    // Construire la bordure du champ
    OutlineInputBorder buildBorder(Color color, double width) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: color, width: width),
      );
    }
    
    // Déterminer la couleur de la bordure et du label
    Color borderColor = _hasError 
        ? theme.colorScheme.error 
        : (_isFocused 
            ? theme.colorScheme.primary 
            : theme.disabledColor);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec indicateur requis si nécessaire
        Row(
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
            if (widget.isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: theme.colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8.0),
        
        // Champ de texte
        Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              _isFocused = hasFocus;
              
              // Valider à la perte de focus
              if (!hasFocus) {
                final error = validateField(widget.controller.text);
                _hasError = error != null;
                _errorText = error;
              }
            });
          },
          child: TextFormField(
            controller: widget.controller,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscureText,
            readOnly: widget.readOnly,
            maxLength: widget.maxLength,
            inputFormatters: widget.inputFormatters,
            onChanged: (value) {
              if (widget.onChanged != null) {
                widget.onChanged!(value);
              }
              
              // Vérifier si l'erreur disparaît
              if (_hasError) {
                final error = validateField(value);
                setState(() {
                  _hasError = error != null;
                  _errorText = error;
                });
              }
            },
            onFieldSubmitted: (value) {
              final error = validateField(value);
              setState(() {
                _hasError = error != null;
                _errorText = error;
              });
              
              if (widget.onFieldSubmitted != null) {
                widget.onFieldSubmitted!(value);
              }
            },
            validator: validateField,
            style: TextStyle(
              fontSize: 16,
              color: widget.readOnly 
                  ? theme.disabledColor 
                  : theme.textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              filled: true,
              fillColor: widget.readOnly 
                  ? theme.disabledColor.withOpacity(0.1) 
                  : Colors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0, 
                vertical: 14.0,
              ),
              prefixIcon: widget.prefixIcon != null 
                  ? Icon(widget.prefixIcon, color: borderColor) 
                  : null,
              suffixIcon: widget.suffixIcon,
              errorText: _hasError ? _errorText : null,
              border: buildBorder(theme.disabledColor, 1.0),
              focusedBorder: buildBorder(theme.colorScheme.primary, 2.0),
              enabledBorder: buildBorder(theme.disabledColor, 1.0),
              errorBorder: buildBorder(theme.colorScheme.error, 1.0),
              focusedErrorBorder: buildBorder(theme.colorScheme.error, 2.0),
              counterText: widget.maxLength != null ? '' : null,
            ),
          ),
        ),
      ],
    );
  }
}