import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'signup_screen.dart';
import 'password_reset_screen.dart';
import '../home/home_screen.dart';
import '../../../core/widgets/ app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_indicator.dart';

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

      // Si la connexion réussit, naviguer vers l'écran d'accueil
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Container(
              padding: const EdgeInsets.all(24.0),
              height: MediaQuery.of(context).size.height,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 60),
                    // Logo et titre
                    Center(
                      child: Image.asset(
                        'assets/images/logo1.png',
                        height: 160,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sports_martial_arts,
                              size: 80,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sunday Sport Club',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
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
                    const SizedBox(height: 48),

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
                    const SizedBox(height: 20),

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
                          activeColor: Colors.blue,
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
                    const SizedBox(height: 32),

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
                    const Spacer(),

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
            ),
          );
        },
      ),
    );
  }
}