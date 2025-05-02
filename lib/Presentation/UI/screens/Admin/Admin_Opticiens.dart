import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/OpticianFilterWidget.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/widgets/paginationcontrols.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:flutter/services.dart';

class OpticianScreen extends StatefulWidget {
  final String? selectedOpticianId;
  const OpticianScreen({Key? key, this.selectedOpticianId}) : super(key: key);

  @override
  _OpticianScreenState createState() => _OpticianScreenState();
}

class _OpticianScreenState extends State<OpticianScreen> {
  final OpticianController _controller = Get.put(OpticianController());
  final TextEditingController _searchController = TextEditingController();
  final AuthController _authController = Get.find<AuthController>();
  String _selectedNom = '';
  String _selectedPrenom = '';
  String _selectedDate = '';
  List<Optician> _filteredOpticians = [];
  String _currentSearchTerm = '';
  bool _showFilters = false;
  int _currentPage = 0;
  int _opticiansPerPage = 10;
  String? _sortColumn;
  bool _sortAscending = true;
  String? _highlightedOpticianId;
  String _selectedRegion = 'Toutes les régions';
  String _selectedGenre = 'Tous les genres';
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
  int _usersPerPage = 5;
  int _startIndex = 0;
  int _endIndex = 0;

  void _updateIndices() {
    _startIndex = (_currentPage - 1) * _usersPerPage;
    _endIndex = _startIndex + _usersPerPage;
    if (_endIndex > _filteredOpticians.length) {
      _endIndex = _filteredOpticians.length;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Fetch data and update state when it completes
    _controller.fetchOpticians().then((_) {
      setState(() {
        // Update _filteredOpticians based on the fetched data
        _filteredOpticians = _controller.opticians;
        debugPrint(
            "After fetch - Pagination: Items: ${_filteredOpticians.length}, Pages: ${(_filteredOpticians.length / _opticiansPerPage).ceil()}");
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _currentSearchTerm = _searchController.text;
      _filterOpticians();
      _currentPage = 1;
      // Reset to first page on new search
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _currentSearchTerm = '';
      _selectedNom = '';
      _selectedPrenom = '';
      _selectedDate = '';
      _selectedRegion = 'Toutes les régions';
      _selectedGenre = 'Tous les genres';
      _filterOpticians();
      _currentPage = 1;
    });
  }

  void _filterOpticians() {
    if (_controller.opticians.isEmpty) {
      _filteredOpticians = [];
      _currentPage = 1;
      _updateIndices();
      return;
    }

    _filteredOpticians = _controller.opticians.where((optician) {
      // Filtrage par recherche textuelle générale
      final matchesSearch = _currentSearchTerm.isEmpty ||
          optician.nom
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          optician.prenom
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          optician.email
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          optician.phone
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          optician.region
              .toLowerCase()
              .contains(_currentSearchTerm.toLowerCase()) ||
          optician.date.contains(_currentSearchTerm);

      // Filtrage par région
      final matchesRegion = _selectedRegion.isEmpty ||
          _selectedRegion == 'Toutes les régions' ||
          optician.region.toLowerCase() == _selectedRegion.toLowerCase();

      // Filtrage par genre
      final matchesGenre = _selectedGenre.isEmpty ||
          _selectedGenre == 'Tous les genres' ||
          optician.genre.toLowerCase() == _selectedGenre.toLowerCase();

      // Filtrage par nom
      final matchesNom = _selectedNom.isEmpty ||
          optician.nom.toLowerCase().contains(_selectedNom.toLowerCase());

      // Filtrage par prénom
      final matchesPrenom = _selectedPrenom.isEmpty ||
          optician.prenom.toLowerCase().contains(_selectedPrenom.toLowerCase());

      // Filtrage par date
      final matchesDate =
          _selectedDate.isEmpty || optician.date.contains(_selectedDate);

      return matchesSearch &&
          matchesRegion &&
          matchesGenre &&
          matchesNom &&
          matchesPrenom &&
          matchesDate;
    }).toList();

    // Appliquer le tri si une colonne est sélectionnée
    if (_sortColumn != null) {
      _filteredOpticians.sort((a, b) {
        var aValue = '';
        var bValue = '';

        switch (_sortColumn) {
          case 'nom':
            aValue = a.nom;
            bValue = b.nom;
            break;
          case 'prenom':
            aValue = a.prenom;
            bValue = b.prenom;
            break;
          case 'email':
            aValue = a.email;
            bValue = b.email;
            break;
          case 'phone':
            aValue = a.phone;
            bValue = b.phone;
            break;
          case 'region':
            aValue = a.region;
            bValue = b.region;
            break;
          case 'date':
            aValue = a.date;
            bValue = b.date;
            break;
          case 'genre':
            aValue = a.genre;
            bValue = b.genre;
            break;
        }

        return _sortAscending
            ? aValue.compareTo(bValue)
            : bValue.compareTo(aValue);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalItems = _filteredOpticians.length;
    final int totalPages = (totalItems / _opticiansPerPage).ceil();

    debugPrint("Build - Pagination: Items: $totalItems, Pages: $totalPages");
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Row(
          children: [
            Expanded(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 16),
                              _buildSearchFilterBar(),
                              const SizedBox(height: 8),

                              // If filters are visible, show the widget
                              if (_showFilters)
                                OpticianFilterWidget(
                                  initialFilters: {
                                    'nom': _selectedNom,
                                    'prenom': _selectedPrenom,
                                    'email': '',
                                    'phone': '',
                                    'date': _selectedDate,
                                    'region': _selectedRegion,
                                    'genre': _selectedGenre,
                                  },
                                  onFilterChanged: (newFilters) {
                                    setState(() {
                                      _selectedNom = newFilters['nom'] ?? '';
                                      _selectedPrenom =
                                          newFilters['prenom'] ?? '';
                                      _selectedDate = newFilters['date'] ?? '';
                                      _selectedRegion = newFilters['region'] ??
                                          'Toutes les régions';
                                      _selectedGenre = newFilters['genre'] ??
                                          'Tous les genres';
                                    });
                                    _filterOpticians();
                                  },
                                ),
                              const SizedBox(height: 16),

                              // Data table with fixed height
                              Container(
                                height: 500,
                                child: _buildDataTable(),
                              ),

                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),

                      // Pagination controls OUTSIDE the scrollable area
                      PaginationControls(
                        currentPage: _currentPage,
                        totalItems: _filteredOpticians.length,
                        itemsPerPage: _opticiansPerPage,
                        onPageChanged: (newPage) {
                          setState(() {
                            _currentPage = newPage;
                            _updateIndices();
                          });
                        },
                      ),
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

  Widget _buildDataTable() {
    return Obx(() {
    // Gestion des états de chargement et d'erreur
    if (_controller.isLoading.value) {
      return _buildLoadingState();
    }
    if (_controller.error.isNotEmpty) {
      return _buildErrorState();
    }

  

      // Pagination: déterminer quels opticiens afficher sur la page actuelle
      final displayedOpticians = _getDisplayedOpticians();

      // On retire le padding supplémentaire pour optimiser l'espace vertical
      return Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête du tableau avec gradient
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3A7BD5).withOpacity(0.15),
                    const Color(0xFF3A7BD5).withOpacity(0.05)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),

            // En-tête des colonnes personnalisé
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildUserTableHeader(),
              ),
            ),

            // Corps du tableau avec rangées personnalisées
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: displayedOpticians.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _buildUserTableRow(displayedOpticians[index]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  List<Optician> _getDisplayedOpticians() {
    final startIndex = _currentPage * _opticiansPerPage;
    final endIndex =
        min(startIndex + _opticiansPerPage, _filteredOpticians.length);

    if (startIndex >= _filteredOpticians.length) {
      return [];
    }

    return _filteredOpticians.sublist(startIndex, endIndex);
  }

// Liste des colonnes du tableau

// État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3A7BD5)),
          ),
          SizedBox(height: 16),
          Text('Chargement en cours...',
              style: TextStyle(fontSize: 16, color: Colors.grey))
        ],
      ),
    );
  }

// État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(32),
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
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            const Text(
              'Une erreur est survenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.error.value,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _controller.fetchOpticians(),
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A7BD5),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

// État vide (aucun résultat)
  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(32),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'Aucun opticien disponible'
                  : 'Aucun opticien ne correspond à votre recherche',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Essayez de modifier vos critères de recherche',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 20),
            if (_searchController.text.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Effacer la recherche'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3A7BD5),
                ),
              ),
          ],
        ),
      ),
    );
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

  Widget _buildUserTableRow(Optician user) {
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
                backgroundImage:
                    (user.imageUrl != null && user.imageUrl!.isNotEmpty)
                        ? NetworkImage(user.imageUrl!)
                        : null,
                child: user.imageUrl == null || user.imageUrl!.isEmpty
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
                onPressed: () => _showEditOpticianDialog(user),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text(
                            'Voulez-vous vraiment supprimer cet opticien ?'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.delete, size: 18),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (user.id != null) {
                                _controller.deleteOptician(user.id!);
                              } else {
                                Get.snackbar(
                                  'Erreur',
                                  'Impossible de supprimer un opticien sans ID',
                                  snackPosition: SnackPosition.BOTTOM,
                                  backgroundColor: Colors.red.shade100,
                                  colorText: Colors.red.shade900,
                                  margin: const EdgeInsets.all(16),
                                  borderRadius: 8,
                                );
                              }
                              Navigator.pop(context);
                            },
                            label: const Text('Supprimer'),
                          ),
                        ],
                      );
                    },
                  );
                },
                tooltip: 'Supprimer',
              ),
              const SizedBox(width: 4),
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

  Widget _buildSearchFilterBar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _currentSearchTerm = value;
                        });
                        _filterOpticians();
                      },
                      decoration: InputDecoration(
                        hintText: 'Rechercher un opticien...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Icon(
                            Icons.search_rounded,
                            color: _textSecondaryColor.withOpacity(0.8),
                            size: 20,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: _primaryColor.withOpacity(0.8),
                            width: 1.5,
                          ),
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showFilters = !_showFilters;
                      });
                    },
                    icon: Icon(
                      _showFilters
                          ? Icons.filter_alt_off_rounded
                          : Icons.filter_alt_rounded,
                      size: 20,
                      color: _showFilters ? Colors.white : _primaryColor,
                    ),
                    label: Text(
                      _showFilters ? 'Cacher' : 'Filtres',
                      style: TextStyle(
                        fontSize: 14,
                        color: _showFilters ? Colors.white : _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _showFilters ? _primaryColor : Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: _showFilters
                              ? _primaryColor
                              : Colors.grey.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            if (_searchController.text.isNotEmpty || _showFilters)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 16,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_filteredOpticians.length} résultats',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _resetFilters,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.restart_alt_rounded,
                            size: 16,
                            color: _errorColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Réinitialiser',
                            style: TextStyle(
                              fontSize: 13,
                              color: _errorColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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

  Widget _buildHeader() {
    // Nouvelle palette premium
    final Color _primaryColor = Color(0xFF006D77); // Bleu-vert profond
    final Color _accentColor =
        const Color.fromARGB(255, 33, 199, 146); // Saumon chaud
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
                    'Opticiens',
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
                        text: '${_controller.getTotalOpticians()} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Opticiens enregistrés',
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
              onPressed: () => _showOpticianDialog(),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                'Nouvel opticien',
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

  void _sortByField(String column) {
    setState(() {
      // If clicking the same column, toggle direction
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
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

void _showOpticianDialog({Optician? optician}) {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController(text: optician?.nom);
  final TextEditingController _prenomController = TextEditingController(text: optician?.prenom);
  final TextEditingController _dateController = TextEditingController(text: optician?.date);
  final TextEditingController _genreController = TextEditingController(text: optician?.genre);
  final TextEditingController _passwordController = TextEditingController(text: optician?.password);
  final TextEditingController _addressController = TextEditingController(text: optician?.address);
  final TextEditingController _emailController = TextEditingController(text: optician?.email);
  final TextEditingController _phoneController = TextEditingController(text: optician?.phone);
  final TextEditingController _regionController = TextEditingController(text: optician?.region);
  final TextEditingController _imageUrlController = TextEditingController(text: optician?.imageUrl);
  PlatformFile? _tempSelectedImage;
  final List<String> genres = ['Homme', 'Femme'];
  String selectedGenre = optician?.genre ?? genres.first;
  DateTime _selectedDate = DateTime.tryParse(optician?.date ?? '') ?? DateTime.now();
  String _selectedRegion = optician?.region ?? Regions.list.first;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              optician == null ? 'Ajouter un opticien' : 'Modifier un opticien',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile image upload section
                    Center(
                      child: Column(
                        children: [
                          FilePickerExample(
                            onImagePicked: (PlatformFile? file) {
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nom',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer un nom';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _prenomController,
                            decoration: InputDecoration(
                              labelText: 'Prénom',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Date de naissance',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            ),
                            readOnly: true,
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
                                  _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner une date';
                              }

                              // Vérifier que l'utilisateur a au moins 13 ans
                              final selectedDate = DateTime.tryParse(value);
                              if (selectedDate != null) {
                                final today = DateTime.now();
                                final age = today.year - selectedDate.year -
                                    (today.month < selectedDate.month ||
                                            (today.month == selectedDate.month && today.day < selectedDate.day)
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
                        SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGenre,
                            decoration: InputDecoration(
                              labelText: 'Genre',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.people),
                            ),
                            items: genres.map((String genre) {
                              return DropdownMenuItem<String>(
                                value: genre,
                                child: Text(genre),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedGenre = newValue!;
                                _genreController.text = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un genre';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Mot de passe',
                        border: OutlineInputBorder(),
                        hintText: 'Minimum 8 caractères avec majuscule, chiffre et caractère spécial',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                        if (!RegExp(r'[!@/+_#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                          return 'Le mot de passe doit contenir au moins un caractère spécial';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Adresse',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.home),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        hintText: 'exemple@gmail.com',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        border: OutlineInputBorder(),
                        hintText: '8 chiffres',
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un numéro de téléphone';
                        }
                        if (value.length != 8 || !RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                          return 'Le téléphone doit contenir exactement 8 chiffres';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Région',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                                  _regionController.text = value;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
              onPressed: () async {
  if (_formKey.currentState!.validate()) {
    try {
      final newOptician = Optician(
        id: optician?.id,
        nom: _nameController.text,
        prenom: _prenomController.text,
        date: _dateController.text,
        genre: selectedGenre,
        password: _passwordController.text,
        address: _addressController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        region: _selectedRegion,
        imageUrl: _imageUrlController.text,
      );
      Navigator.pop(context);

      if (optician == null) {
        await _controller.addOptician(newOptician);
      } else {
        await _controller.updateOptician(newOptician);
      }

      if (_tempSelectedImage != null) {
        final imageUrl = await _uploadImageAndGetUrl(
          _tempSelectedImage,
          _emailController.text,
        );
        newOptician.imageUrl = imageUrl;
        await _controller.updateOptician(newOptician);
      }

  try {
  final completeUser = await _authController.getUserByEmail(newOptician.email);
  if (completeUser == null) {
    throw Exception('User not found after creation');
  }
  newOptician.id = completeUser['_id'] ?? completeUser['id'] ?? '';
} catch (e) {
  print('Error getting user by email:');
  // Gérer l'erreur ou créer l'utilisateur d'une autre manière
}

      Get.snackbar(
        'Succès', 
        optician == null ? 'Opticien ajouté avec succès' : 'Opticien modifié avec succès'
      );

      // Fermer la boîte de dialogue
      Navigator.pop(context);
    } catch (e) {
    }
  }
},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: Text(optician == null ? 'Ajouter' : 'Enregistrer'),
              ),
            ],
          );
        }
      );
    },
  );
}
  Future<void> _showEditOpticianDialog(Optician optician) async {
    final _formKey = GlobalKey<FormState>();
    bool _isLoading = false;
    PlatformFile? _tempSelectedImage;

    // Créer des contrôleurs avec les données existantes de l'opticien
    final TextEditingController _nameController =
        TextEditingController(text: optician.nom);
    final TextEditingController _prenomController =
        TextEditingController(text: optician.prenom);
    final TextEditingController _dateController =
        TextEditingController(text: optician.date);
    final TextEditingController _passwordController =
        TextEditingController(text: optician.password);
    final TextEditingController _addressController =
        TextEditingController(text: optician.address);
    final TextEditingController _emailController =
        TextEditingController(text: optician.email);
    final TextEditingController _phoneController =
        TextEditingController(text: optician.phone);
    final TextEditingController _statusController =
        TextEditingController(text: optician.status);

    // Valeurs pour les menus déroulants
    String _selectedRegion = Regions.list.contains(optician.region)
        ? optician.region
        : Regions.list[0];
    String _selectedGenre =
        ['Homme', 'Femme'].contains(optician.genre) ? optician.genre : 'Homme';
    DateTime _selectedDate = DateTime.tryParse(optician.date) ?? DateTime.now();

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              'Modifier un opticien',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
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
                              initialImageUrl: optician.imageUrl,
                            ),
                            const SizedBox(height: 8),
                            const Text('Photo de profil'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informations personnelles - Nom et Prénom
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer un nom';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _prenomController,
                              decoration: InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline),
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
                      SizedBox(height: 16),

                      // Date de naissance et Genre
                      Row(
                        children: [
                          Expanded(
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
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null && picked != _selectedDate) {
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
                          SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedGenre,
                              decoration: InputDecoration(
                                labelText: 'Genre',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.people),
                              ),
                              items: ['Homme', 'Femme'].map((String genre) {
                                return DropdownMenuItem<String>(
                                  value: genre,
                                  child: Text(genre),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _selectedGenre = newValue;
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez sélectionner un genre';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Mot de passe
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
                      SizedBox(height: 16),

                      // Adresse
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Adresse',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.home),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer une adresse';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Email
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
                      SizedBox(height: 16),

                      // Téléphone
                      TextFormField(
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
                              !RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                            return 'Le téléphone doit contenir exactement 8 chiffres';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),

                      // Région
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez sélectionner une région';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Statut (si nécessaire)
                      // Vous pouvez ajouter le champ de statut ici si nécessaire
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: TextStyle(color: Colors.grey)),
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
                            // Créer un opticien mis à jour
                            Optician updatedOptician = Optician(
                              id: optician.id,
                              nom: _nameController.text,
                              prenom: _prenomController.text,
                              date: _dateController.text,
                              genre: _selectedGenre,
                              password: _passwordController.text,
                              address: _addressController.text,
                              email: _emailController.text,
                              phone: _phoneController.text,
                              region: _selectedRegion,
                              imageUrl: optician.imageUrl, // Valeur par défaut
                              status: _statusController.text,
                            );

                            // Si une nouvelle image est sélectionnée, téléchargez-la
                            if (_tempSelectedImage != null) {
                              final imageUrl = await _uploadImageAndGetUrl(
                                _tempSelectedImage,
                                _emailController.text,
                              );
                              // Mettez à jour l'URL de l'image de l'opticien
                              updatedOptician.imageUrl = imageUrl;
                            }

                            // Mettez à jour l'opticien dans la base de données
                            await _controller.updateOptician(updatedOptician);

                            // Affichez un message de succès
                            Get.snackbar(
                              'Succès',
                              'Opticien modifié avec succès',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.green,
                              colorText: Colors.white,
                            );

                            // Fermez la boîte de dialogue
                            Navigator.pop(dialogContext);

                            // Forcez le rafraîchissement de l'interface utilisateur
                            if (mounted) {
                              setState(() {
                                // Rafraichir la liste des opticiens
                                _controller.fetchOpticians();
                              });
                            }
                          } catch (e) {
                            // Affichez un message d'erreur
                            Get.snackbar(
                              'Erreur',
                              'Une erreur s\'est produite: ${e.toString()}',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.0, color: Colors.white),
                      )
                    : const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );

    if (mounted) {
      setState(() {});
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
