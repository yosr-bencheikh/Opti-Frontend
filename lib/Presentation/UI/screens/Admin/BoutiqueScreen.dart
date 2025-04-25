import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/BoutiqueFilterWidget.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/widgets/paginationcontrols.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/Optician.dart';

class BoutiqueScreen extends StatefulWidget {
  const BoutiqueScreen({Key? key}) : super(key: key);

  @override
  State<BoutiqueScreen> createState() => _BoutiqueScreenState();
}

class _BoutiqueScreenState extends State<BoutiqueScreen> {
  final BoutiqueController opticienController = Get.find();

  final OpticianController opticianController =
      Get.find(); // Ajoutez ce contrôleur
  final RxString selectedOpticianId = ''.obs;
  final RxString selectedOpticianName = 'Non attribué'.obs;

  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  TextEditingController _searchController = TextEditingController();
  final Map<String, String?> _filters = {
    'nom': null,
    'adresse': null,
    'ville': null,
    'email': null,
    'phone': null,
    'description': null,
    'horaires': null,
  };
  bool _showFilters = false;
  String _currentSearchTerm = '';
  List<Boutique> _filteredBoutique = [];

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 10;
  final Color _primaryColor = const Color.fromARGB(255, 33, 199, 146);
  final Color _secondaryColor = const Color.fromARGB(255, 16, 16, 17);
  final Color _accentColor = const Color(0xFFFF4081);
  final Color _lightPrimaryColor = const Color(0xFFC5CAE9);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);
  final Color _infoColor = Color(0xFF1976D2); // Info blue
  final Color _errorColor = Color(0xFFD32F2F); // Error red

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOpticiens);
  }

  List<Boutique> get _filteredOpticiens {
    List<Boutique> filteredList = opticienController.opticiensList;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredList = filteredList.where((opticien) {
        return opticien.nom.toLowerCase().contains(query) ||
            opticien.adresse.toLowerCase().contains(query) ||
            opticien.ville.toLowerCase().contains(query) ||
            opticien.email.toLowerCase().contains(query) ||
            opticien.phone.toLowerCase().contains(query) ||
            opticien.description.toLowerCase().contains(query) ||
            opticien.opening_hours.toLowerCase().contains(query);
      }).toList();
    }

    // Apply advanced filters
    filteredList = filteredList.where((opticien) {
      final matchesNom = _filters['nom'] == null ||
          _filters['nom']!.isEmpty ||
          opticien.nom.toLowerCase().contains(_filters['nom']!.toLowerCase());

      final matchesAdresse = _filters['adresse'] == null ||
          _filters['adresse']!.isEmpty ||
          opticien.adresse
              .toLowerCase()
              .contains(_filters['adresse']!.toLowerCase());

      final matchesVille = _filters['ville'] == null ||
          _filters['ville']!.isEmpty ||
          opticien.ville
              .toLowerCase()
              .contains(_filters['ville']!.toLowerCase());

      final matchesEmail = _filters['email'] == null ||
          _filters['email']!.isEmpty ||
          opticien.email
              .toLowerCase()
              .contains(_filters['email']!.toLowerCase());

      final matchesPhone = _filters['phone'] == null ||
          _filters['phone']!.isEmpty ||
          opticien.phone
              .toLowerCase()
              .contains(_filters['phone']!.toLowerCase());

      final matchesDescription = _filters['description'] == null ||
          _filters['description']!.isEmpty ||
          opticien.description
              .toLowerCase()
              .contains(_filters['description']!.toLowerCase());

      final matchesHoraires = _filters['horaires'] == null ||
          _filters['horaires']!.isEmpty ||
          opticien.opening_hours
              .toLowerCase()
              .contains(_filters['horaires']!.toLowerCase());

      return matchesNom &&
          matchesAdresse &&
          matchesVille &&
          matchesEmail &&
          matchesPhone &&
          matchesDescription &&
          matchesHoraires;
    }).toList();

    return filteredList;
  }

  // Get paginated data
  List<Boutique> get _paginatedOpticiens {
    final filteredList = _filteredOpticiens;
    final startIndex = _currentPage * _itemsPerPage;

    if (startIndex >= filteredList.length) {
      return [];
    }

    final endIndex = (startIndex + _itemsPerPage < filteredList.length)
        ? startIndex + _itemsPerPage
        : filteredList.length;

    return filteredList.sublist(startIndex, endIndex);
  }

  int get _pageCount {
    return (_filteredOpticiens.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Contenu principal amélioré
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              color: _backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header amélioré
                  _buildHeader(),
                  SizedBox(height: 16),

                  // Barre de recherche et filtres
                  _buildSearchFilterBar(),

                  SizedBox(height: 16),

                  // Filtres avancés (conditionnel)
                  if (_showFilters) _buildAdvancedFilters(),

                  SizedBox(height: 24),

                  // Tableau de données
                  Expanded(
                    child: _buildDataTable(),
                  ),

                  // Pagination
                  PaginationControls(
                    currentPage: _currentPage,
                    totalItems: _filteredOpticiens.length,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (newPage) {
                      setState(() {
                        _currentPage = newPage;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return BoutiqueFilterWidget(
      initialFilters: {
        'nom': _filters['nom'] ?? '',
        'adresse': _filters['adresse'] ?? '',
        'ville': _filters['ville'] ?? '',
        'email': _filters['email'] ?? '',
        'phone': _filters['phone'] ?? '',
        'description': _filters['description'] ?? '',
        'horaires': _filters['horaires'] ?? '',
      },
      onFilterChanged: (newFilters) {
        setState(() {
          _filters['nom'] =
              newFilters['nom']!.isNotEmpty ? newFilters['nom'] : null;
          _filters['adresse'] =
              newFilters['adresse']!.isNotEmpty ? newFilters['adresse'] : null;
          _filters['ville'] =
              newFilters['ville']!.isNotEmpty ? newFilters['ville'] : null;
          _filters['email'] =
              newFilters['email']!.isNotEmpty ? newFilters['email'] : null;
          _filters['phone'] =
              newFilters['phone']!.isNotEmpty ? newFilters['phone'] : null;
          _filters['description'] = newFilters['description']!.isNotEmpty
              ? newFilters['description']
              : null;
          _filters['horaires'] = newFilters['horaires']!.isNotEmpty
              ? newFilters['horaires']
              : null;
        });
        _filterOpticiens();
      },
    );
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

  void _filterOpticiens() {
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      for (var key in _filters.keys) {
        _filters[key] = null;
      }
      _searchController.clear();
      _currentSearchTerm = '';
      _filterOpticiens();
      _currentPage = 1;
    });
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
                    'Boutiques',
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
                        text: '${_filteredOpticiens.length} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Boutiques enregistrés',
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
              onPressed: () => _showAddBoutiqueDialog(context),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                'Nouveau boutique',
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

  Widget _buildSearchFilterBar() {
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.grey[50]!,
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
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
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterOpticiens(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une boutique...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: Icon(
                            Icons.search_rounded,
                            color: _textSecondaryColor.withOpacity(0.8),
                            size: 22,
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
                SizedBox(width: 12),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
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
                padding: EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.store_rounded,
                            size: 16,
                            color: _primaryColor,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${_filteredOpticiens.length} résultats',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    TextButton.icon(
                      onPressed: _resetFilters,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: _errorColor,
                      ),
                      label: Text(
                        'Réinitialiser',
                        style: TextStyle(
                          fontSize: 13,
                          color: _errorColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 8),
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
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          child: TextField(
            controller: TextEditingController(text: value),
            onChanged: onChanged,
            style: TextStyle(color: Colors.black),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(icon,
                  color: Color.fromARGB(255, 84, 151, 198), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable() {
    return Obx(() {
      if (opticienController.isLoading.value) {
        return Center(
          child: CircularProgressIndicator(color: _primaryColor),
        );
      }

      if (opticienController.error.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: _errorColor),
              SizedBox(height: 16),
              Text('Erreur de chargement',
                  style: TextStyle(fontSize: 18, color: _textPrimaryColor)),
              SizedBox(height: 8),
              Text(opticienController.error.value,
                  style: TextStyle(color: _textSecondaryColor),
                  textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => opticienController.refreshBoutiques(),
                child: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        );
      }

      final boutiques = _filteredOpticiens;
      if (boutiques.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.store_mall_directory,
                  size: 48, color: _textSecondaryColor),
              SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'Aucune boutique disponible'
                    : 'Aucun résultat trouvé',
                style: TextStyle(fontSize: 18, color: _textPrimaryColor),
              ),
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    onPressed: _resetFilters,
                    child: Text('Réinitialiser la recherche',
                        style: TextStyle(color: _primaryColor)),
                  ),
                ),
            ],
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              // En-tête du tableau
              Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: _buildTableHeader(),
              ),

              // Contenu du tableau
              Expanded(
                child: AnimatedSwitcher(
                  duration: Duration(milliseconds: 300),
                  child: boutiques.isEmpty
                      ? Center(child: Text("Aucune donnée disponible"))
                      : ListView.separated(
                          key: ValueKey(
                              boutiques.length), // Important pour l'animation
                          itemCount: _paginatedOpticiens.length,
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, color: Colors.grey[200]),
                          itemBuilder: (context, index) {
                            final boutique = _paginatedOpticiens[index];
                            return Container(
                              key: ValueKey(
                                  boutique.id), // Important pour les animations
                              padding: EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 8),
                              color:
                                  index.isEven ? Colors.white : Colors.grey[50],
                              child: _buildTableRow(boutique),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildTableHeader() {
    final columns = [
      TableColumn(flex: 15, label: 'Nom', icon: Icons.business),
      TableColumn(flex: 15, label: 'Opticien', icon: Icons.person),
      TableColumn(flex: 20, label: 'Adresse', icon: Icons.location_on),
      TableColumn(flex: 15, label: 'Email', icon: Icons.email),
      TableColumn(flex: 10, label: 'Ville', icon: Icons.location_city),
      TableColumn(flex: 10, label: 'Téléphone', icon: Icons.phone),
      TableColumn(flex: 25, label: 'Description', icon: Icons.description),
      TableColumn(flex: 20, label: 'Horaires', icon: Icons.schedule),
      TableColumn(
          flex: 10, label: 'Actions', icon: Icons.settings, isActions: true),
    ];

    return Row(
      children: columns.map((col) {
        return Expanded(
          flex: col.flex,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: col.label,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(col.icon, size: 16, color: _primaryColor),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      col.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _textPrimaryColor,
                        fontSize: 12,
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

  Widget _buildTableRow(Boutique boutique) {
    return Row(
      children: [
        // Nom
        Expanded(
          flex: 15,
          child: _buildTableCell(
            icon: Icons.store,
            text: boutique.nom,
            isImportant: true,
          ),
        ),

        // Opticien
        Expanded(
          flex: 15,
          child: _buildTableCell(
            icon: Icons.person_outline,
            text: opticianController.getOpticienNom(boutique.opticien_id) ??
                'Non attribué',
            isImportant: boutique.opticien_id != null,
          ),
        ),

        // Adresse
        Expanded(
          flex: 20,
          child: _buildTableCell(
            icon: Icons.place,
            text: boutique.adresse,
          ),
        ),

        // Email
        Expanded(
          flex: 15,
          child: _buildTableCell(
            icon: Icons.mail_outline,
            text: boutique.email ?? '-',
          ),
        ),

        // Ville
        Expanded(
          flex: 10,
          child: _buildTableCell(
            icon: Icons.location_city,
            text: boutique.ville,
          ),
        ),

        // Téléphone
        Expanded(
          flex: 10,
          child: _buildTableCell(
            icon: Icons.phone_outlined,
            text: boutique.phone,
          ),
        ),

        // Description
        Expanded(
          flex: 25,
          child: _buildTableCell(
            icon: Icons.subject,
            text: boutique.description ?? '-',
          ),
        ),

        // Horaires
        Expanded(
          flex: 20,
          child: _buildTableCell(
            icon: Icons.access_time,
            text: boutique.opening_hours ?? '-',
          ),
        ),

        // Actions
        Expanded(
          flex: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: _infoColor),
                onPressed: () => _showEditBoutiqueDialog(context, boutique),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Modifier',
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: _errorColor),
                onPressed: () => _showDeleteConfirmation(context, boutique),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableCell(
      {required IconData icon,
      required String text,
      bool isImportant = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: text,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _textSecondaryColor),
            SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isImportant ? FontWeight.w500 : FontWeight.normal,
                  color: isImportant ? _textPrimaryColor : _textSecondaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalPages = _pageCount;

    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage de ${_paginatedOpticiens.length} sur ${_filteredOpticiens.length} boutiques',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              OutlinedButton(
                onPressed: _currentPage > 0
                    ? () => setState(() {
                          _currentPage--;
                        })
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Précédent'),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('${_currentPage + 1} / $totalPages'),
              ),
              OutlinedButton(
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() {
                          _currentPage++;
                        })
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Boutique opticien) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _showEditBoutiqueDialog(context, opticien),
          tooltip: 'Modifier',
          color: const Color(0xFF3A7BD5),
          splashRadius: 24,
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteConfirmation(context, opticien),
          tooltip: 'Supprimer',
          color: Colors.red[400],
          splashRadius: 24,
        ),
      ],
    );
  }

  void _showAddBoutiqueDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController();
    final adresseController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final descriptionController = TextEditingController();
    final openingHoursController = TextEditingController();
    final villeController = TextEditingController();

    opticianController.fetchOpticians();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ajouter une boutique',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          controller: nomController,
                          label: 'Nom',
                          hint: 'Entrez le nom de la boutique',
                          prefixIcon: Icons.store,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer un nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: adresseController,
                          label: 'Adresse',
                          hint: 'Entrez l\'adresse complète',
                          prefixIcon: Icons.location_on,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une adresse';
                            }
                            return null;
                          },
                        ),
                        _buildFormField(
                          controller: villeController,
                          label: 'Ville',
                          hint: 'Sélectionnez la ville',
                          prefixIcon: Icons.location_city,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isDropdown: true, // Indicate that this is a dropdown
                        ),
                        const SizedBox(height: 16),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: phoneController,
                          label: 'Téléphone',
                          hint: '8 chiffres',
                          prefixIcon: Icons.phone,
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
                        _buildFormField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Ex: contact@boutique.com',
                          prefixIcon: Icons.email,
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
                        _buildFormField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Décrivez la boutique en quelques mots',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une descriptionn';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: openingHoursController,
                          label: 'Horaires d\'ouverture',
                          hint: 'Ex: Lun-Ven: 9h-18h, Sam: 9h-12h',
                          prefixIcon: Icons.access_time,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isSchedulePicker:
                              true, // Activer le sélecteur d'horaires
                        ),
                        const SizedBox(height: 16),
                        Obx(() => _buildOpticianDropdown(
                              opticianController.opticians,
                              selectedOpticianId,
                              selectedOpticianName,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        // Create a new Opticien with the form data
                        final opticien = Boutique(
                          id: '', // This will be ignored by the server
                          nom: nomController.text,
                          adresse: adresseController.text,
                          ville: villeController.text,
                          phone: phoneController.text,
                          email: emailController.text,
                          description: descriptionController.text,
                          opening_hours: openingHoursController.text,
                          opticien_id: selectedOpticianId.value.isNotEmpty
                              ? selectedOpticianId.value
                              : null, // Explicitly set to null if no selection
                          opticien_nom: null,
                        );

                        // Close the dialog first to avoid context issues
                        Navigator.pop(dialogContext);

                        // Add the optician
                        final success =
                            await opticienController.addOpticien(opticien);

                        // Show a snackbar with the result
                        if (!context.mounted) return;
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Boutique ajoutée avec succès'
                                  : 'Erreur: ${opticienController.error.value}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {
                                scaffold.hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Enregistrer',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Ajoutez cette méthode pour construire le dropdown des opticiens
  Widget _buildOpticianDropdown(
    List<Optician> opticians,
    RxString selectedId,
    RxString selectedName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optician',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedId.value.isEmpty ? null : selectedId.value,
          decoration: InputDecoration(
            hintText: 'Select an optician',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(Icons.person, color: Colors.grey[500], size: 20),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          items: opticians.map((Optician optician) {
            return DropdownMenuItem<String>(
              value: optician.id,
              child: Text('${optician.nom} ${optician.prenom}'),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              selectedId.value = newValue;
              final selectedOptician =
                  opticians.firstWhere((optician) => optician.id == newValue);
              selectedName.value =
                  '${selectedOptician.nom} ${selectedOptician.prenom}';
            }
          },
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData prefixIcon,
    required String? Function(String?) validator,
    int maxLines = 1,
    bool isDropdown = false,
    bool isSchedulePicker =
        false, // Nouveau paramètre pour identifier le champ des horaires
  }) {
    if (isDropdown) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: controller.text.isNotEmpty ? controller.text : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            items: Regions.list.map((String region) {
              return DropdownMenuItem<String>(
                value: region,
                child: Text(region),
              );
            }).toList(),
            onChanged: (String? newValue) {
              controller.text = newValue ?? ''; // Mettre à jour le contrôleur
            },
          ),
        ],
      );
    } else if (isSchedulePicker) {
      // Cas spécifique pour le sélecteur d'horaires
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            readOnly: true, // Empêche la saisie manuelle
            onTap: () async {
              // Ouvrir le sélecteur d'horaires
              final selectedSchedule = await _showSchedulePicker();
              if (selectedSchedule != null) {
                controller.text =
                    selectedSchedule; // Mettre à jour le contrôleur
              }
            },
            validator: validator,
          ),
        ],
      );
    } else {
      // Cas par défaut pour un TextFormField normal
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(prefixIcon, color: Colors.grey[500], size: 20),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide:
                    const BorderSide(color: Color(0xFF3A7BD5), width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: validator,
            maxLines: maxLines,
          ),
        ],
      );
    }
  }

  Future<String?> _showSchedulePicker() async {
    String selectedSchedule = '';
    TimeOfDay? openingTime;
    TimeOfDay? closingTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sélectionner les horaires'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sélection des jours
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Jours',
                  border: OutlineInputBorder(),
                ),
                items: ['Lun-Ven', 'Lun-Sam', 'Lun-Dim'].map((day) {
                  return DropdownMenuItem(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedSchedule = '$value: ';
                },
              ),
              SizedBox(height: 16),
              // Sélection des heures d'ouverture
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.blue),
                title: Text(
                  openingTime == null
                      ? 'Heure d\'ouverture'
                      : 'Ouverture: ${openingTime?.format(context)}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    openingTime = time;
                    selectedSchedule += '${time.format(context)}-';
                  }
                },
              ),
              SizedBox(height: 8),
              // Sélection des heures de fermeture
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.red),
                title: Text(
                  closingTime == null
                      ? 'Heure de fermeture'
                      : 'Fermeture: ${closingTime?.format(context)}',
                ),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    closingTime = time;
                    selectedSchedule += time.format(context);
                  }
                },
              ),
              // Validation des heures
              if (openingTime != null && closingTime != null)
                Text(
                  closingTime!.hour < openingTime!.hour
                      ? 'L\'heure de fermeture doit être après l\'heure d\'ouverture'
                      : '',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                if (openingTime == null || closingTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Veuillez sélectionner les heures')),
                  );
                } else if (closingTime!.hour < openingTime!.hour) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'L\'heure de fermeture doit être après l\'heure d\'ouverture'),
                    ),
                  );
                } else {
                  Navigator.pop(context, selectedSchedule);
                }
              },
              child: Text('Valider', style: TextStyle(color: Colors.blue)),
            ),
          ],
        );
      },
    );

    return selectedSchedule;
  }

  void _showEditBoutiqueDialog(BuildContext context, Boutique opticien) {
    final formKey = GlobalKey<FormState>();
    final nomController = TextEditingController(text: opticien.nom);
    final adresseController = TextEditingController(text: opticien.adresse);
    final phoneController = TextEditingController(text: opticien.phone);
    final emailController = TextEditingController(text: opticien.email);
    final descriptionController =
        TextEditingController(text: opticien.description);
    final openingHoursController =
        TextEditingController(text: opticien.opening_hours);
    final villeController = TextEditingController(text: opticien.ville);

    // Initialiser les valeurs de l'opticien sélectionné
    final RxString selectedOpticianId = (opticien.opticien_id ?? '').obs;
    final RxString selectedOpticianName =
        (opticien.opticien_nom ?? 'Non attribué').obs;

    // Charger la liste des opticiens
    opticianController.fetchOpticians();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Modifier la boutique',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(dialogContext),
                    splashRadius: 20,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormField(
                          controller: nomController,
                          label: 'Nom',
                          hint: 'Entrez le nom de la boutique',
                          prefixIcon: Icons.store,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: adresseController,
                          label: 'Adresse',
                          hint: 'Entrez l\'adresse complète',
                          prefixIcon: Icons.location_on,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                        ),
                        _buildFormField(
                          controller: villeController,
                          label: 'Ville',
                          hint: 'Sélectionnez la ville',
                          prefixIcon: Icons.location_city,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isDropdown: true,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: phoneController,
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
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: emailController,
                          label: 'Email',
                          hint: 'Ex: contact@boutique.com',
                          prefixIcon: Icons.email,
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
                        _buildFormField(
                          controller: descriptionController,
                          label: 'Description',
                          hint: 'Décrivez la boutique en quelques mots',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer une description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildFormField(
                          controller: openingHoursController,
                          label: 'Horaires d\'ouverture',
                          hint: 'Ex: Lun-Ven: 9h-18h, Sam: 9h-12h',
                          prefixIcon: Icons.access_time,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Champ requis' : null,
                          isSchedulePicker: true,
                        ),
                        const SizedBox(height: 16),
                        Obx(() => _buildOpticianDropdown(
                              opticianController.opticians,
                              selectedOpticianId,
                              selectedOpticianName,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (formKey.currentState?.validate() ?? false) {
                        // Create updated Boutique with form data
                        final updatedBoutique = Boutique(
                          id: opticien.id,
                          nom: nomController.text,
                          adresse: adresseController.text,
                          ville: villeController.text,
                          phone: phoneController.text,
                          email: emailController.text,
                          description: descriptionController.text,
                          opening_hours: openingHoursController.text,
                          opticien_id: selectedOpticianId.value.isNotEmpty
                              ? selectedOpticianId.value
                              : null,
                          opticien_nom:
                              selectedOpticianName.value != 'Non attribué'
                                  ? selectedOpticianName.value
                                  : null,
                        );

                        // Close the dialog first to avoid context issues
                        Navigator.pop(dialogContext);

                        // Update the boutique
                        final success = await opticienController.updateOpticien(
                            opticien.id, updatedBoutique);

                        // Show a snackbar with the result
                        if (!context.mounted) return;
                        final scaffold = ScaffoldMessenger.of(context);
                        scaffold.showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? 'Boutique mise à jour avec succès'
                                  : 'Erreur: ${opticienController.error.value}',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor:
                                success ? Colors.green : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.all(16),
                            action: SnackBarAction(
                              label: 'OK',
                              textColor: Colors.white,
                              onPressed: () {
                                scaffold.hideCurrentSnackBar();
                              },
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3A7BD5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mettre à jour',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Boutique opticien) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${opticien.nom} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Close the dialog first to avoid context issues
              Navigator.pop(dialogContext);

              // Delete the optician
              final success =
                  await opticienController.deleteOpticien(opticien.id);

              // Show a snackbar with the result
              final scaffold = ScaffoldMessenger.of(context);
              scaffold.showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'Boutique supprimée avec succès'
                      : 'Erreur: ${opticienController.error.value}'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
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
