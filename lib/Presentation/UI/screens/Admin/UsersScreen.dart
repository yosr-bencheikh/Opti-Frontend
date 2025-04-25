import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';

import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';

import 'package:opti_app/Presentation/widgets/paginationcontrols.dart';
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
  final Color _primaryColor = const Color.fromARGB(255, 33, 199, 146);
  final Color _secondaryColor = const Color.fromARGB(255, 16, 16, 17);
  final Color _accentColor = const Color(0xFFFF4081);
  final Color _lightPrimaryColor = const Color(0xFFC5CAE9);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);
  final Color _errorColor = Color(0xFFD32F2F); // Error red
  final Color _infoColor = Color(0xFF1976D2); // Info blue

  // Pagination
  int _currentPage = 0;

  final int _usersPerPage = 10;
  int _startIndex = 0;
  int _endIndex = 0;

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

    // Charger les utilisateurs et mettre à jour les indices une fois les données disponibles
    _loadUsers().then((_) {
      if (mounted) {
        setState(() {
          _updateIndices();
        });
      }
    });
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

  void _updateIndices() {
    _startIndex = _currentPage * _usersPerPage;
    _endIndex = min(_startIndex + _usersPerPage, _filteredUsers.length);
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchTerm = _searchController.text;
      _filterUsers(); // Cette ligne est cruciale
      _currentPage = 1;
      _updateIndices();
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
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                  _buildDataTable(),
                  const SizedBox(height: 16),

                  // Use the PaginationControls widget
                  PaginationControls(
                    currentPage: _currentPage,
                    totalItems: _filteredUsers.length,
                    itemsPerPage: _usersPerPage,
                    onPageChanged: (newPage) {
                      setState(() {
                        _currentPage = newPage;
                        _updateIndices(); // Update indices if needed
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              mainAxisSize: MainAxisSize.min, // Important to prevent overflow
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _currentSearchTerm = value;
                          });
                          _filterUsers();
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
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Container(
                      constraints: BoxConstraints(
                        maxWidth:
                            constraints.maxWidth * 0.3, // Limit button width
                      ),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                        },
                        icon: Icon(
                          _showFilters
                              ? Icons.filter_alt_off
                              : Icons.filter_alt,
                          size: 20,
                        ),
                        label: Text(
                          _showFilters ? 'Cacher Filtres' : 'Filtres',
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          side: BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_searchController.text.isNotEmpty || _showFilters)
                  Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text('${_filteredUsers.length} résultats'),
                          backgroundColor: _primaryColor.withOpacity(0.1),
                        ),
                        TextButton(
                          onPressed: _resetFilters,
                          child: Text(
                            'Réinitialiser',
                            style: TextStyle(color: _errorColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
    // Nouvelle palette premium
    final Color _primaryColor = Color(0xFF006D77); // Bleu-vert profond
    final Color _accentColor = const Color.fromARGB(255, 33, 199, 146);
    final Color _lightBg = Color(0xFFEDF6F9); // Fond très clair
    final Color _textPrimary = Color(0xFF1E1E1E); // Noir riche
    final Color _textSecondary = Color(0xFF5E5E5E); // Gris foncé

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      decoration: BoxDecoration(
        color: _lightBg,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_lightBg, Colors.white],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Gestion des ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    'Utilisateurs',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _primaryColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '${_controller.users.length} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Utilisateur enregistrés',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(null),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                'Nouvel utilisateur',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                shadowColor: Colors.transparent,
              ),
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
      padding: const EdgeInsets.all(12),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth > 800;
          final isMediumScreen = constraints.maxWidth > 600;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_alt, color: _primaryColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Filtres',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                if (isWideScreen) _buildWideScreenFilters(),
                if (isMediumScreen && !isWideScreen)
                  _buildMediumScreenFilters(),
                if (!isMediumScreen && !isWideScreen)
                  _buildSmallScreenFilters(),
              ],
            ),
          );
        },
      ),
    );
  }

