import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/user_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  // Contrôleurs pour les champs de texte
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _enduranceController = TextEditingController();
  final TextEditingController _strengthController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  // Variables pour le mode édition
  bool _isEditing = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  // TabController pour les onglets
  late TabController _tabController;
  
  // Valeurs initiales
  double _initialWeight = 0.0;
  int _initialEndurance = 0;
  int _initialStrength = 0;
  
  // Données pour les graphiques
  List<Map<String, dynamic>> _weightHistory = [];
  List<Map<String, dynamic>> _enduranceHistory = [];
  List<Map<String, dynamic>> _strengthHistory = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Charger les données initiales
    _loadUserData();
    
    // Charger l'historique des statistiques
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStatsHistory();
    });
  }
  
  @override
  void dispose() {
    _weightController.dispose();
    _enduranceController.dispose();
    _strengthController.dispose();
    _notesController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  // Chargement des données utilisateur
  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser != null) {
      final user = authProvider.currentUser!;
      
      setState(() {
        // Enregistrer les valeurs initiales
        _initialWeight = user.weight ?? 0.0;
        _initialEndurance = user.endurance;
        _initialStrength = user.strength;
        
        // Initialiser les contrôleurs
        _weightController.text = user.weight?.toString() ?? '';
        _enduranceController.text = user.endurance.toString();
        _strengthController.text = user.strength.toString();
      });
    }
  }
  
  // Chargement de l'historique des statistiques
  Future<void> _loadStatsHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        await progressProvider.fetchProgressHistory(authProvider.currentUser!.id);
        
        // Dans un cas réel, nous utiliserions les données de progressProvider.progressHistory
        // Pour cette démo, je vais simuler des données d'historique
        _generateMockHistoryData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des données: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  // Génération de données d'historique fictives (à remplacer par des données réelles)
  void _generateMockHistoryData() {
    final now = DateTime.now();
    
    // Générer des données pour les 10 dernières semaines
    _weightHistory = List.generate(10, (index) {
      final date = now.subtract(Duration(days: index * 7));
      // Simule une perte de poids graduelle
      final weight = _initialWeight + (index * 0.3);
      return {'date': date, 'value': weight};
    }).reversed.toList();
    
    _enduranceHistory = List.generate(10, (index) {
      final date = now.subtract(Duration(days: index * 7));
      // Simule une augmentation de l'endurance
      final endurance = _initialEndurance - (index * 2);
      return {'date': date, 'value': endurance > 0 ? endurance : 1};
    }).reversed.toList();
    
    _strengthHistory = List.generate(10, (index) {
      final date = now.subtract(Duration(days: index * 7));
      // Simule une augmentation de la force
      final strength = _initialStrength - (index * 2);
      return {'date': date, 'value': strength > 0 ? strength : 1};
    }).reversed.toList();
  }
  
  // Enregistrement des nouvelles statistiques
  Future<void> _saveStats() async {
    if (!_isEditing) return;
    
    // Valider les entrées
    if (_weightController.text.isEmpty ||
        _enduranceController.text.isEmpty ||
        _strengthController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez remplir tous les champs obligatoires';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final double weight = double.parse(_weightController.text.replaceAll(',', '.'));
      final int endurance = int.parse(_enduranceController.text);
      final int strength = int.parse(_strengthController.text);
      
      if (weight <= 0 || endurance <= 0 || strength <= 0) {
        throw Exception('Les valeurs doivent être positives');
      }
      
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final progressProvider = Provider.of<ProgressProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        // Mise à jour des statistiques
        await userProvider.updateUserProperties(
          userId: authProvider.currentUser!.id,
          weight: weight,
          endurance: endurance,
          strength: strength,
        );
        
        // Enregistrement de la progression
        await progressProvider.saveProgress(
          userId: authProvider.currentUser!.id,
          weight: weight,
          endurance: endurance,
          strength: strength,
          notes: _notesController.text,
        );
        
        // Rafraîchir les données utilisateur
        await authProvider.refreshUserData();
        
        // Ajouter le nouvel enregistrement à l'historique local
        setState(() {
          _weightHistory.add({
            'date': DateTime.now(),
            'value': weight,
          });
          _enduranceHistory.add({
            'date': DateTime.now(),
            'value': endurance,
          });
          _strengthHistory.add({
            'date': DateTime.now(),
            'value': strength,
          });
          
          // Mettre à jour les valeurs initiales
          _initialWeight = weight;
          _initialEndurance = endurance;
          _initialStrength = strength;
          
          // Sortir du mode édition
          _isEditing = false;
        });
        
        // Afficher un message de succès
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statistiques mises à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de l\'enregistrement: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes statistiques'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Statistiques'),
            Tab(text: 'Évolution'),
            Tab(text: 'Historique'),
          ],
        ),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveStats,
              tooltip: 'Enregistrer',
            ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(center: true, message: 'Chargement des données...')
          : Consumer<AuthProvider>(
              builder: (context, authProvider, _) {
                final user = authProvider.currentUser;
                
                if (user == null) {
                  return const Center(
                    child: Text('Veuillez vous connecter pour accéder à cette page'),
                  );
                }
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Onglet Statistiques
                    _buildStatsTab(user),
                    
                    // Onglet Évolution
                    _buildEvolutionTab(),
                    
                    // Onglet Historique
                    _buildHistoryTab(),
                  ],
                );
              },
            ),
    );
  }
  
  // Onglet des statistiques actuelles
  Widget _buildStatsTab(user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec avatar
          _buildHeaderWithAvatar(user),
          
          const SizedBox(height: 24),
          
          // Carte des statistiques
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Données actuelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!_isEditing)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true;
                              
                              // Initialiser les contrôleurs avec les valeurs actuelles
                              _weightController.text = user.weight?.toString() ?? '';
                              _enduranceController.text = user.endurance.toString();
                              _strengthController.text = user.strength.toString();
                              _notesController.text = '';
                            });
                          },
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Modifier'),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Poids
                  _isEditing
                      ? AppTextField(
                          label: 'Poids (kg)',
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          hintText: 'Entrez votre poids en kg',
                          prefixIcon: Icons.monitor_weight,
                          isRequired: true,
                        )
                      : _buildStatRow(
                          'Poids',
                          '${user.weight?.toStringAsFixed(1) ?? "N/A"} kg',
                          Icons.monitor_weight,
                          Colors.blue,
                          subtitle: user.initialWeight != null && user.weight != null
                              ? 'Initial: ${user.initialWeight!.toStringAsFixed(1)} kg (${_calculateWeightDifference(user.weight!, user.initialWeight!)})'
                              : null,
                        ),
                  
                  const SizedBox(height: _isEditing ? 16 : 12),
                  
                  // Endurance
                  _isEditing
                      ? AppTextField(
                          label: 'Endurance (1-100)',
                          controller: _enduranceController,
                          keyboardType: TextInputType.number,
                          hintText: 'Entrez votre score d\'endurance',
                          prefixIcon: Icons.speed,
                          isRequired: true,
                        )
                      : _buildStatRow(
                          'Endurance',
                          '${user.endurance}/100',
                          Icons.speed,
                          Colors.orange,
                          showProgressBar: true,
                          progressValue: user.endurance / 100,
                          progressColor: Colors.orange,
                        ),
                  
                  const SizedBox(height: _isEditing ? 16 : 12),
                  
                  // Force
                  _isEditing
                      ? AppTextField(
                          label: 'Force (1-100)',
                          controller: _strengthController,
                          keyboardType: TextInputType.number,
                          hintText: 'Entrez votre score de force',
                          prefixIcon: Icons.fitness_center,
                          isRequired: true,
                        )
                      : _buildStatRow(
                          'Force',
                          '${user.strength}/100',
                          Icons.fitness_center,
                          Colors.red,
                          showProgressBar: true,
                          progressValue: user.strength / 100,
                          progressColor: Colors.red,
                        ),
                  
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    
                    // Notes sur l'enregistrement
                    AppTextField(
                      label: 'Notes (optionnel)',
                      controller: _notesController,
                      hintText: 'Commentaires sur cet enregistrement...',
                      prefixIcon: Icons.note,
                      isRequired: false,
                      maxLength: 200,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Boutons d'action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AppButton(
                          text: 'Annuler',
                          onPressed: () {
                            setState(() {
                              _isEditing = false;
                            });
                          },
                          type: AppButtonType.outline,
                        ),
                        const SizedBox(width: 16),
                        AppButton(
                          text: 'Enregistrer',
                          onPressed: _saveStats,
                          type: AppButtonType.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Afficher les messages d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            ErrorDisplay(
              message: _errorMessage!,
              type: ErrorType.general,
              actionLabel: 'Réessayer',
              onAction: _loadStatsHistory,
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Carte des niveaux physiques
          if (!_isEditing)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Niveau de fitness',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Calculer le niveau de fitness global (moyenne pondérée)
                    _buildFitnessLevel(user.endurance, user.strength),
                    
                    const SizedBox(height: 16),
                    
                    // Conseil personnalisé
                    _buildFitnessTip(user.endurance, user.strength),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  // Onglet d'évolution
  Widget _buildEvolutionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Évolution de vos performances',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Évolution du poids
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monitor_weight, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Text(
                        'Évolution du poids',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Graphique d'évolution (à remplacer par un vrai graphique)
                  _buildGraphPlaceholder(
                    data: _weightHistory,
                    yAxisLabel: 'Poids (kg)',
                    color: Colors.blue,
                  ),
                  
                  // Résumé des données
                  const SizedBox(height: 16),
                  _buildDataSummary(
                    data: _weightHistory,
                    label: 'Poids',
                    unit: 'kg',
                    isWeightData: true,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Évolution de l'endurance
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.speed, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Évolution de l\'endurance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Graphique d'évolution
                  _buildGraphPlaceholder(
                    data: _enduranceHistory,
                    yAxisLabel: 'Endurance',
                    color: Colors.orange,
                  ),
                  
                  // Résumé des données
                  const SizedBox(height: 16),
                  _buildDataSummary(
                    data: _enduranceHistory,
                    label: 'Endurance',
                    unit: 'points',
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Évolution de la force
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.fitness_center, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Évolution de la force',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Graphique d'évolution
                  _buildGraphPlaceholder(
                    data: _strengthHistory,
                    yAxisLabel: 'Force',
                    color: Colors.red,
                  ),
                  
                  // Résumé des données
                  const SizedBox(height: 16),
                  _buildDataSummary(
                    data: _strengthHistory,
                    label: 'Force',
                    unit: 'points',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Onglet d'historique
  Widget _buildHistoryTab() {
    // Fusionner les données des trois types de statistiques
    final allEntries = [..._weightHistory, ..._enduranceHistory, ..._strengthHistory]
      .map((entry) => entry['date'] as DateTime)
      .toSet()
      .toList();
    
    // Trier par date décroissante
    allEntries.sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: allEntries.length + 1, // +1 pour l'en-tête
      itemBuilder: (context, index) {
        if (index == 0) {
          // En-tête
          return const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Historique des enregistrements',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }
        
        // Chaque entrée d'historique
        final date = allEntries[index - 1];
        
        // Trouver les données correspondantes pour cette date
        final weightEntry = _weightHistory.firstWhere(
          (entry) => _isSameDay(entry['date'] as DateTime, date),
          orElse: () => {'value': null},
        );
        
        final enduranceEntry = _enduranceHistory.firstWhere(
          (entry) => _isSameDay(entry['date'] as DateTime, date),
          orElse: () => {'value': null},
        );
        
        final strengthEntry = _strengthHistory.firstWhere(
          (entry) => _isSameDay(entry['date'] as DateTime, date),
          orElse: () => {'value': null},
        );
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date de l'enregistrement
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(date),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                
                // Détails des mesures
                if (weightEntry['value'] != null)
                  _buildHistoryItem(
                    'Poids',
                    '${weightEntry['value'].toStringAsFixed(1)} kg',
                    Icons.monitor_weight,
                    Colors.blue,
                  ),
                
                if (enduranceEntry['value'] != null)
                  _buildHistoryItem(
                    'Endurance',
                    '${enduranceEntry['value']}/100',
                    Icons.speed,
                    Colors.orange,
                  ),
                
                if (strengthEntry['value'] != null)
                  _buildHistoryItem(
                    'Force',
                    '${strengthEntry['value']}/100',
                    Icons.fitness_center,
                    Colors.red,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Méthode utilitaire pour vérifier si deux dates sont le même jour
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }
  
  // Widget d'en-tête avec avatar
  Widget _buildHeaderWithAvatar(user) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(60),
          child: Image.asset(
            'assets/avatars/${user.gender}_${user.skinColor}_${user.avatarStage}.png',
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey[600],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Niveau ${user.level}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Données mises à jour ${_getLastUpdateText()}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // Widget de ligne de statistique
  Widget _buildStatRow(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    bool showProgressBar = false,
    double? progressValue,
    Color? progressColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                if (showProgressBar && progressValue != null) ...[
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressValue.clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[200],
                    color: progressColor,
                    minHeight: 8,
                  ),
                ],
              ],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget pour l'élément d'historique
  Widget _buildHistoryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  // Widget placeholder pour un graphique
  Widget _buildGraphPlaceholder({
    required List<Map<String, dynamic>> data,
    required String yAxisLabel,
    required Color color,
  }) {
    if (data.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: Text(
          'Pas de données disponibles',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    // Trouver les valeurs min et max pour l'axe Y
    double minValue = double.infinity;
    double maxValue = double.negativeInfinity;
    
    for (var item in data) {
      if (item['value'] != null) {
        final value = item['value'] is int ? item['value'].toDouble() : item['value'];
        if (value < minValue) minValue = value;
        if (value > maxValue) maxValue = value;
      }
    }
    
    // Arrondir les valeurs pour l'affichage
    minValue = (minValue * 0.9).floorToDouble();
    maxValue = (maxValue * 1.1).ceilToDouble();
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Axe Y (vertical)
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  maxValue.toStringAsFixed(maxValue.truncateToDouble() == maxValue ? 0 : 1),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  ((maxValue + minValue) / 2).toStringAsFixed(1),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
                Text(
                  minValue.toStringAsFixed(minValue.truncateToDouble() == minValue ? 0 : 1),
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(width: 8),
            
            // Graphique
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Zone de graphique
                  Expanded(
                    child: CustomPaint(
                      painter: GraphPainter(
                        data: data,
                        minValue: minValue,
                        maxValue: maxValue,
                        color: color,
                      ),
                    ),
                  ),
                  
                  // Axe X (horizontal)
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data.isNotEmpty 
                            ? DateFormat('dd/MM').format(data.first['date'] as DateTime)
                            : '',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        data.length > 1 
                            ? DateFormat('dd/MM').format(data[data.length ~/ 2]['date'] as DateTime)
                            : '',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      Text(
                        data.isNotEmpty 
                            ? DateFormat('dd/MM').format(data.last['date'] as DateTime)
                            : '',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget pour afficher le résumé des données
  Widget _buildDataSummary({
    required List<Map<String, dynamic>> data,
    required String label,
    required String unit,
    bool isWeightData = false,
  }) {
    if (data.isEmpty || data.length < 2) {
      return Text(
        'Pas assez de données pour analyser la progression',
        style: TextStyle(
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
        ),
      );
    }
    
    // Calculer la différence entre la première et la dernière valeur
    final firstValue = data.first['value'];
    final lastValue = data.last['value'];
    final difference = lastValue - firstValue;
    
    // Déterminer si c'est une amélioration (selon le type de donnée)
    bool isImprovement = isWeightData ? difference < 0 : difference > 0;
    
    // Calculer le pourcentage de changement
    final percentChange = firstValue != 0 
        ? (difference / firstValue * 100).abs()
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isImprovement ? Icons.trending_up : Icons.trending_down,
              color: isImprovement ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isImprovement ? 'Amélioration' : 'Régression',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isImprovement ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isWeightData
              ? 'Vous avez ${isImprovement ? 'perdu' : 'pris'} ${difference.abs().toStringAsFixed(1)} $unit (${percentChange.toStringAsFixed(1)}%)'
              : 'Votre $label a ${isImprovement ? 'augmenté' : 'diminué'} de ${difference.abs().toStringAsFixed(0)} $unit (${percentChange.toStringAsFixed(1)}%)',
          style: TextStyle(
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Période: ${DateFormat('dd/MM/yyyy').format(data.first['date'] as DateTime)} - ${DateFormat('dd/MM/yyyy').format(data.last['date'] as DateTime)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  // Widget pour afficher le niveau de fitness
  Widget _buildFitnessLevel(int endurance, int strength) {
    // Calculer un score fitness global (moyenne pondérée)
    final fitnessScore = (endurance * 0.6 + strength * 0.4) / 100;
    
    // Déterminer le niveau et la couleur
    String fitnessLevel;
    Color fitnessColor;
    
    if (fitnessScore >= 0.8) {
      fitnessLevel = 'Excellent';
      fitnessColor = Colors.green[700]!;
    } else if (fitnessScore >= 0.6) {
      fitnessLevel = 'Bon';
      fitnessColor = Colors.green;
    } else if (fitnessScore >= 0.4) {
      fitnessLevel = 'Moyen';
      fitnessColor = Colors.orange;
    } else if (fitnessScore >= 0.2) {
      fitnessLevel = 'À améliorer';
      fitnessColor = Colors.orange[300]!;
    } else {
      fitnessLevel = 'Débutant';
      fitnessColor = Colors.red[300]!;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Niveau de fitness global',
              style: TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: fitnessColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: fitnessColor, width: 1),
              ),
              child: Text(
                fitnessLevel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: fitnessColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fitnessScore,
            backgroundColor: Colors.grey[200],
            color: fitnessColor,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
  
  // Widget pour afficher un conseil personnalisé
  Widget _buildFitnessTip(int endurance, int strength) {
    // Décider du conseil selon les statistiques
    String tipTitle;
    String tipContent;
    IconData tipIcon;
    
    if (endurance < 30 && strength < 30) {
      tipTitle = 'Conseil pour débutant';
      tipContent = 'Commencez par des exercices légers et augmentez progressivement l\'intensité. Priorisez la constance plutôt que l\'intensité.';
      tipIcon = Icons.fitness_center;
    } else if (endurance < strength && (strength - endurance) > 20) {
      tipTitle = 'Améliorez votre endurance';
      tipContent = 'Votre force est bonne, mais travaillez sur votre endurance avec des exercices cardio réguliers comme la course, le vélo ou la corde à sauter.';
      tipIcon = Icons.directions_run;
    } else if (strength < endurance && (endurance - strength) > 20) {
      tipTitle = 'Renforcez vos muscles';
      tipContent = 'Votre endurance est bonne, mais travaillez plus sur la force avec des exercices de résistance et des poids.';
      tipIcon = Icons.fitness_center;
    } else if (endurance >= 70 && strength >= 70) {
      tipTitle = 'Maintenez votre excellent niveau';
      tipContent = 'Continuez votre bon travail ! À ce niveau, variez vos exercices pour éviter les plateaux et prévenir les blessures.';
      tipIcon = Icons.emoji_events;
    } else {
      tipTitle = 'Équilibrez votre entraînement';
      tipContent = 'Alternez entre exercices de cardio et de force pour un développement équilibré. N\'oubliez pas de vous reposer entre les séances intensives.';
      tipIcon = Icons.balance;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tipIcon, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                tipTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            tipContent,
            style: TextStyle(
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  // Calcule la différence de poids et renvoie un texte formaté
  String _calculateWeightDifference(double current, double initial) {
    final difference = current - initial;
    final percentChange = (difference / initial * 100).abs();
    
    return difference >= 0
        ? '+${difference.toStringAsFixed(1)} kg (+${percentChange.toStringAsFixed(1)}%)'
        : '-${difference.abs().toStringAsFixed(1)} kg (-${percentChange.toStringAsFixed(1)}%)';
  }
  
  // Renvoie un texte indiquant quand les données ont été mises à jour pour la dernière fois
  String _getLastUpdateText() {
    // Dans une implémentation réelle, cette information viendrait de la base de données
    // Pour cette démo, on utilise une date fixe
    return 'aujourd\'hui';
  }
}

// Classe de peintre personnalisé pour dessiner un graphique simple
class GraphPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double minValue;
  final double maxValue;
  final Color color;
  
  GraphPainter({
    required this.data,
    required this.minValue,
    required this.maxValue,
    required this.color,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final pointPaint = Paint()
      ..color = color
      ..strokeWidth = 4.0
      ..style = PaintingStyle.fill;
    
    final path = Path();
    
    // Dessiner la ligne du graphique
    for (int i = 0; i < data.length; i++) {
      final dataPoint = data[i];
      final value = dataPoint['value'] is int ? dataPoint['value'].toDouble() : dataPoint['value'];
      
      // Calculer les coordonnées x et y
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((value - minValue) / (maxValue - minValue) * size.height);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      
      // Dessiner un point pour chaque valeur
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}