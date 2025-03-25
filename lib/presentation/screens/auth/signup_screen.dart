import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../../core/widgets/ app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/constants/app_constants.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedGender = AppConstants.genderMale;
  String _selectedSkinColor = AppConstants.skinColorWhite;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() ?? false) {
      // Masquer le clavier
      FocusScope.of(context).unfocus();

      // Récupérer l'AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Tenter l'inscription
      final success = await authProvider.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        gender: _selectedGender,
        skinColor: _selectedSkinColor,
      );

      // Si l'inscription réussit, retourner à l'écran de connexion
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inscription réussie !'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          // Afficher un indicateur de chargement pendant l'inscription
          if (authProvider.isLoading) {
            return const LoadingIndicator(
              center: true,
              message: 'Création de votre compte...',
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  
                  // Logo et titre
                  Center(
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.sports_martial_arts,
                            size: 60,
                            color: Colors.blue,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Titre
                  const Text(
                    'Créer un compte',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rejoignez la communauté Sunday Sport Club pour commencer votre parcours sportif',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Champs pour prénom et nom
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          label: 'Prénom',
                          controller: _firstNameController,
                          hintText: 'Votre prénom',
                          validator: (value) => Validators.required(
                            value,
                            fieldName: 'Prénom',
                          ),
                          isRequired: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppTextField(
                          label: 'Nom',
                          controller: _lastNameController,
                          hintText: 'Votre nom',
                          validator: (value) => Validators.required(
                            value,
                            fieldName: 'Nom',
                          ),
                          isRequired: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Champ d'email
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    hintText: 'Votre adresse email',
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
                    hintText: 'Choisissez un mot de passe',
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

                  // Champ de confirmation de mot de passe
                  AppTextField(
                    label: 'Confirmer le mot de passe',
                    controller: _confirmPasswordController,
                    hintText: 'Confirmez votre mot de passe',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    validator: (value) => Validators.mustMatch(
                      value,
                      _passwordController.text,
                      fieldName: 'Les mots de passe',
                    ),
                    isRequired: true,
                  ),
                  const SizedBox(height: 24),

                  // Sélection du genre
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Genre',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectionCard(
                              title: 'Homme',
                              icon: Icons.man,
                              isSelected: _selectedGender == AppConstants.genderMale,
                              onTap: () {
                                setState(() {
                                  _selectedGender = AppConstants.genderMale;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSelectionCard(
                              title: 'Femme',
                              icon: Icons.woman,
                              isSelected: _selectedGender == AppConstants.genderFemale,
                              onTap: () {
                                setState(() {
                                  _selectedGender = AppConstants.genderFemale;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sélection de la couleur de peau
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Couleur de peau (pour l\'avatar)',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSelectionCard(
                              title: 'Blanc',
                              icon: Icons.face,
                              iconColor: Colors.pink[100],
                              isSelected: _selectedSkinColor == AppConstants.skinColorWhite,
                              onTap: () {
                                setState(() {
                                  _selectedSkinColor = AppConstants.skinColorWhite;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectionCard(
                              title: 'Métisse',
                              icon: Icons.face,
                              iconColor: Colors.brown[300],
                              isSelected: _selectedSkinColor == AppConstants.skinColorMixed,
                              onTap: () {
                                setState(() {
                                  _selectedSkinColor = AppConstants.skinColorMixed;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildSelectionCard(
                              title: 'Noir',
                              icon: Icons.face,
                              iconColor: Colors.brown[800],
                              isSelected: _selectedSkinColor == AppConstants.skinColorBlack,
                              onTap: () {
                                setState(() {
                                  _selectedSkinColor = AppConstants.skinColorBlack;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Bouton d'inscription
                  AppButton(
                    text: 'S\'inscrire',
                    onPressed: _register,
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

                  // Lien pour retourner à la page de connexion
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Déjà un compte ?'),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Se connecter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Widget pour les cartes de sélection (genre, couleur de peau)
  Widget _buildSelectionCard({
    required String title,
    required IconData icon,
    Color? iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : (iconColor ?? Colors.grey),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blue : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}