// Filter layout variations
  Widget _buildWideScreenFilters() {
    return Column(
      children: [
        _buildFilterRow([
          _buildCompactFilterTextField(
              label: 'Nom', icon: Icons.person, filterKey: 'nom'),
          _buildCompactFilterTextField(
              label: 'Prénom', icon: Icons.person_outline, filterKey: 'prenom'),
          _buildCompactFilterTextField(
              label: 'Email', icon: Icons.email_outlined, filterKey: 'email'),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              filterKey: 'phone'),
          _buildCompactFilterTextField(
              label: 'Date',
              hintText: 'YYYY-MM-DD',
              icon: Icons.calendar_today,
              filterKey: 'date'),
          _buildCompactDropdown(
              label: 'Région',
              icon: Icons.location_on_outlined,
              filterKey: 'region'),
          _buildCompactDropdown(
              label: 'Genre', icon: Icons.people_outline, filterKey: 'genre'),
        ]),
      ],
    );
  }

  Widget _buildMediumScreenFilters() {
    return Column(
      children: [
        _buildFilterRow([
          _buildCompactFilterTextField(
              label: 'Nom', icon: Icons.person, filterKey: 'nom'),
          _buildCompactFilterTextField(
              label: 'Prénom', icon: Icons.person_outline, filterKey: 'prenom'),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
              label: 'Email', icon: Icons.email_outlined, filterKey: 'email'),
          _buildCompactFilterTextField(
              label: 'Téléphone',
              icon: Icons.phone_outlined,
              filterKey: 'phone'),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactFilterTextField(
              label: 'Date',
              hintText: 'YYYY-MM-DD',
              icon: Icons.calendar_today,
              filterKey: 'date'),
          _buildCompactDropdown(
              label: 'Région',
              icon: Icons.location_on_outlined,
              filterKey: 'region'),
        ]),
        const SizedBox(height: 12),
        _buildFilterRow([
          _buildCompactDropdown(
              label: 'Genre', icon: Icons.people_outline, filterKey: 'genre'),
          const Spacer(),
        ]),
      ],
    );
  }

  Widget _buildSmallScreenFilters() {
    return Column(
      children: [
        _buildCompactFilterTextField(
            label: 'Nom', icon: Icons.person, filterKey: 'nom'),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
            label: 'Prénom', icon: Icons.person_outline, filterKey: 'prenom'),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
            label: 'Email', icon: Icons.email_outlined, filterKey: 'email'),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
            label: 'Téléphone', icon: Icons.phone_outlined, filterKey: 'phone'),
        const SizedBox(height: 8),
        _buildCompactFilterTextField(
            label: 'Date',
            hintText: 'YYYY-MM-DD',
            icon: Icons.calendar_today,
            filterKey: 'date'),
        const SizedBox(height: 8),
        _buildCompactDropdown(
            label: 'Région',
            icon: Icons.location_on_outlined,
            filterKey: 'region'),
        const SizedBox(height: 8),
        _buildCompactDropdown(
            label: 'Genre', icon: Icons.people_outline, filterKey: 'genre'),
      ],
    );
  }

// Form field builders
  Widget _buildCompactFilterTextField({
    required String label,
    required IconData icon,
    required String filterKey,
    String? hintText,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: TextField(
        controller: TextEditingController(text: _filters[filterKey]),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText ?? 'Filtrer par $label',
          prefixIcon: Icon(icon, size: 16),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          isDense: true,
        ),
        onChanged: (value) => _updateFilter(filterKey, value),
      ),
    );
  }

  Widget _buildCompactDropdown({
    required String label,
    required IconData icon,
    required String filterKey,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 16),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          isDense: true,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _filters[filterKey],
            items: filterKey == 'region'
                ? _buildRegionDropdownItems()
                : _buildGenderDropdownItems(),
            onChanged: (value) => _updateFilter(filterKey, value),
            isExpanded: true,
            isDense: true,
            hint: const Text('Sélectionner', style: TextStyle(fontSize: 12)),
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ),
      ),
    );
  }

