import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class UsersScreen extends StatefulWidget {
  final String? selectedUserId;
  const UsersScreen({Key? key, this.selectedUserId}) : super(key: key);
  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final UserController _controller =
      UserController(UserDataSourceImpl(client: http.Client()));
  final AuthController _authController = Get.find<AuthController>();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  String? _highlightedUserId;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Palette de couleurs pour un design cohérent
  final Color _primaryColor = const Color.fromARGB(255, 84, 151, 198);
  final Color _secondaryColor = const Color.fromARGB(255, 16, 16, 17);
  final Color _accentColor = const Color(0xFFFF4081);
  final Color _lightPrimaryColor = const Color(0xFFC5CAE9);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);

  // Pagination
  int _currentPage = 1;
  int _usersPerPage = 10;
  int get _startIndex => (_currentPage - 1) * _usersPerPage;
  int get _endIndex => _startIndex + _usersPerPage > _filteredUsers.length
      ? _filteredUsers.length
      : _startIndex + _usersPerPage;

  // Search and filtering
  final TextEditingController _searchController = TextEditingController();
  List<User> _filteredUsers = [];
  String _currentSearchTerm = '';
  String _sortColumn = '';
  bool _sortAscending = true;

  // Advanced filters
  Map<String, String?> _filters = {
    'nom': null,
    'prenom': null,
    'email': null,
    'date': null,
    'phone': null,
    'region': null,
    'genre': null,
  };
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();

    // Initialiser la recherche
    _searchController.addListener(_onSearchChanged);

    // Initialiser la mise en évidence si un ID est passé
    if (widget.selectedUserId != null) {
      _highlightedUserId = widget.selectedUserId;

      // Réinitialiser après 3 secondes
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _highlightedUserId = null;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchTerm = _searchController.text;
      _filterUsers();
      _currentPage = 1; // Reset to first page on new search
    });
  }

  void _filterUsers() {
    if (_controller.users.isEmpty) {
      _filteredUsers = [];
      return;
    }

    _filteredUsers = _controller.users.where((user) {
      final matchesSearch = _currentSearchTerm.isEmpty ||
          user.nom.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.prenom
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          user.email.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.phone.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.date.toLowerCase().contains(_currentSearchTerm.toLowerCase()) ||
          user.region
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          user.genre.toLowerCase().contains(_currentSearchTerm.toLowerCase());

      final matchesNom = _filters['nom'] == null ||
          _filters['nom']!.isEmpty ||
          user.nom.toLowerCase().contains(_filters['nom']!.toLowerCase());

      final matchesPrenom = _filters['prenom'] == null ||
          _filters['prenom']!.isEmpty ||
          user.prenom.toLowerCase().contains(_filters['prenom']!.toLowerCase());

      final matchesEmail = _filters['email'] == null ||
          _filters['email']!.isEmpty ||
          user.email.toLowerCase().contains(_filters['email']!.toLowerCase());

      final matchesPhone = _filters['phone'] == null ||
          _filters['phone']!.isEmpty ||
          user.phone.toLowerCase().contains(_filters['phone']!.toLowerCase());

      final matchesDate = _filters['date'] == null ||
          _filters['date']!.isEmpty ||
          user.date.toLowerCase().contains(_filters['date']!.toLowerCase());

      final matchesRegion = _filters['region'] == null ||
          _filters['region']!.isEmpty ||
          user.region == _filters['region'];

      final matchesGenre = _filters['genre'] == null ||
          _filters['genre']!.isEmpty ||
          user.genre == _filters['genre'];

      return matchesSearch &&
          matchesNom &&
          matchesPrenom &&
          matchesEmail &&
          matchesPhone &&
          matchesDate &&
          matchesRegion &&
          matchesGenre;
    }).toList();

    // Apply sorting if a column is selected
    if (_sortColumn.isNotEmpty) {
      _filteredUsers.sort((a, b) {
        var aValue = _getValueForSort(a, _sortColumn);
        var bValue = _getValueForSort(b, _sortColumn);
        var comparison = aValue.compareTo(bValue);
        return _sortAscending ? comparison : -comparison;
      });
    }
  }

  Future<void> _showAddUserDialog(User? user) async {
    final _formKey = GlobalKey<FormState>();

    // Form controllers
    final TextEditingController _nomController = TextEditingController();
    final TextEditingController _prenomController = TextEditingController();
    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _phoneController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _dateController = TextEditingController(
      text: user?.date != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(user!.date))
          : '',
    );
    bool _isLoading = false;

    // Selection variables
    String _selectedRegion = Regions.list.first;
    String _selectedGenre = 'Homme';
    DateTime _selectedDate =
        DateTime.tryParse(user?.date ?? '') ?? DateTime.now();
    PlatformFile? _tempSelectedImage;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 600,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog title
                    const Text(
                      'Ajouter un utilisateur',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Form content in a scrollable container
                    Flexible(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile image upload section
                              Center(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height:
                                          120, // Give explicit size to the file picker
                                      child: FilePickerExample(
                                        onImagePicked: (PlatformFile? file) {
                                          setState(() {
                                            _tempSelectedImage = file;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Photo de profil'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name and surname fields
                              Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _nomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Nom',
                                        border: OutlineInputBorder(),
                                        hintText: 'Entrez le nom de famille',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer un nom';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _prenomController,
                                      decoration: const InputDecoration(
                                        labelText: 'Prénom',
                                        border: OutlineInputBorder(),
                                        hintText: 'Entrez le prénom',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer un prénom';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Email field
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  border: OutlineInputBorder(),
                                  hintText: 'exemple@gmail.com',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un email';
                                  }
                                  if (!value.endsWith('@gmail.com')) {
                                    return 'L\'email doit être sous format @gmail.com';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Mot de passe',
                                  border: OutlineInputBorder(),
                                  hintText:
                                      'Minimum 8 caractères avec majuscule, chiffre et caractère spécial',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 16),
                                ),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Veuillez entrer un mot de passe';
                                  }
                                  if (value.length < 8) {
                                    return 'Le mot de passe doit contenir au moins 8 caractères';
                                  }
                                  if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                    return 'Le mot de passe doit contenir au moins une majuscule';
                                  }
                                  if (!RegExp(r'[0-9]').hasMatch(value)) {
                                    return 'Le mot de passe doit contenir au moins un chiffre';
                                  }
                                  if (!RegExp(r'[!@/+_#$%^&*(),.?":{}|<>]')
                                      .hasMatch(value)) {
                                    return 'Le mot de passe doit contenir au moins un caractère spécial';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Phone and date fields
                              Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _phoneController,
                                      decoration: const InputDecoration(
                                        labelText: 'Téléphone',
                                        border: OutlineInputBorder(),
                                        hintText: '8 chiffres',
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      keyboardType: TextInputType.phone,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez entrer un numéro de téléphone';
                                        }
                                        if (value.length != 8 ||
                                            !RegExp(r'^[0-9]{8}$')
                                                .hasMatch(value)) {
                                          return 'Le téléphone doit contenir exactement 8 chiffres';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Date de naissance
                                  Flexible(
                                    flex: 1,
                                    child: TextFormField(
                                      controller: _dateController,
                                      decoration: const InputDecoration(
                                        labelText: 'Date de naissance',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      readOnly: true,
                                      onTap: () async {
                                        final DateTime? picked =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: _selectedDate,
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null &&
                                            picked != _selectedDate) {
                                          setState(() {
                                            _selectedDate = picked;
                                            _dateController.text =
                                                DateFormat('yyyy-MM-dd')
                                                    .format(_selectedDate);
                                          });
                                        }
                                      },
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Veuillez sélectionner une date';
                                        }

                                        // Vérifier que l'utilisateur a au moins 13 ans
                                        final selectedDate =
                                            DateTime.tryParse(value);
                                        if (selectedDate != null) {
                                          final today = DateTime.now();
                                          final age = today.year -
                                              selectedDate.year -
                                              (today.month <
                                                          selectedDate.month ||
                                                      (today.month ==
                                                              selectedDate
                                                                  .month &&
                                                          today.day <
                                                              selectedDate.day)
                                                  ? 1
                                                  : 0);

                                          if (age < 13) {
                                            return 'L\'utilisateur doit avoir au moins 13 ans';
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Region and gender selection
                              Row(
                                children: [
                                  Flexible(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Région',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      value: _selectedRegion,
                                      items: Regions.list.map((region) {
                                        return DropdownMenuItem(
                                          value: region,
                                          child: Text(region),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedRegion = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Flexible(
                                    flex: 1,
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Genre',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 16),
                                      ),
                                      value: _selectedGenre,
                                      items: ['Homme', 'Femme'].map((genre) {
                                        return DropdownMenuItem(
                                          value: genre,
                                          child: Text(genre),
                                        );
                                      }).toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            _selectedGenre = value;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Action buttons
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  if (_formKey.currentState!.validate()) {
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      // Créer l'utilisateur
                                      final newUser = User(
                                        nom: _nomController.text,
                                        prenom: _prenomController.text,
                                        email: _emailController.text,
                                        date: DateFormat('yyyy-MM-dd')
                                            .format(_selectedDate),
                                        region: _selectedRegion,
                                        genre: _selectedGenre,
                                        password: _passwordController.text,
                                        phone: _phoneController.text,
                                        status: 'Active',
                                        imageUrl: 'imageUrl',
                                      );

                                      // Add user to database FIRST
                                      final result =
                                          await _controller.addUser(newUser);

                                      // THEN, upload the image if available
                                      if (_tempSelectedImage != null) {
                                        final imageUrl =
                                            await _uploadImageAndGetUrl(
                                          _tempSelectedImage,
                                          _emailController.text,
                                        );
                                        // Update the user with the new image URL
                                        newUser.imageUrl = imageUrl;
                                      }

                                      // Retrieve the complete user with ID
                                      final completeUser = await _authController
                                          .getUserByEmail(newUser.email);

                                      // Update the user ID
                                      newUser.id = completeUser['_id'] ??
                                          completeUser['id'] ??
                                          '';

                                      // Close the dialog
                                      Navigator.pop(dialogContext);

                                      // Update UI
                                      if (mounted) {
                                        setState(() {
                                          _controller.fetchUsers();
                                          _showSnackBar(
                                              'Utilisateur ajouté avec succès');
                                          // Force refresh of the UI
                                          _controller.fetchUsers().then((_) {
                                            if (mounted) {
                                              setState(() {
                                                _filterUsers();
                                              });
                                            }
                                          }).catchError((error) {
                                            print(
                                                "Erreur lors du rafraîchissement des utilisateurs: $error");
                                          });
                                        });
                                      }
                                    } catch (e) {
                                      _showSnackBar('Erreur: ${e.toString()}',
                                          isError: true);
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isLoading = false;
                                        });
                                      }
                                    }
                                  }
                                },
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.0),
                                )
                              : const Text('Ajouter'),
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

    // Force rebuild after dialog is closed
    if (mounted) {
      setState(() {});
    }
  }

  String _getValueForSort(User user, String column) {
    switch (column) {
      case 'id':
        return user.id ?? '';
      case 'nom':
        return user.nom.toLowerCase();
      case 'prenom':
        return user.prenom.toLowerCase();
      case 'email':
        return user.email.toLowerCase();
      case 'date':
        return user.date;
      case 'phone':
        return user.phone;
      case 'region':
        return user.region.toLowerCase();
      case 'genre':
        return user.genre.toLowerCase();
      default:
        return '';
    }
  }

  void _sortBy(String column) {
    setState(() {
      // If clicking the same column, toggle direction
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
      _filterUsers();
    });
  }

  void _resetFilters() {
    setState(() {
      for (var key in _filters.keys) {
        _filters[key] = null;
      }
      _searchController.clear();
      _currentSearchTerm = '';
      _filterUsers();
      _currentPage = 1;
    });
  }

  Future<void> _loadUsers() async {
    await _controller.fetchUsers();
    setState(() {
      _filterUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Builder(
          builder: (BuildContext context) {
            if (_controller.isLoading) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_primaryColor),
                        strokeWidth: 4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chargement des utilisateurs...',
                      style: TextStyle(
                        fontSize: 16,
                        color: _textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (_controller.error != null) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: _accentColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadUsers,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Réessayer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Wrap the main content in a Row to include the sidebar
            return Row(
              children: [
                // Add the CustomSidebar here
                CustomSidebar(currentPage: 'Users'),

                // Main content
                Expanded(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildSearchBar(),
                          if (_showFilters) _buildAdvancedFilters(),
                          const SizedBox(height: 24),
                          Expanded(
                            child: _buildContent(),
                          ),
                          const SizedBox(height: 16),
                          _buildPagination(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _lightPrimaryColor,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Utilisateurs',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_controller.users.length} utilisateurs',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddUserDialog(null),
            icon: const Icon(Icons.person_add),
            label: const Text('Nouvel utilisateur'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Rechercher un utilisateur par nom, email, téléphone...',
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                    filled: true,
                    fillColor: _backgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    hintStyle: TextStyle(color: _textSecondaryColor),
                  ),
                  style: TextStyle(color: _textPrimaryColor, fontSize: 15),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
                icon: Icon(
                    _showFilters ? Icons.filter_list_off : Icons.filter_list),
                label:
                    Text(_showFilters ? 'Masquer filtres' : 'Filtres avancés'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _showFilters ? _lightPrimaryColor : _primaryColor,
                  foregroundColor: _showFilters ? _primaryColor : Colors.white,
                  elevation: _showFilters ? 0 : 2,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          if (_filteredUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _lightPrimaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const Spacer(),
                  if (_showFilters || _currentSearchTerm.isNotEmpty)
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: Icon(Icons.clear_all, color: _accentColor),
                      label: Text(
                        'Réinitialiser les filtres',
                        style: TextStyle(
                          color: _accentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: _lightPrimaryColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Filtres avancés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline),
                color: _textSecondaryColor,
                tooltip: 'Aide sur les filtres',
                onPressed: () {
                  // Afficher une aide sur les filtres
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // First row of filters
          Row(
            children: [
              Expanded(
                child: _buildFilterTextField(
                  label: 'Nom',
                  hintText: 'Filtrer par nom',
                  icon: Icons.person,
                  value: _filters['nom'],
                  onChanged: (value) {
                    setState(() {
                      _filters['nom'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterTextField(
                  label: 'Prénom',
                  hintText: 'Filtrer par prénom',
                  icon: Icons.person_outline,
                  value: _filters['prenom'],
                  onChanged: (value) {
                    setState(() {
                      _filters['prenom'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterTextField(
                  label: 'Email',
                  hintText: 'Filtrer par email',
                  icon: Icons.email_outlined,
                  value: _filters['email'],
                  onChanged: (value) {
                    setState(() {
                      _filters['email'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Second row of filters
          Row(
            children: [
              Expanded(
                child: _buildFilterTextField(
                  label: 'Téléphone',
                  hintText: 'Filtrer par téléphone',
                  icon: Icons.phone_outlined,
                  value: _filters['phone'],
                  onChanged: (value) {
                    setState(() {
                      _filters['phone'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterTextField(
                  label: 'Date de naissance',
                  hintText: 'YYYY-MM-DD',
                  icon: Icons.calendar_today,
                  value: _filters['date'],
                  onChanged: (value) {
                    setState(() {
                      _filters['date'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Région',
                  hint: 'Toutes les régions',
                  icon: Icons.location_on_outlined,
                  value: _filters['region'],
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Toutes les régions'),
                    ),
                    ...Regions.list.map((region) {
                      return DropdownMenuItem<String>(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters['region'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Genre',
                  hint: 'Tous les genres',
                  icon: Icons.people_outline,
                  value: _filters['genre'],
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les genres'),
                    ),
                    ...['Homme', 'Femme', 'Autre'].map((genre) {
                      return DropdownMenuItem<String>(
                        value: genre,
                        child: Text(genre),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filters['genre'] = value;
                      _filterUsers();
                      _currentPage = 1;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTextField({
    required String label,
    required String hintText,
    required IconData icon,
    required String? value,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _lightPrimaryColor,
              width: 1,
            ),
          ),
          child: TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            style: TextStyle(color: _textPrimaryColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: _textSecondaryColor),
              prefixIcon: Icon(icon, color: _primaryColor, size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _lightPrimaryColor,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: _textSecondaryColor)),
              icon: const Icon(Icons.keyboard_arrow_down),
              isExpanded: true,
              style: TextStyle(color: _textPrimaryColor, fontSize: 15),
              dropdownColor: Colors.white,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    // Handle empty state
    if (_filteredUsers.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun utilisateur trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    // Get current page users
    final displayedUsers = _filteredUsers.length <= _usersPerPage
        ? _filteredUsers
        : _filteredUsers.sublist(_startIndex, _endIndex);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          dataRowHeight: 70,
          headingRowHeight: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.shade100, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          columns: [
            DataColumn(
              label: const Text('ID',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 0, 0))),
            ),
            DataColumn(
              label: const Text('Image',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 5, 5, 5))),
            ),
            DataColumn(
              label: const Text('Nom',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 9, 9, 9))),
              onSort: (_, __) => _sortBy('nom'),
            ),
            DataColumn(
              label: const Text('Prénom',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 4, 4, 4))),
              onSort: (_, __) => _sortBy('prenom'),
            ),
            DataColumn(
              label: const Text('Email',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 9, 9, 9))),
              onSort: (_, __) => _sortBy('email'),
            ),
            DataColumn(
              label: const Text('Date',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 10, 10, 10))),
              onSort: (_, __) => _sortBy('date'),
            ),
            DataColumn(
              label: const Text('Téléphone',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 16, 16, 16))),
              onSort: (_, __) => _sortBy('phone'),
            ),
            DataColumn(
              label: const Text('Région',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 11, 11, 11))),
              onSort: (_, __) => _sortBy('region'),
            ),
            DataColumn(
              label: const Text('Genre',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 11, 11, 11))),
              onSort: (_, __) => _sortBy('genre'),
            ),
            const DataColumn(
              label: Text('Actions',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 14, 14, 14))),
            ),
          ],
          rows: displayedUsers.map((user) {
            final isSelected = user.id == _highlightedUserId;

            return DataRow(
              color: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
                  if (isSelected) {
                    return Colors.blue
                        .shade100; // Couleur de fond pour la ligne sélectionnée
                  }
                  if (displayedUsers.indexOf(user) % 2 == 0) {
                    return Colors.blue.shade50.withOpacity(0.3);
                  }
                  return Colors.white;
                },
              ),
              cells: [
                DataCell(Text(user.id ?? 'N/A',
                    style: const TextStyle(
                        color:
                            Color.fromARGB(255, 11, 11, 11)))), // Afficher l'ID
                DataCell(
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: user.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(user.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[200],
                    ),
                    child: user.imageUrl.isEmpty
                        ? Center(
                            child: Text(
                              '${user.nom.isNotEmpty ? user.nom[0] : ''}${user.prenom.isNotEmpty ? user.prenom[0] : ''}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
                DataCell(Text(user.nom,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 11, 11, 11)))),
                DataCell(Text(user.prenom,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 16, 16, 16)))),
                DataCell(Text(user.email,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 13, 13, 13)))),
                DataCell(Text(user.date,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 16, 16, 16)))),
                DataCell(Text(user.phone,
                    style:
                        const TextStyle(color: Color.fromARGB(255, 9, 9, 9)))),
                DataCell(Text(user.region,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 11, 11, 11)))),
                DataCell(Text(user.genre,
                    style: const TextStyle(
                        color: Color.fromARGB(255, 11, 11, 11)))),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(user),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteDialog(user),
                      tooltip: 'Supprimer',
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (_filteredUsers.isEmpty || _filteredUsers.length <= _usersPerPage) {
      return const SizedBox.shrink();
    }

    final int totalPages = (_filteredUsers.length / _usersPerPage).ceil();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Displaying range and total
          Text(
            'Affichage de ${_startIndex + 1} à $_endIndex sur ${_filteredUsers.length} utilisateurs',
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),

          // Page size selector
          Row(
            children: [
              const Text('Lignes par page: '),
              DropdownButton<int>(
                value: _usersPerPage,
                items: [5, 10, 20, 50, 100].map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _usersPerPage = value;
                      // Adjust current page if needed
                      int maxPage =
                          (_filteredUsers.length / _usersPerPage).ceil();
                      if (_currentPage > maxPage) {
                        _currentPage = maxPage;
                      }
                    });
                  }
                },
              ),
            ],
          ),

          // Pagination controls
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage = 1)
                    : null,
                tooltip: 'Première page',
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                tooltip: 'Page précédente',
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$_currentPage / $totalPages',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                tooltip: 'Page suivante',
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage = totalPages)
                    : null,
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(User user) async {
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;

    // Créez une copie de l'utilisateur pour éviter de modifier l'original avant confirmation
    final User userCopy = User(
      id: user.id,
      nom: user.nom,
      prenom: user.prenom,
      email: user.email,
      phone: user.phone,
      date: user.date,
      region: user.region,
      genre: user.genre,
      imageUrl: user.imageUrl,
      password: '', // Pas besoin de modifier le mot de passe dans l'édition
      status: user.status,
    );

    // Initialisez les contrôleurs avec les données existantes de l'utilisateur
    final TextEditingController _nomController =
        TextEditingController(text: userCopy.nom);
    final TextEditingController _prenomController =
        TextEditingController(text: userCopy.prenom);
    final TextEditingController _emailController =
        TextEditingController(text: userCopy.email);
    final TextEditingController _phoneController =
        TextEditingController(text: userCopy.phone);
    final TextEditingController _dateController =
        TextEditingController(text: userCopy.date);

    // Initialisez les valeurs sélectionnées
    String _selectedRegion = userCopy.region;
    String _selectedGenre = userCopy.genre;
    DateTime _selectedDate = DateTime.tryParse(userCopy.date) ?? DateTime.now();
    PlatformFile? _tempSelectedImage;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier l\'utilisateur'),
            content: Container(
              width: 600,
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Section de l'image de profil
                      Center(
                        child: Column(
                          children: [
                            FilePickerExample(
                              onImagePicked: (PlatformFile? file) {
                                setState(() {
                                  _tempSelectedImage = file;
                                });
                              },
                              initialImageUrl: userCopy.imageUrl,
                            ),
                            const SizedBox(height: 8),
                            const Text('Photo de profil'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Champs du formulaire
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nomController,
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _prenomController,
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un prénom';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Champ email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ téléphone
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un numéro de téléphone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Champ date de naissance
                      GestureDetector(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null && picked != _selectedDate) {
                            setState(() {
                              _selectedDate = picked;
                              _dateController.text = DateFormat('yyyy-MM-dd')
                                  .format(_selectedDate);
                            });
                          }
                        },
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une date';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sélection de la région et du genre
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Région',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedRegion,
                              items: Regions.list.map((region) {
                                return DropdownMenuItem(
                                  value: region,
                                  child: Text(region),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedRegion = value;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Genre',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedGenre,
                              items: ['Homme', 'Femme', 'Autre'].map((genre) {
                                return DropdownMenuItem(
                                  value: genre,
                                  child: Text(genre),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedGenre = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          // Démarrez le chargement
                          setState(() {
                            _isLoading = true;
                          });

                          try {
                            // Mettez à jour l'objet utilisateur avec les nouvelles valeurs
                            userCopy.nom = _nomController.text;
                            userCopy.prenom = _prenomController.text;
                            userCopy.email = _emailController.text;
                            userCopy.date = _dateController.text;
                            userCopy.region = _selectedRegion;
                            userCopy.genre = _selectedGenre;
                            userCopy.phone = _phoneController.text;

                            // Si une nouvelle image est sélectionnée, téléchargez-la
                            if (_tempSelectedImage != null) {
                              final imageUrl = await _uploadImageAndGetUrl(
                                _tempSelectedImage,
                                _emailController.text,
                              );
                              // Mettez à jour l'URL de l'image de l'utilisateur
                              userCopy.imageUrl = imageUrl;
                            }

                            // Mettez à jour l'utilisateur dans la base de données
                            await _controller.updateUser(userCopy);

                            // Mettez à jour l'utilisateur original avec les nouvelles valeurs
                            user.nom = userCopy.nom;
                            user.prenom = userCopy.prenom;
                            user.email = userCopy.email;
                            user.date = userCopy.date;
                            user.region = userCopy.region;
                            user.genre = userCopy.genre;
                            user.phone = userCopy.phone;
                            user.imageUrl = userCopy.imageUrl;

                            // Affichez un message de succès
                            _showSnackBar('Utilisateur modifié avec succès');

                            // Forcez le rafraîchissement de l'interface utilisateur
                            if (mounted) {
                              _controller.fetchUsers().then((_) {
                                if (mounted) {
                                  setState(() {
                                    _filterUsers();
                                  });
                                }
                              }).catchError((error) {
                                print(
                                    "Erreur lors du rafraîchissement des utilisateurs: $error");
                              });
                            }

                            // Fermez la boîte de dialogue
                            Navigator.pop(dialogContext);
                          } catch (e) {
                            // Affichez un message d'erreur
                            _showSnackBar('Erreur: ${e.toString()}',
                                isError: true);
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        }
                      },
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );

    // Forcez le rafraîchissement après la fermeture de la boîte de dialogue
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _showDeleteDialog(User user) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${user.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Annuler la suppression
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Supprimer l'utilisateur via le contrôleur
                await _controller.deleteUser(user.email);

                // Mettre à jour l'état immédiatement sans recharger la page
                setState(() {
                  _controller.users.removeWhere((u) =>
                      u.email ==
                      user.email); // Retirer l'utilisateur de la liste
                  _filterUsers(); // Re-filtrer la liste pour refléter les changements
                });

                // Afficher un message de succès
                _showSnackBar('Utilisateur supprimé avec succès');

                // Fermer la boîte de dialogue
                Navigator.pop(context);
              } catch (e) {
                // En cas d'erreur, afficher un message d'erreur
                _showSnackBar('Erreur lors de la suppression : ${e.toString()}',
                    isError: true);
                Navigator.pop(
                    context); // Fermer la boîte de dialogue même en cas d'erreur
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<String> _uploadImageAndGetUrl(
      PlatformFile? imageFile, String email) async {
    if (imageFile == null) {
      return '';
    }

    try {
      if (kIsWeb) {
        // For web, use the bytes of the image
        if (imageFile.bytes != null) {
          final imageUrl = await _controller.uploadImageWeb(
            imageFile.bytes!,
            imageFile.name,
            email,
          );
          return imageUrl;
        }
      } else {
        // For mobile, use the file path
        final file = File(imageFile.path!);
        final imageUrl = await _controller.uploadImage(file, email);
        return imageUrl;
      }

      return '';
    } catch (e) {
      print('Error uploading image: $e');
      _showSnackBar('Erreur de téléchargement de l\'image: ${e.toString()}',
          isError: true);
      return '';
    }
  }
}
