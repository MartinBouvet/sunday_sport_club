import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/widgets/ app_button.dart'; 
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_indicator.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key}); 

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Cacher le clavier
      FocusScope.of(context).unfocus();

      // Récupérer l'AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Tenter la connexion
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Si la connexion réussit, retourner à l'écran d'accueil
      if (success && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        centerTitle: true,
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Afficher un indicateur de chargement pendant la connexion
          if (authProvider.isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Connexion en cours...',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo et titre
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.sports_martial_arts,
                          size: 100,
                          color: Colors.blue,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sunday Sport Club',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Connectez-vous pour accéder à votre espace personnel',
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
                  const SizedBox(height: 16),

                  // Champ de mot de passe
                  AppTextField(
                    label: 'Mot de passe',
                    controller: _passwordController,
                    hintText: 'Entrez votre mot de passe',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    validator: (value) => Validators.minLength(
                      value,
                      6,
                      required: true,
                    ),
                    isRequired: true,
                  ),
                  const SizedBox(height: 16),

                  // Option "Se souvenir de moi"
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                      ),
                      const Text('Se souvenir de moi'),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const PasswordResetScreen(),
                            ),
                          );
                        },
                        child: const Text('Mot de passe oublié ?'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Bouton de connexion
                  AppButton(
                    text: 'Se connecter',
                    onPressed: _login,
                    type: AppButtonType.primary,
                    size: AppButtonSize.large,
                    fullWidth: true,
                    isLoading: authProvider.isLoading,
                  ),
                  const SizedBox(height: 16),

                  // Message d'erreur
                  if (authProvider.errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authProvider.errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Lien vers la page d'inscription
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Pas encore de compte ?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },
                        child: const Text('S\'inscrire'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}