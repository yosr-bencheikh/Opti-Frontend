import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/core/constants/regions.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/Optician.dart';

class GestionBoutique extends StatefulWidget {
  const GestionBoutique({Key? key}) : super(key: key);

  @override
  State<GestionBoutique> createState() => _GestionBoutiqueState();
}

class _GestionBoutiqueState extends State<GestionBoutique> {
  final BoutiqueController opticienController = Get.find();
  final OpticianController opticianController = Get.find();
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
  int _currentPage = 0;
  final int _itemsPerPage = 5;

// Professional color palette
final Color _lightPrimaryColor = Color(0xFFE8F5E9); // Light green
  final Color _primaryColor = Color(0xFF2E7D32); // Dark green
  final Color _secondaryColor = Color(0xFF6A1B9A); // Purple
  final Color _accentColor = Color(0xFF00C853); // Light green
  final Color _backgroundColor = Color(0xFFF5F5F6); // Light gray
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = Color(0xFF263238); // Dark blue-gray
  final Color _textSecondaryColor = Color(0xFF546E7A); // Medium blue-gray
  final Color _successColor = Color(0xFF388E3C); // Success green
  final Color _errorColor = Color(0xFFD32F2F); // Error red
  final Color _warningColor = Color(0xFFFFA000); // Warning amber
  final Color _infoColor = Color(0xFF1976D2); // Info blue

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterOpticiens);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
    final opticianController = Get.find<OpticianController>();
    if (opticianController.isLoggedIn.value) {
      opticienController.getboutiqueByOpticianId(opticianController.currentUserId.value);
    } 
  }

  Future<void> _loadInitialData() async {
    final opticianController = Get.find<OpticianController>();
    if (opticianController.isLoggedIn.value) {
      await opticienController.getboutiqueByOpticianId(opticianController.currentUserId.value);
    } 
    if (mounted) setState(() {});
  }

  List<Boutique> get _filteredOpticiens {
    final opticianController = Get.find<OpticianController>();
    List<Boutique> filteredList = opticianController.isLoggedIn.value
        ? opticienController.opticiensList
            .where((boutique) => boutique.opticien_id == opticianController.currentUserId.value)
            .toList()
        : opticienController.opticiensList;
    
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

    filteredList = filteredList.where((opticien) {
      final matchesNom = _filters['nom'] == null ||
          _filters['nom']!.isEmpty ||
          opticien.nom.toLowerCase().contains(_filters['nom']!.toLowerCase());
      final matchesAdresse = _filters['adresse'] == null ||
          _filters['adresse']!.isEmpty ||
          opticien.adresse.toLowerCase().contains(_filters['adresse']!.toLowerCase());
      final matchesVille = _filters['ville'] == null ||
          _filters['ville']!.isEmpty ||
          opticien.ville.toLowerCase().contains(_filters['ville']!.toLowerCase());
      final matchesEmail = _filters['email'] == null ||
          _filters['email']!.isEmpty ||
          opticien.email.toLowerCase().contains(_filters['email']!.toLowerCase());
      final matchesPhone = _filters['phone'] == null ||
          _filters['phone']!.isEmpty ||
          opticien.phone.toLowerCase().contains(_filters['phone']!.toLowerCase());
      final matchesDescription = _filters['description'] == null ||
          _filters['description']!.isEmpty ||
          opticien.description.toLowerCase().contains(_filters['description']!.toLowerCase());
      final matchesHoraires = _filters['horaires'] == null ||
          _filters['horaires']!.isEmpty ||
          opticien.opening_hours.toLowerCase().contains(_filters['horaires']!.toLowerCase());

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
        // Utilisation de votre CustomSidebar existant
        CustomSidebar(currentPage: 'Boutiques'),
        
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
                _buildPaginationControls(),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
  // ... (le reste des méthodes reste inchangé)
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
                    decoration: InputDecoration(
                      hintText: 'Rechercher une boutique...',
                      prefixIcon: Icon(Icons.search, color: _textSecondaryColor),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  icon: Icon(_showFilters ? Icons.filter_alt_off : Icons.filter_alt),
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
                      label: Text('${_filteredOpticiens.length} résultats'),
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


Widget _buildDataTable() {
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
          Text('Erreur de chargement', style: TextStyle(fontSize: 18, color: _textPrimaryColor)),
          SizedBox(height: 8),
          Text(opticienController.error.value, style: TextStyle(color: _textSecondaryColor), textAlign: TextAlign.center),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => opticienController.refreshBoutiques(),
            child: Text('Réessayer'),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryColor, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  if (_filteredOpticiens.isEmpty) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory, size: 48, color: _textSecondaryColor),
          SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty ? 'Aucune boutique disponible' : 'Aucun résultat trouvé',
            style: TextStyle(fontSize: 18, color: _textPrimaryColor),
          ),
          if (_searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: _resetFilters,
                child: Text('Réinitialiser la recherche', style: TextStyle(color: _primaryColor)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            child: ListView.separated(
              itemCount: _paginatedOpticiens.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final boutique = _paginatedOpticiens[index];
                return Container(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  color: index.isEven ? Colors.white : Colors.grey[50],
                  child: _buildTableRow(boutique),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
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
    TableColumn(flex: 10, label: 'Actions', icon: Icons.settings, isActions: true),
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
          text: opticianController.getOpticienNom(boutique.opticien_id) ?? 'Non attribué',
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

Widget _buildTableCell({required IconData icon, required String text, bool isImportant = false}) {
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
            onPressed: _currentPage > 0
                ? () => setState(() => _currentPage--)
                : null,
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
                  icon: Icons.store,
                  onChanged: (value) => setState(() {
                    _filters['nom'] = value;
                    _filterOpticiens();
                  }),
                ),
                _buildFilterField(
                  label: 'Adresse',
                  value: _filters['adresse'],
                  icon: Icons.location_on,
                  onChanged: (value) => setState(() {
                    _filters['adresse'] = value;
                    _filterOpticiens();
                  }),
                ),
                _buildFilterField(
                  label: 'Ville',
                  value: _filters['ville'],
                  icon: Icons.location_city,
                  onChanged: (value) => setState(() {
                    _filters['ville'] = value;
                    _filterOpticiens();
                  }),
                ),
                _buildFilterField(
                  label: 'Email',
                  value: _filters['email'],
                  icon: Icons.email,
                  onChanged: (value) => setState(() {
                    _filters['email'] = value;
                    _filterOpticiens();
                  }),
                ),
                _buildFilterField(
                  label: 'Téléphone',
                  value: _filters['phone'],
                  icon: Icons.phone,
                  onChanged: (value) => setState(() {
                    _filters['phone'] = value;
                    _filterOpticiens();
                  }),
                ),
                _buildFilterField(
                  label: 'Horaires',
                  value: _filters['horaires'],
                  icon: Icons.access_time,
                  onChanged: (value) => setState(() {
                    _filters['horaires'] = value;
                    _filterOpticiens();
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

 Widget _buildHeader() {
    final opticianController = Get.find<OpticianController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des Boutiques',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              opticianController.isLoggedIn.value
                  ? '${_filteredOpticiens.length} boutiques'
                  : '${_filteredOpticiens.length} boutiques',
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
            final selectedOptician = opticians.firstWhere(
              (optician) => optician.id == newValue);
            selectedName.value = '${selectedOptician.nom} ${selectedOptician.prenom}';
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
  final descriptionController = TextEditingController(text: opticien.description);
  final openingHoursController = TextEditingController(text: opticien.opening_hours);
  final villeController = TextEditingController(text: opticien.ville);

  // Initialiser les valeurs de l'opticien sélectionné
  final RxString selectedOpticianId = (opticien.opticien_id ?? '').obs;
  final RxString selectedOpticianName = (opticien.opticien_nom ?? 'Non attribué').obs;

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
                        opticien_nom: selectedOpticianName.value != 'Non attribué'
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