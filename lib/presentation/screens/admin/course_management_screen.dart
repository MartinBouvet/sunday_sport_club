import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_display.dart';
import '../../../data/datasources/supabase/supabase_course_datasource.dart';
import '../../../data/models/course.dart';
import '../../../data/repositories/course_repository.dart';
import '../../providers/auth_provider.dart';

/// Écran de gestion des cours pour les administrateurs
///
/// Permet de visualiser, créer, modifier et supprimer des cours
/// ainsi que de gérer les différentes sessions de coaching.
class CourseManagementScreen extends StatefulWidget {
  const CourseManagementScreen({super.key});

  @override
  State<CourseManagementScreen> createState() => _CourseManagementScreenState();
}

class _CourseManagementScreenState extends State<CourseManagementScreen> with SingleTickerProviderStateMixin {
  final CourseRepository _courseRepository = CourseRepository();
  final SupabaseCourseDatasource _courseDatasource = SupabaseCourseDatasource();
  
  late TabController _tabController;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isEditing = false;
  String? _errorMessage;
  
  List<Course> _allCourses = [];
  List<Course> _filteredCourses = [];
  Course? _selectedCourse;
  
  // Filtres
  String _filterType = 'all'; // all, individual, collective
  String _filterStatus = 'all'; // all, available, full, cancelled
  DateTime _filterStartDate = DateTime.now();
  DateTime _filterEndDate = DateTime.now().add(const Duration(days: 30));
  
