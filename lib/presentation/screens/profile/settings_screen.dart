import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/datasources/supabase/shared_prefs_helper.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../auth/password_reset_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  // Paramètres de l'application
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  
  // Paramètres de confidentialité
  bool _shareProgressEnabled = true;
  bool _participateInRankings = true;
  
  // Paramètres d'entraînement
  String _difficultyLevel = 'Intermédiaire';
  String _workoutReminder = 'Chaque jour';
  
  // Gestionnaire d'initialisation
  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Initialiser SharedPreferences
      await SharedPrefsHelper.init();
      
      // Charger les préférences
      setState(() {
        _isDarkMode = SharedPrefsHelper.getIsDarkMode();
        _notificationsEnabled = SharedPrefsHelper.getNotificationsEnabled();
        
        // Dans une implémentation réelle, ces valeurs seraient également chargées depuis le stockage
        _shareProgressEnabled = true;
        _participateInRankings = true;
        _difficultyLevel = 'Intermédiaire';
        _workoutReminder = 'Chaque jour';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des préférences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  // Sauvegarder les paramètres
  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Sauvegarder dans SharedPreferences
      await SharedPrefsHelper.setIsDarkMode(_isDarkMode);
      await SharedPrefsHelper.setNotificationsEnabled(_notificationsEnabled);
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres sauvegardés avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sauvegarde des préférences: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Déconnexion
  Future<void> _logout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      // Rediriger vers l'écran de connexion
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la déconnexion: $e';
        _isLoading = false;
      });
    }
  }
  
  // Réinitialiser tous les paramètres
  Future<void> _resetSettings() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser les paramètres?'),
        content: const Text(
          'Cette action rétablira tous les paramètres à leurs valeurs par défaut. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                // Réinitialiser les paramètres
                _isDarkMode = false;
                _notificationsEnabled = true;
                _shareProgressEnabled = true;
                _participateInRankings = true;
                _difficultyLevel = 'Intermédiaire';
                _workoutReminder = 'Chaque jour';
                
                // Sauvegarder les valeurs par défaut
                await _savePreferences();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Paramètres réinitialisés avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                setState(() {
                  _errorMessage = 'Erreur lors de la réinitialisation: $e';
                });
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Enregistrer les modifications',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement des paramètres...')
          : Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                
                if (user == null) {
                  return const Center(
                    child: Text('Veuillez vous connecter pour accéder à cette page'),
                  );
                }
                
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Afficher les messages d'erreur s'il y en a
                        if (_errorMessage != null) ...[
                          ErrorDisplay(
                            message: _errorMessage!,
                            type: ErrorType.general,
                            actionLabel: 'Réessayer',
                            onAction: _loadPreferences,
                          ),
                          const SizedBox(height: 16),
                        ],
                        
                        // Section du compte utilisateur
                        _buildSectionHeader('Compte utilisateur', Icons.person),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.email),
                                title: const Text('Adresse email'),
                                subtitle: Text(user.email),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Modifier le profil'),
                                subtitle: const Text('Nom, prénom, téléphone...'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Navigation vers l'écran de modification du profil
                                  // Dans une implémentation réelle, cette navigation serait implémentée
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fonctionnalité à implémenter'),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.password),
                                title: const Text('Changer le mot de passe'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const PasswordResetScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section des paramètres de l'application
                        _buildSectionHeader('Paramètres de l\'application', Icons.settings),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Mode sombre'),
                                subtitle: const Text('Activer le thème sombre pour l\'application'),
                                value: _isDarkMode,
                                onChanged: (value) {
                                  setState(() {
                                    _isDarkMode = value;
                                  });
                                },
                                secondary: const Icon(Icons.brightness_4),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: const Text('Notifications'),
                                subtitle: const Text('Recevoir des notifications push'),
                                value: _notificationsEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _notificationsEnabled = value;
                                  });
                                },
                                secondary: const Icon(Icons.notifications),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.language),
                                title: const Text('Langue'),
                                subtitle: const Text('Français'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Ouvrir le sélecteur de langue
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fonctionnalité à implémenter'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section Confidentialité et sécurité
                        _buildSectionHeader('Confidentialité et sécurité', Icons.security),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                title: const Text('Partager mes progrès'),
                                subtitle: const Text('Permettre aux autres utilisateurs de voir votre évolution'),
                                value: _shareProgressEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _shareProgressEnabled = value;
                                  });
                                },
                                secondary: const Icon(Icons.share),
                              ),
                              const Divider(height: 1),
                              SwitchListTile(
                                title: const Text('Participer aux classements'),
                                subtitle: const Text('Apparaître dans les classements publics'),
                                value: _participateInRankings,
                                onChanged: (value) {
                                  setState(() {
                                    _participateInRankings = value;
                                    
                                    // Si l'utilisateur désactive les classements, désactiver aussi le partage des progrès
                                    if (!value) {
                                      _shareProgressEnabled = false;
                                    }
                                  });
                                },
                                secondary: const Icon(Icons.leaderboard),
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.policy),
                                title: const Text('Politique de confidentialité'),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () {
                                  // Ouvrir la politique de confidentialité
                                  // Utiliserait url_launcher dans une implémentation réelle
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fonctionnalité à implémenter'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section Préférences d'entraînement
                        _buildSectionHeader('Préférences d\'entraînement', Icons.fitness_center),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.signal_cellular_alt),
                                title: const Text('Niveau de difficulté'),
                                subtitle: Text(_difficultyLevel),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Ouvrir un sélecteur de niveau de difficulté
                                  _showDifficultyPicker();
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.alarm),
                                title: const Text('Rappels d\'entraînement'),
                                subtitle: Text(_workoutReminder),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Ouvrir un sélecteur de fréquence des rappels
                                  _showReminderPicker();
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Section Aide et support
                        _buildSectionHeader('Aide et support', Icons.help),
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.question_answer),
                                title: const Text('Foire aux questions'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Naviguer vers la FAQ
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fonctionnalité à implémenter'),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.contact_support),
                                title: const Text('Contacter le support'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Ouvrir la page de contact
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Fonctionnalité à implémenter'),
                                    ),
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(Icons.info),
                                title: const Text('À propos'),
                                subtitle: Text('Version ${AppConstants.appVersion}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  // Afficher les informations sur l'application
                                  _showAboutDialog();
                                },
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Boutons d'action
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Réinitialiser les paramètres',
                                onPressed: _resetSettings,
                                type: AppButtonType.outline,
                                icon: Icons.restore,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppButton(
                                text: 'Déconnexion',
                                onPressed: _logout,
                                type: AppButtonType.primary,
                                icon: Icons.logout,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Option de suppression du compte
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Afficher une boîte de dialogue de confirmation
                              _showDeleteAccountConfirmation();
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Supprimer mon compte'),
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  
  // Sélecteur de niveau de difficulté
  void _showDifficultyPicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Niveau de difficulté'),
        children: [
          'Débutant',
          'Intermédiaire',
          'Avancé',
          'Expert',
        ].map((level) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              _difficultyLevel = level;
            });
            Navigator.pop(context);
          },
          child: Text(level),
        )).toList(),
      ),
    );
  }
  
  // Sélecteur de fréquence des rappels
  void _showReminderPicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Rappels d\'entraînement'),
        children: [
          'Chaque jour',
          'Jours ouvrables',
          'Week-ends uniquement',
          'Trois fois par semaine',
          'Une fois par semaine',
          'Jamais',
        ].map((frequency) => SimpleDialogOption(
          onPressed: () {
            setState(() {
              _workoutReminder = frequency;
            });
            Navigator.pop(context);
          },
          child: Text(frequency),
        )).toList(),
      ),
    );
  }
  
  // Afficher la boîte de dialogue "À propos"
  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: 'Version ${AppConstants.appVersion}',
      applicationIcon: Image.asset(
        'assets/images/logo1.png',
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 50,
            height: 50,
            color: Colors.blue.shade100,
            child: const Icon(Icons.sports_martial_arts, color: Colors.blue),
          );
        },
      ),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
            AppConstants.appDescription,
            textAlign: TextAlign.center,
          ),
        ),
        const Text(
          '© 2023 Sunday Sport Club. Tous droits réservés.',
          style: TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // Confirmation de suppression de compte
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte?'),
        content: const Text(
          'Cette action est irréversible. Toutes vos données seront définitivement supprimées. Êtes-vous sûr de vouloir continuer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              // Dans une implémentation réelle, nous appellerions un service pour supprimer le compte
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité à implémenter'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
  
  // Widget pour l'en-tête de section
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}