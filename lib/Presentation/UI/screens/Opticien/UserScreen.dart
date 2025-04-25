import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';

import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';

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

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Palette de couleurs pour un design cohérent
  final Color _primaryColor = const Color.fromARGB(255, 84, 151, 198);

  final Color _lightPrimaryColor = const Color(0xFFC5CAE9);
  final Color _backgroundColor = const Color(0xFFF5F7FA);

  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);
  // Professional color palette (identique à la page boutique)

  final Color _errorColor = Color(0xFFD32F2F); // Error red

  final Color _infoColor = Color(0xFF1976D2); // Info blue
  // Pagination
  int _currentPage = 1;
  final int _usersPerPage = 10;
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
  final Map<String, String?> _filters = {
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
    // Schedule the data loading after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOpticianUsers();
    });
  }

  Future<void> _loadOpticianUsers() async {
    try {
      final opticianController = Get.find<OpticianController>();
      final orderController = Get.find<OrderController>();

      // Récupérer l'ID de l'opticien connecté
      final opticianId = opticianController.currentUserId.value;

      final users = await orderController.getUsersByOptician(opticianId);

      setState(() {
        _controller.users.assignAll(users);
        _filterUsers();
      });
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Row(
          children: [
            CustomSidebar(currentPage: 'Users'),
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Barre de recherche et filtres
                      _buildSearchFilterBar(),

                      SizedBox(height: 16),
                      if (_showFilters) _buildAdvancedFilters(),
                      const SizedBox(height: 24),
                      Expanded(child: _buildDataTable()),
                      const SizedBox(height: 16),
                      _buildPagination(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Utilisateurs',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${_filteredUsers.length} utilisateurs',
              style: TextStyle(
                fontSize: 14,
                color: _textSecondaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchFilterBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _currentSearchTerm =
                            value; // Mettez à jour _currentSearchTerm
                      });
                      _filterUsers(); // Appelez la méthode de filtrage
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher un utilisateur...',
                      prefixIcon:
                          Icon(Icons.search, color: _textSecondaryColor),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                  icon: Icon(
                      _showFilters ? Icons.filter_alt_off : Icons.filter_alt),
                  label: Text(_showFilters ? 'Cacher Filtres' : 'Filtres'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: _primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            if (_searchController.text.isNotEmpty || _showFilters)
              Padding(
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Chip(
                      label: Text('${_filteredUsers.length} résultats'),
                      backgroundColor: _primaryColor.withOpacity(0.1),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: _resetFilters,
                      child: Text(
                        'Réinitialiser',
                        style: TextStyle(color: _errorColor),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: EdgeInsets.only(top: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: _primaryColor),
                SizedBox(width: 8),
                Text(
                  'Filtres Avancés',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildFilterField(
                  label: 'Nom',
                  value: _filters['nom'],
                  icon: Icons.person,
                  onChanged: (value) => setState(() {
                    _filters['nom'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Prénom',
                  value: _filters['prenom'],
                  icon: Icons.person_outline,
                  onChanged: (value) => setState(() {
                    _filters['prenom'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Email',
                  value: _filters['email'],
                  icon: Icons.email,
                  onChanged: (value) => setState(() {
                    _filters['email'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Téléphone',
                  value: _filters['phone'],
                  icon: Icons.phone,
                  onChanged: (value) => setState(() {
                    _filters['phone'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Date de naissance',
                  value: _filters['date'],
                  icon: Icons.calendar_today,
                  onChanged: (value) => setState(() {
                    _filters['date'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Région',
                  value: _filters['region'],
                  icon: Icons.location_on,
                  onChanged: (value) => setState(() {
                    _filters['region'] = value;
                    _filterUsers();
                  }),
                ),
                _buildFilterField(
                  label: 'Genre',
                  value: _filters['genre'],
                  icon: Icons.people,
                  onChanged: (value) => setState(() {
                    _filters['genre'] = value;
                    _filterUsers();
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterField({
    required String label,
    required String? value,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return SizedBox(
      width: 250,
      child: TextField(
        controller: TextEditingController(text: value ?? ''),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildDataTable() {
    return Padding(
      padding: const EdgeInsets.all(8.0), // Réduire le padding
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            // Header - sans défilement horizontal
            Container(
              padding: EdgeInsets.symmetric(
                  vertical: 8, horizontal: 4), // Padding réduit
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: _buildUserTableHeader(),
            ),

            // Data rows - sans défilement horizontal
            Expanded(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filteredUsers.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return Container(
                    padding: EdgeInsets.symmetric(
                        vertical: 6, horizontal: 4), // Padding réduit
                    color: index.isEven ? Colors.white : Colors.grey[50],
                    child: _buildUserTableRow(user),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTableHeader() {
    final columns = [
      TableColumn(
          flex: 6, label: 'Photo', icon: Icons.photo_camera), // Flex réduit
      TableColumn(
          flex: 8, label: 'Nom', icon: Icons.person_outline), // Flex réduit
      TableColumn(
          flex: 8, label: 'Prénom', icon: Icons.person_outline), // Flex réduit
      TableColumn(
          flex: 12, label: 'Email', icon: Icons.email_outlined), // Flex réduit
      TableColumn(
          flex: 7,
          label: 'Téléphone',
          icon: Icons.phone_outlined), // Flex réduit
      TableColumn(
          flex: 8,
          label: 'Naiss.',
          icon: Icons.cake_outlined), // Label raccourci
      TableColumn(
          flex: 7,
          label: 'Région',
          icon: Icons.location_on_outlined), // Flex réduit
      TableColumn(
          flex: 7, label: 'Genre', icon: Icons.transgender), // Flex réduit
      TableColumn(
          flex: 6,
          label: 'Actions',
          icon: Icons.settings,
          isActions: true), // Flex réduit
    ];

    return Row(
      children: columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2), // Padding réduit
            child: Tooltip(
              message: col.label,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(col.icon,
                      size: 14, color: _primaryColor), // Taille réduite
                  SizedBox(width: 2), // Espace réduit
                  Flexible(
                    child: Text(
                      col.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _textPrimaryColor,
                        fontSize: 13, // Taille réduite
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserTableRow(User user) {
    return Row(
      children: [
        // Photo - taille réduite
        Expanded(
          flex: 6,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: CircleAvatar(
              radius: 44, // Taille réduite
              backgroundColor: _primaryColor.withOpacity(0.1),
              backgroundImage: (user.imageUrl.isNotEmpty)
                  ? NetworkImage(user.imageUrl!)
                  : null,
              child: user.imageUrl.isEmpty
                  ? Text(
                      '${user.nom.isNotEmpty ? user.nom[0] : ''}${user.prenom.isNotEmpty ? user.prenom[0] : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // Nom
        Expanded(
          flex: 8,
          child: _buildTableCell(
            icon: Icons.person_outline,
            text: user.nom,
            isImportant: true,
          ),
        ),

        // Prénom
        Expanded(
          flex: 8,
          child: _buildTableCell(
            icon: Icons.person_outline,
            text: user.prenom,
          ),
        ),

        // Email
        Expanded(
          flex: 12,
          child: _buildTableCell(
            icon: Icons.email_outlined,
            text: user.email,
          ),
        ),

        // Téléphone
        Expanded(
          flex: 7,
          child: _buildTableCell(
            icon: Icons.phone_outlined,
            text: user.phone,
          ),
        ),

        // Date de naissance
        Expanded(
          flex: 8,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2),
            child: Builder(
              builder: (context) {
                String displayDate = user.date;
                try {
                  final parsedDate = DateTime.parse(user.date);
                  displayDate =
                      DateFormat('dd/MM/yy').format(parsedDate); // Format court
                } catch (e) {
                  displayDate = user.date.length > 6
                      ? '${user.date.substring(0, 6)}...'
                      : user.date;
                }

                return Tooltip(
                  message: user.date,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cake_outlined,
                          size: 12, color: _textSecondaryColor),
                      SizedBox(width: 2),
                      Text(
                        displayDate,
                        style: TextStyle(fontSize: 10), // Taille réduite
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // Région
        Expanded(
          flex: 7,
          child: _buildTableCell(
            icon: Icons.location_on_outlined,
            text: user.region.length > 8
                ? '${user.region.substring(0, 7)}...'
                : user.region,
          ),
        ),

        // Genre
        Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.only(right: 4),
            child: Tooltip(
              message: user.genre,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getGenderIcon(user.genre),
                    size: 16,
                    color: _getGenderColor(user.genre),
                  ),
                  SizedBox(width: 4), // Espace entre l'icône et le texte
                  Text(
                    user.genre, // Affiche le genre ou un texte par défaut
                    style: TextStyle(
                        fontSize: 12), // Ajustez la taille si nécessaire
                  ),
                ],
              ),
            ),
          ),
        ),

        // Actions
        Expanded(
          flex: 6,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit,
                    size: 14, color: _infoColor), // Taille réduite
                onPressed: () => _showEditDialog(user),
                padding: EdgeInsets.zero,
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: Icon(Icons.delete,
                    size: 14, color: _errorColor), // Taille réduite
                onPressed: () => _showDeleteDialog(user),
                padding: EdgeInsets.zero,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getGenderIcon(String? gender) {
    if (gender == null || gender.isEmpty) return Icons.question_mark;
    return gender.toLowerCase().contains('femme') ? Icons.female : Icons.male;
  }

  Color _getGenderColor(String? gender) {
    if (gender == null || gender.isEmpty) return Colors.grey;
    return gender.toLowerCase().contains('femme') ? Colors.pink : Colors.blue;
  }

  Widget _buildTableCell(
      {required IconData icon,
      required String text,
      bool isImportant = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2), // Padding réduit
      child: Tooltip(
        message: text,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: _textSecondaryColor), // Taille réduite
            SizedBox(width: 2), // Espace réduit
            Flexible(
              child: Text(
                text.length > 10 ? '${text.substring(0, 9)}...' : text,
                style: TextStyle(
                  fontSize: 13, // Taille réduite
                  fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
                  color: isImportant ? _textPrimaryColor : _textSecondaryColor,
                ),
              ),
            ),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage de ${_startIndex + 1} à $_endIndex sur ${_filteredUsers.length} utilisateurs',
            style: TextStyle(color: Colors.grey[700]),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage = 1)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
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
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage = totalPages)
                    : null,
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
    final TextEditingController _dateController = TextEditingController(
      text: user?.date != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(user!.date))
          : '',
    );
    final TextEditingController _passwordController =
        TextEditingController(); // Nouveau contrôleur pour le mot de passe

    // Initialisez les valeurs sélectionnées
    String _selectedRegion = userCopy.region;
    String _selectedGenre = userCopy.genre;
    DateTime _selectedDate =
        DateTime.tryParse(user?.date ?? '') ?? DateTime.now();
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
                                hintText: 'Entrez le nom de famille',
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
                                hintText: 'Entrez le prénom',
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
                          hintText: 'exemple@gmail.com',
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

                      // Champ de mot de passe (optionnel pour la modification)
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe (optionnel)',
                          border: OutlineInputBorder(),
                          hintText:
                              'Minimum 8 caractères avec majuscule, chiffre et caractère spécial',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null; // Le mot de passe est optionnel lors de la modification
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
                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]')
                              .hasMatch(value)) {
                            return 'Le mot de passe doit contenir au moins un caractère spécial';
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
                          hintText: '8 chiffres',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer un numéro de téléphone';
                          }
                          if (value.length != 8 ||
                              !RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                            return 'Le téléphone doit contenir exactement 8 chiffres';
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
                              hintText: 'Minimum 13 ans',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une date';
                              }

                              // Vérifier que l'utilisateur a au moins 13 ans
                              final selectedDate = DateTime.tryParse(value);
                              if (selectedDate != null) {
                                final today = DateTime.now();
                                final age = today.year -
                                    selectedDate.year -
                                    (today.month < selectedDate.month ||
                                            (today.month ==
                                                    selectedDate.month &&
                                                today.day < selectedDate.day)
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

                            // Mettez à jour le mot de passe uniquement s'il a été modifié
                            if (_passwordController.text.isNotEmpty) {
                              userCopy.password = _passwordController.text;
                            }

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
                            if (_passwordController.text.isNotEmpty) {
                              user.password = userCopy.password;
                            }

                            // Affichez un message de succès
                            _showSnackBar('Utilisateur modifié avec succès');

                            // Forcez le rafraîchissement de l'interface utilisateur
                            // Dans la partie où vous gérez le succès de la mise à jour
// Remplacez votre appel à fetchUsers suivi de setState par:

                            if (mounted) {
                              // Option 1: Mettre à jour directement la liste _filteredUsers si elle existe
                              final index = _controller.users
                                  .indexWhere((u) => u.id == user.id);
                              if (index != -1) {
                                setState(() {
                                  // Mise à jour de l'utilisateur dans la liste du contrôleur
                                  _controller.users[index] = user;

                                  // Ré-appliquer le filtre pour mettre à jour _filteredUsers
                                  _filterUsers();
                                });
                              } else {
                                // Si l'utilisateur n'est pas trouvé, rechargez la liste complète
                                _controller.fetchUsers().then((_) {
                                  if (mounted) {
                                    setState(() {
                                      _filterUsers();
                                    });
                                  }
                                });
                              }
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

class TableColumn {
  final int flex;
  final String label;
  final IconData icon;
  final bool isActions;

  TableColumn({
    required this.flex,
    required this.label,
    required this.icon,
    this.isActions = false,
  });
}