  // Contrôleurs pour les formulaires
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _startTimeController = TextEditingController();
  final TextEditingController _endTimeController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _loadCourses();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }
  
  void _handleTabChanged() {
    if (_tabController.indexIsChanging) {
      setState(() {
        switch (_tabController.index) {
          case 0: // Tous les cours
            _filterType = 'all';
            break;
          case 1: // Cours individuels
            _filterType = AppConstants.membershipTypeIndividual;
            break;
          case 2: // Cours collectifs
            _filterType = AppConstants.membershipTypeCollective;
            break;
        }
      });
      _filterCourses();
    }
  }
  
  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Récupérer tous les cours depuis la base de données
      final courses = await _courseRepository.getAllCourses();
      
      setState(() {
        _allCourses = courses;
        _filterCourses();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des cours: $e';
        _isLoading = false;
      });
    }
  }
  
  void _filterCourses() {
    if (_allCourses.isEmpty) {
      setState(() {
        _filteredCourses = [];
      });
      return;
    }
    
    setState(() {
      _filteredCourses = _allCourses.where((course) {
        // Filtre par type
        if (_filterType != 'all' && course.type != _filterType) {
          return false;
        }
        
        // Filtre par statut
        if (_filterStatus != 'all' && course.status != _filterStatus) {
          return false;
        }
        
        // Filtre par date
        if (course.date.isBefore(_filterStartDate) || 
            course.date.isAfter(_filterEndDate)) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Tri par date (plus récent d'abord)
      _filteredCourses.sort((a, b) => a.date.compareTo(b.date));
    });
  }
  
  void _resetFilters() {
    setState(() {
      _filterType = 'all';
      _filterStatus = 'all';
      _filterStartDate = DateTime.now();
      _filterEndDate = DateTime.now().add(const Duration(days: 30));
      _tabController.index = 0;
    });
    _filterCourses();
  }
  
  void _showCreateCourseForm() {
    setState(() {
      _isCreating = true;
      _isEditing = false;
      _selectedCourse = null;
      
      // Réinitialiser les contrôleurs
      _titleController.text = '';
      _descriptionController.text = '';
      _capacityController.text = '10';
      _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now().add(const Duration(days: 1)));
      _startTimeController.text = '10:00';
      _endTimeController.text = '11:00';
    });
  }
  
  void _showEditCourseForm(Course course) {
    setState(() {
      _isCreating = false;
      _isEditing = true;
      _selectedCourse = course;
      
      // Remplir les contrôleurs avec les données du cours
      _titleController.text = course.title;
      _descriptionController.text = course.description;
      _capacityController.text = course.capacity.toString();
      _dateController.text = DateFormat('dd/MM/yyyy').format(course.date);
      _startTimeController.text = course.startTime;
      _endTimeController.text = course.endTime;
    });
  }
  
  void _cancelForm() {
    setState(() {
      _isCreating = false;
      _isEditing = false;
      _selectedCourse = null;
    });
  }
  
  Future<void> _saveCourse() async {
    // Validation de base
    if (_titleController.text.isEmpty || 
        _descriptionController.text.isEmpty || 
        _dateController.text.isEmpty ||
        _startTimeController.text.isEmpty ||
        _endTimeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validation de la capacité
    int capacity;
    try {
      capacity = int.parse(_capacityController.text);
      if (capacity <= 0) throw FormatException('La capacité doit être positive');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une capacité valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validation de la date
    DateTime date;
    try {
      date = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format de date invalide. Utilisez JJ/MM/AAAA'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      if (_isCreating) {
        // Créer un nouveau cours
        final newCourse = Course(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporaire, sera remplacé par Supabase
          title: _titleController.text,
          description: _descriptionController.text,
          type: _tabController.index == 1 ? AppConstants.membershipTypeIndividual : AppConstants.membershipTypeCollective,
          date: date,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          capacity: capacity,
          currentParticipants: 0,
          status: 'available',
          coachId: userId,
        );
        
        await _courseRepository.createCourse(newCourse);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (_isEditing && _selectedCourse != null) {
        // Mettre à jour un cours existant
        final updatedCourse = _selectedCourse!.copyWith(
          title: _titleController.text,
          description: _descriptionController.text,
          type: _tabController.index == 1 ? AppConstants.membershipTypeIndividual : AppConstants.membershipTypeCollective,
          date: date,
          startTime: _startTimeController.text,
          endTime: _endTimeController.text,
          capacity: capacity,
        );
        
        await _courseRepository.updateCourse(
          _selectedCourse!.id,
          updatedCourse.toJson(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cours mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Réinitialiser l'état et recharger les données
      setState(() {
        _isCreating = false;
        _isEditing = false;
        _selectedCourse = null;
      });
      
      await _loadCourses();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _deleteCourse(Course course) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer le cours "${course.title}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _isLoading = true;
              });
              
              try {
                await _courseRepository.deleteCourse(course.id);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cours supprimé avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
                
                await _loadCourses();
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors de la suppression: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _updateCourseStatus(Course course, String newStatus) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _courseRepository.updateCourse(
        course.id,
        {'status': newStatus},
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Statut du cours mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
      
      await _loadCourses();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    
    if (picked != null) {
      final String formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isStartTime) {
          _startTimeController.text = formattedTime;
        } else {
          _endTimeController.text = formattedTime;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des cours'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous les cours'),
            Tab(text: 'Cours individuels'),
            Tab(text: 'Cours collectifs'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourses,
            tooltip: 'Rafraîchir',
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;
          
          // Vérifier si l'utilisateur est admin
          if (user == null || user.role != 'admin') {
            return const Center(
              child: Text('Accès restreint aux administrateurs'),
            );
          }
          
          if (_isLoading) {
            return const LoadingIndicator(center: true, message: 'Chargement...');
          }
          
          if (_errorMessage != null) {
            return ErrorDisplay(
              message: _errorMessage!,
              actionLabel: 'Réessayer',
              onAction: _loadCourses,
            );
          }
          
          // Affichage du formulaire de création/édition
          if (_isCreating || _isEditing) {
            return _buildCourseForm();
          }
          
          // Affichage de la liste des cours
          return _buildCourseList();
        },
      ),
      floatingActionButton: (!_isCreating && !_isEditing)
          ? FloatingActionButton(
              onPressed: _showCreateCourseForm,
              tooltip: 'Créer un cours',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
  
  Widget _buildCourseList() {
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous')),
                    DropdownMenuItem(value: 'available', child: Text('Disponible')),
                    DropdownMenuItem(value: 'full', child: Text('Complet')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Annulé')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filterStatus = value;
                      });
                      _filterCourses();
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.filter_alt_off),
                onPressed: _resetFilters,
                tooltip: 'Réinitialiser les filtres',
              ),
            ],
          ),
        ),
        
        // Liste des cours
        Expanded(
          child: _filteredCourses.isEmpty
              ? const Center(
                  child: Text('Aucun cours trouvé pour ces critères'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredCourses.length,
                  itemBuilder: (context, index) {
                    final course = _filteredCourses[index];
                    return _buildCourseCard(course);
                  },
                ),
        ),
      ],
    );
  }
  
  Widget _buildCourseCard(Course course) {
    final bool isPast = course.date.isBefore(DateTime.now());
    final bool isFull = course.currentParticipants >= course.capacity;
    final bool isCancelled = course.status == 'cancelled';
    
    Color statusColor;
    String statusText;
    
    if (isCancelled) {
      statusColor = Colors.red;
      statusText = 'Annulé';
    } else if (isPast) {
      statusColor = Colors.grey;
      statusText = 'Passé';
    } else if (isFull) {
      statusColor = Colors.orange;
      statusText = 'Complet';
    } else {
      statusColor = Colors.green;
      statusText = 'Disponible';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Informations du cours
            Text(
              course.description,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            
            // Détails
            Row(
              children: [
                _buildDetailItem(Icons.event, DateFormat('dd/MM/yyyy').format(course.date)),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.access_time, '${course.startTime} - ${course.endTime}'),
                const SizedBox(width: 16),
                _buildDetailItem(Icons.people, '${course.currentParticipants}/${course.capacity}'),
                const SizedBox(width: 16),
                _buildDetailItem(
                  Icons.category,
                  course.type == AppConstants.membershipTypeIndividual ? 'Individuel' : 'Collectif',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Bouton Voir participants
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implémenter la vue des participants
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fonctionnalité à implémenter'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.people, size: 16),
                  label: const Text('Participants'),
                ),
                
                const SizedBox(width: 8),
                
                // Bouton d'édition
                TextButton.icon(
                  onPressed: () => _showEditCourseForm(course),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Modifier'),
                ),
                
                const SizedBox(width: 8),
                
                // Menu d'options
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'cancel':
                        _updateCourseStatus(course, 'cancelled');
                        break;
                      case 'activate':
                        _updateCourseStatus(course, 'available');
                        break;
                      case 'delete':
                        _deleteCourse(course);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (course.status != 'cancelled')
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Annuler le cours'),
                      ),
                    if (course.status == 'cancelled')
                      const PopupMenuItem(
                        value: 'activate',
                        child: Text('Réactiver le cours'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildCourseForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isCreating ? 'Créer un nouveau cours' : 'Modifier le cours',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          // Formulaire
          AppTextField(
            label: 'Titre du cours',
            controller: _titleController,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          AppTextField(
            label: 'Description',
            controller: _descriptionController,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          // Type de cours (sélectionné via les onglets)
          Text(
            'Type de cours: ${_tabController.index == 1 ? 'Individuel' : 'Collectif'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Capacité
          AppTextField(
            label: 'Capacité',
            controller: _capacityController,
            keyboardType: TextInputType.number,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          
          // Date
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: AppTextField(
                label: 'Date',
                controller: _dateController,
                isRequired: true,
                prefixIcon: Icons.calendar_today,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Horaires
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, true),
                  child: AbsorbPointer(
                    child: AppTextField(
                      label: 'Heure de début',
                      controller: _startTimeController,
                      isRequired: true,
                      prefixIcon: Icons.access_time,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectTime(context, false),
                  child: AbsorbPointer(
                    child: AppTextField(
                      label: 'Heure de fin',
                      controller: _endTimeController,
                      isRequired: true,
                      prefixIcon: Icons.access_time,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Boutons d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                text: 'Annuler',
                onPressed: _cancelForm,
                type: AppButtonType.outline,
              ),
              const SizedBox(width: 16),
              AppButton(
                text: _isCreating ? 'Créer' : 'Enregistrer',
                onPressed: _saveCourse,
                type: AppButtonType.primary,
                isLoading: _isLoading,
              ),
            ],
          ),
        ],
      ),
    );
  }
}