// Helper methods
  Widget _buildFilterRow(List<Widget> children) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children
          .map((child) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: child,
                ),
              ))
          .toList(),
    );
  }

  List<DropdownMenuItem<String>> _buildRegionDropdownItems() {
    return [
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
    ];
  }

  List<DropdownMenuItem<String>> _buildGenderDropdownItems() {
    return [
      const DropdownMenuItem<String>(
        value: null,
        child: Text('Tous les genres'),
      ),
      ...['Homme', 'Femme'].map((genre) {
        return DropdownMenuItem<String>(
          value: genre,
          child: Text(genre),
        );
      }).toList(),
    ];
  }

  void _updateFilter(String key, String? value) {
    setState(() {
      _filters[key] = value;
      _filterUsers();
      _currentPage = 1;
    });
  }

  Widget _buildDataTable() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          elevation: 6,
          child: Column(
            children: [
              // En-tête du tableau
              _buildUserTableHeader(),

              // Corps du tableau avec défilement
              Container(
                constraints: BoxConstraints(
                  maxHeight:
                      constraints.maxHeight * 0.7, // 70% de l'espace disponible
                ),
                child: Scrollbar(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: _buildUserTableBody(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUserTableBody() {
    final currentPageUsers = _filteredUsers.sublist(
      _startIndex,
      _endIndex.clamp(0, _filteredUsers.length),
    );
    final displayedusers = _getDisplayedUsers();
    return Scrollbar(
      child: ListView.builder(
        shrinkWrap: true,
        physics: AlwaysScrollableScrollPhysics(),
        itemCount: displayedusers.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color:
                  index.isEven ? Colors.white : Colors.grey.withOpacity(0.02),
            ),
            child: _buildUserTableRow(displayedusers[index]),
          );
        },
      ),
    );
  }

  List<User> _getDisplayedUsers() {
    // Check if the list is empty to avoid range errors
    if (_filteredUsers.isEmpty) {
      return [];
    }

    // Calculate proper start index with bounds checking
    final startIndex = _currentPage * _usersPerPage;

    // If start index is now beyond the list bounds, adjust the current page
    if (startIndex >= _filteredUsers.length) {
      // Reset to the last valid page
      _currentPage = (_filteredUsers.length - 1) ~/ _usersPerPage;
      // Recalculate start index
      final newStartIndex = _currentPage * _usersPerPage;
      final endIndex =
          min(newStartIndex + _usersPerPage, _filteredUsers.length);
      return _filteredUsers.sublist(newStartIndex, endIndex);
    }

    // Normal case
    final endIndex = min(startIndex + _usersPerPage, _filteredUsers.length);
    return _filteredUsers.sublist(startIndex, endIndex);
  }

  Widget _buildUserTableHeader() {
    final columns = [
      TableColumn(flex: 5, label: 'Photo', icon: Icons.photo_camera),
      TableColumn(flex: 8, label: 'Nom', icon: Icons.person_outline),
      TableColumn(flex: 8, label: 'Prénom', icon: Icons.person_outline),
      TableColumn(flex: 12, label: 'Email', icon: Icons.email_outlined),
      TableColumn(flex: 7, label: 'Téléphone', icon: Icons.phone_outlined),
      TableColumn(flex: 7, label: 'Naissance', icon: Icons.cake_outlined),
      TableColumn(flex: 6, label: 'Région', icon: Icons.location_on_outlined),
      TableColumn(flex: 5, label: 'Genre', icon: Icons.transgender),
      TableColumn(
          flex: 5, label: 'Actions', icon: Icons.more_vert, isActions: true),
    ];

    return Row(
      children: columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: col.label,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  // Tri des colonnes
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(col.icon,
                          size: 16, color: _primaryColor.withOpacity(0.7)),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          col.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _textPrimaryColor.withOpacity(0.9),
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (col.isActions)
                        SizedBox.shrink()
                      else
                        Icon(
                          Icons.unfold_more,
                          size: 14,
                          color: Colors.grey.shade400,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildUserTableRow(User user) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Photo
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: 'Profil de ${user.prenom} ${user.nom}',
              child: CircleAvatar(
                radius: 44,
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
        ),

        // Nom
        Expanded(
          flex: 8,
          child: _buildTableCell(
            text: user.nom,
            isImportant: true,
            maxChars: 15,
          ),
        ),

        // Prénom
        Expanded(
          flex: 8,
          child: _buildTableCell(
            text: user.prenom,
            maxChars: 15,
          ),
        ),

        // Email
        Expanded(
          flex: 12,
          child: _buildTableCell(
            text: user.email,
            icon: Icons.email_outlined,
            isEmail: true,
          ),
        ),

        // Téléphone
        Expanded(
          flex: 7,
          child: _buildTableCell(
            text: user.phone,
            icon: Icons.phone_outlined,
          ),
        ),

        // Date de naissance
        Expanded(
          flex: 7,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Builder(
              builder: (context) {
                String displayDate = "N/A";
                try {
                  final parsedDate = DateTime.parse(user.date);
                  displayDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                } catch (e) {
                  displayDate = user.date;
                }

                return Tooltip(
                  message: displayDate,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cake_outlined,
                          size: 14,
                          color: _textSecondaryColor.withOpacity(0.7)),
                      SizedBox(width: 6),
                      Text(
                        displayDate.length > 10
                            ? '${displayDate.substring(0, 10)}...'
                            : displayDate,
                        style: TextStyle(
                          fontSize: 12,
                          color: _textSecondaryColor,
                        ),
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
          flex: 6,
          child: _buildTableCell(
            text: user.region,
            maxChars: 10,
          ),
        ),

        // Genre
        Expanded(
          flex: 5,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: user.genre ?? 'Non spécifié',
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                decoration: BoxDecoration(
                  color: _getGenderColor(user.genre).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getGenderIcon(user.genre),
                      size: 14,
                      color: _getGenderColor(user.genre),
                    ),
                    SizedBox(width: 4),
                    Text(
                      _getGenderAbbreviation(user.genre),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _getGenderColor(user.genre),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Actions
        Expanded(
          flex: 5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                icon: Icons.edit_outlined,
                color: _infoColor,
                tooltip: 'Modifier',
                onPressed: () => _showEditDialog(user),
              ),
              SizedBox(width: 4),
              _buildActionButton(
                icon: Icons.delete_outline,
                color: _errorColor,
                tooltip: 'Supprimer',
                onPressed: () => _showDeleteDialog(user),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell({
    required String text,
    IconData? icon,
    bool isImportant = false,
    bool isEmail = false,
    int? maxChars,
  }) {
    final displayText = maxChars != null && text.length > maxChars
        ? '${text.substring(0, maxChars)}...'
        : text;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: text,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: _textSecondaryColor.withOpacity(0.6)),
              SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                displayText.isNotEmpty ? displayText : '-',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isImportant ? FontWeight.w600 : FontWeight.normal,
                  color: isImportant ? _textPrimaryColor : _textSecondaryColor,
                  fontStyle: displayText.isEmpty ? FontStyle.italic : null,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: color,
        onPressed: onPressed,
        tooltip: tooltip,
        splashRadius: 20,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

// Helper functions
  IconData _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'homme':
        return Icons.male;
      case 'femme':
        return Icons.female;
      default:
        return Icons.transgender;
    }
  }

  Color _getGenderColor(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'homme':
        return Colors.blue.shade600;
      case 'femme':
        return Colors.pink.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _getGenderAbbreviation(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'homme':
        return 'H';
      case 'femme':
        return 'F';
      default:
        return '?';
    }
  }

  int get _pageCount {
    return (_filteredUsers.length / _usersPerPage).ceil();
  }

  Widget _buildPaginationControls() {
    final totalPages = _pageCount;
    if (totalPages <= 1) return SizedBox();

    return Padding(
      padding: EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          SizedBox(width: 16),
          Text(
            'Page ${_currentPage + 1} sur $totalPages',
            style: TextStyle(
              color: _textSecondaryColor,
            ),
          ),
          SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _showAddUserDialog(User? user) async {
    final _formKey = GlobalKey<FormState>();

    // Create a new user object (similar to userCopy in edit)
    final User newUser = User(
      nom: user?.nom ?? '',
      prenom: user?.prenom ?? '',
      email: user?.email ?? '',
      phone: user?.phone ?? '',
      date: user?.date ?? '',
      region: user?.region ?? Regions.list.first,
      genre: user?.genre ?? 'Homme',
      imageUrl: user?.imageUrl ?? '',
      password: '',
      status: 'Active',
      id: user?.id ?? '',
    );

    // Form controllers initialized with newUser data
    final TextEditingController _nomController =
        TextEditingController(text: newUser.nom);
    final TextEditingController _prenomController =
        TextEditingController(text: newUser.prenom);
    final TextEditingController _emailController =
        TextEditingController(text: newUser.email);
    final TextEditingController _phoneController =
        TextEditingController(text: newUser.phone);
    final TextEditingController _passwordController = TextEditingController();
    final TextEditingController _dateController = TextEditingController(
      text: newUser.date.isNotEmpty
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(newUser.date))
          : '',
    );
    bool _isLoading = false;

    // Selection variables
    String _selectedRegion =
        newUser.region.isNotEmpty ? newUser.region : Regions.list.first;
    String _selectedGenre = newUser.genre.isNotEmpty ? newUser.genre : 'Homme';
    DateTime _selectedDate = DateTime.tryParse(newUser.date) ?? DateTime.now();
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
                    Text(
                      user == null
                          ? 'Ajouter un utilisateur'
                          : 'Modifier l\'utilisateur',
                      style: const TextStyle(
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
                                      child: Center(
                                        child: Column(
                                          children: [
                                            FilePickerExample(
                                              onImagePicked:
                                                  (PlatformFile? file) {
                                                setState(() {
                                                  _tempSelectedImage = file;
                                                });
                                              },
                                            ),
                                            const SizedBox(height: 8),
                                            const Text('Photo de profil'),
                                          ],
                                        ),
                                      ),
                                    ),
                                   
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
                                      // Update the User object with form values
                                      newUser.nom = _nomController.text;
                                      newUser.prenom = _prenomController.text;
                                      newUser.email = _emailController.text;
                                      newUser.date = DateFormat('yyyy-MM-dd')
                                          .format(_selectedDate);
                                      newUser.region = _selectedRegion;
                                      newUser.genre = _selectedGenre;
                                      newUser.password =
                                          _passwordController.text;
                                      newUser.phone = _phoneController.text;
                                      newUser.status = 'Active';

                                      // OPTIMISTIC UI UPDATE: Add to local list first
                                      if (mounted) {
                                        setState(() {
                                          // Set a temporary imageUrl for UI purposes if image is selected
                                          if (_tempSelectedImage != null) {
                                            // If possible, show a local preview URL
                                            // This depends on your FilePickerExample implementation
                                            // newUser.imageUrl = 'temp-preview-url';
                                            newUser.imageUrl =
                                                'imageUrl'; // Temporary value
                                          }

                                          _controller.users.add(newUser);
                                          _filterUsers(); // Filter if needed
                                        });
                                      }

                                      // Send API request in background
                                      await _controller.addUser(newUser);

                                      // Handle image upload and update if necessary
                                      if (_tempSelectedImage != null) {
                                        final imageURL =
                                            await _uploadImageAndGetUrl(
                                          _tempSelectedImage,
                                          _emailController.text,
                                        );

                                        // Update image URL in the local list
                                        if (mounted) {
                                          setState(() {
                                            final index = _controller.users
                                                .indexWhere((u) =>
                                                    u.email == newUser.email);
                                            if (index != -1) {
                                              _controller.users[index]
                                                  .imageUrl = imageURL;
                                              _filterUsers();
                                            }
                                          });
                                        }
                                        newUser.imageUrl = imageURL;
                                      }

                                      // If new user, get the complete user with ID from backend
                                      if (user == null) {
                                        final completeUser =
                                            await _authController
                                                .getUserByEmail(newUser.email);
                                        newUser.id = completeUser['_id'] ??
                                            completeUser['id'] ??
                                            '';

                                        // Update the ID in the local list
                                        if (mounted) {
                                          setState(() {
                                            final index = _controller.users
                                                .indexWhere((u) =>
                                                    u.email == newUser.email);
                                            if (index != -1) {
                                              _controller.users[index].id =
                                                  newUser.id;
                                            }
                                          });
                                        }
                                      }

                                      // Close the dialog
                                      Navigator.pop(dialogContext);

                                      // Show success message
                                      _showSnackBar(
                                          'Utilisateur ajouté avec succès');

                                      // Refresh data in background for synchronization
                                      _controller.fetchUsers().then((_) {
                                        if (mounted) {
                                          setState(() {
                                            _filterUsers();
                                          });
                                        }
                                      });
                                    } catch (e) {
                                      // In case of error, remove the locally added user
                                      if (mounted) {
                                        setState(() {
                                          _controller.users.removeWhere(
                                              (u) => u.email == newUser.email);
                                          _filterUsers();
                                        });
                                      }
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
                            // 1. Mettre à jour la copie locale avec les nouvelles valeurs
                            userCopy.nom = _nomController.text;
                            userCopy.prenom = _prenomController.text;
                            userCopy.email = _emailController.text;
                            userCopy.date = _dateController.text;
                            userCopy.region = _selectedRegion;
                            userCopy.genre = _selectedGenre;
                            userCopy.phone = _phoneController.text;

                            // 2. Mise à jour OPTIMISTE de l'UI avant l'appel API
                            final index = _controller.users
                                .indexWhere((u) => u.id == user.id);
                            if (index != -1 && mounted) {
                              setState(() {
                                _controller.users[index] = userCopy;
                                _filterUsers(); // Si vous utilisez un filtrage
                              });
                            }

                            // 3. Gestion du mot de passe (si modifié)
                            if (_passwordController.text.isNotEmpty) {
                              userCopy.password = _passwordController.text;
                            }

                            // 4. Téléchargement de l'image si nécessaire
                            if (_tempSelectedImage != null) {
                              final imageUrl = await _uploadImageAndGetUrl(
                                _tempSelectedImage,
                                _emailController.text,
                              );
                              userCopy.imageUrl = imageUrl;

                              // Mise à jour immédiate de l'image dans l'UI
                              if (mounted) {
                                setState(() {
                                  _controller.users[index].imageUrl = imageUrl;
                                });
                              }
                            }

                            // 5. Appel API pour la mise à jour en base de données
                            await _controller.updateUser(userCopy);

                            // 6. Fermer le dialogue et afficher un message
                            Navigator.pop(dialogContext);
                            _showSnackBar('Utilisateur modifié avec succès');

                            // 7. Synchronisation en arrière-plan (optionnel)
                            _controller.fetchUsers().then((_) {
                              if (mounted) setState(() => _filterUsers());
                            });
                          } catch (e) {
                            // ANNULATION de la modification OPTIMISTE en cas d'erreur
                            if (mounted) {
                              setState(() {
                                final originalIndex = _controller.users
                                    .indexWhere((u) => u.id == user.id);
                                if (originalIndex != -1) {
                                  _controller.users[originalIndex] =
                                      user; // Rétablir l'original
                                  _filterUsers();
                                }
                              });
                            }
                            _showSnackBar('Erreur: ${e.toString()}',
                                isError: true);
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        }
                      },
                child: _isLoading
                    ? const CircularProgressIndicator(strokeWidth: 2.0)
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
