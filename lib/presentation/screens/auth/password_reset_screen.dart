import 'package:flutter/material.dart';
import '../../../core/widgets/ app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../domain/services/auth_service.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({Key? key}) : super(key: key);

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _resetSent = false;
  String? _errorMessage;

  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Cacher le clavier
      FocusScope.of(context).unfocus();

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Envoyer l'email de réinitialisation
        await _authService.resetPassword(_emailController.text.trim());
        
        // Marquer comme envoyé si aucune erreur
        setState(() {
          _resetSent = true;
          _isLoading = false;
        });
      } catch (e) {
        // Gérer l'erreur
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mot de passe oublié'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const LoadingIndicator(
              center: true,
              message: 'Envoi en cours...',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _resetSent ? _buildSuccessView() : _buildResetForm(),
            ),
    );
  }

  // Vue du formulaire de réinitialisation
  Widget _buildResetForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icône et titre
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: Colors.blue,
          ),
          const SizedBox(height: 24),
          const Text(
            'Réinitialisation du mot de passe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Entrez votre adresse email et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 32),

          // Champ d'email
          AppTextField(
            label: 'Email',
            controller: _emailController,
            hintText: 'Entrez votre adresse email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email,
            validator: Validators.email,
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Bouton d'envoi
          AppButton(
            text: 'Envoyer le lien de réinitialisation',
            onPressed: _resetPassword,
            type: AppButtonType.primary,
            size: AppButtonSize.large,
            fullWidth: true,
          ),
          const SizedBox(height: 16),

          // Message d'erreur
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // Vue de succès après envoi
  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        const Text(
          'Email envoyé !',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Un lien de réinitialisation a été envoyé à ${_emailController.text}. Veuillez vérifier votre boîte de réception et suivre les instructions.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 32),
        AppButton(
          text: 'Retour à la connexion',
          onPressed: () {
            Navigator.of(context).pop();
          },
          type: AppButtonType.outline,
          size: AppButtonSize.medium,
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _resetSent = false;
            });
          },
          child: const Text('Réessayer avec une autre adresse'),
        ),
      ],
    );
  }
}