import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Model3DPickerWidget.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Product3DViewer.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/UI/screens/User/Rotating3DModel.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/core/constants/champsProduits.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:http/http.dart' as http;

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductController productController = Get.find();
  File? _imageFile;
  PlatformFile? _tempSelectedImage;
  String _currentSearchTerm = '';

  TextEditingController _searchController = TextEditingController();

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 10;

  // Filter variables
  String? _selectedCategory;
  String? _selectedOpticien;
  double? _minPrice;
  double? _maxPrice;
  bool _showFilters = false;

  // Color scheme for the app
  final Color primaryColor = const Color(0xFF1A73E9);
  final Color secondaryColor = const Color(0xFF4285F4);
  final Color accentColor = const Color(0xFFEA4335);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF202124);
  final Color textSecondaryColor = const Color(0xFF5F6368);

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

  final Map<String, String?> _filters = {
    'name': null,
    'category': null,
    'marque': null,
    'couleur': null,
    'typeVerre': null,
    'boutique': null,
    'prixMin': null,
    'prixMax': null,
  };
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    try {
      final opticianController = Get.find<OpticianController>();
      final boutiqueController = Get.find<BoutiqueController>();

      if (opticianController.isLoggedIn.value) {
        // Chargez d'abord les boutiques
        await boutiqueController
            .getboutiqueByOpticianId(opticianController.currentUserId.value);

        // Puis chargez les produits
        await productController.loadProductsForCurrentOptician();
      }
    } catch (e) {
      Get.snackbar(
          'Erreur', 'Impossible de charger les données: ${e.toString()}');
    }
  }

  List<Product> get _filteredProducts {
    List<Product> filteredList = productController.products;

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredList = filteredList.where((product) {
        final opticienNom =
            productController.getOpticienNom(product.boutiqueId) ?? '';
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            opticienNom.toLowerCase().contains(query);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    // Apply shop filter
    if (_selectedOpticien != null && _selectedOpticien!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.boutiqueId == _selectedOpticien)
          .toList();
    }

    // Apply price filters
    if (_minPrice != null) {
      filteredList =
          filteredList.where((product) => product.prix >= _minPrice!).toList();
    }

    if (_maxPrice != null) {
      filteredList =
          filteredList.where((product) => product.prix <= _maxPrice!).toList();
    }

    return filteredList;
  }

  // Get paginated data
  List<Product> get _paginatedProducts {
    final filteredList = _filteredProducts;
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
    return (_filteredProducts.length / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          CustomSidebar(currentPage: 'Products'),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              color: _backgroundColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 16),
                  _buildSearchFilterBar(),
                  SizedBox(height: 16),
                  if (_showFilters) _buildAdvancedFilters(),
                  SizedBox(height: 24),
                  Expanded(child: _buildDataTable()),
                  _buildPaginationControls(),
                ],
              ),
            ),
          ),
        ],
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
              'Gestion des Produits',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textPrimaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '${_filteredProducts.length} produits',
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

  Color getColorFromHex(String hexColor) {
    // Assurez-vous que le code est au bon format
    hexColor = hexColor.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }

    // Pour le débogage
    print('Conversion de $hexColor en couleur');

    // Convertir en integer puis en Color
    try {
      return Color(int.parse(hexColor, radix: 16));
    } catch (e) {
      print('Erreur de conversion: $e');
      return Colors.black; // Couleur par défaut en cas d'erreur
    }
  }

  Widget _buildFilterChips() {
    if (_selectedCategory == null &&
        _selectedOpticien == null &&
        _minPrice == null &&
        _maxPrice == null) {
      return Container();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtres actifs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _selectedCategory = null;
                  _selectedOpticien = null;
                  _minPrice = null;
                  _maxPrice = null;
                  _currentPage = 0;
                }),
                icon: Icon(Icons.filter_list_off, size: 16, color: accentColor),
                label: Text(
                  'Effacer tous',
                  style: TextStyle(color: accentColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_selectedCategory != null)
                _buildFilterChip(
                  label: 'Catégorie: $_selectedCategory',
                  onDeleted: () => setState(() => _selectedCategory = null),
                  icon: Icons.category,
                ),
              if (_selectedOpticien != null)
                _buildFilterChip(
                  label:
                      'Boutique: ${productController.getOpticienNom(_selectedOpticien!) ?? ''}',
                  onDeleted: () => setState(() => _selectedOpticien = null),
                  icon: Icons.store,
                ),
              if (_minPrice != null)
                _buildFilterChip(
                  label: 'Prix min: ${_minPrice!.toStringAsFixed(2)} €',
                  onDeleted: () => setState(() => _minPrice = null),
                  icon: Icons.euro,
                ),
              if (_maxPrice != null)
                _buildFilterChip(
                  label: 'Prix max: ${_maxPrice!.toStringAsFixed(2)} €',
                  onDeleted: () => setState(() => _maxPrice = null),
                  icon: Icons.euro,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
    required IconData icon,
  }) {
    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: primaryColor),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDeleted,
      backgroundColor: primaryColor.withOpacity(0.1),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    onChanged: (value) => _filterProducts(),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
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
                      label: Text('${_filteredProducts.length} résultats'),
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
    // Utiliser GetX Obx pour la réactivité
    return Obx(() {
      // Gestion des états de chargement et d'erreur
      if (productController.isLoading) {
        return Center(
          child: CircularProgressIndicator(color: _primaryColor),
        );
      }

      /*  if (productController.error != null) {
        final errorMessage = productController.error!;
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: _errorColor),
              SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: TextStyle(fontSize: 18, color: _textPrimaryColor),
              ),
              SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(color: _textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                // Utiliser une fonction qui est appelée via un callback
                // au lieu d'appeler directement une méthode qui pourrait modifier l'état
                onPressed: () {
                  // Utiliser Future.microtask pour éviter les modifications d'état pendant le build
                  Future.microtask(() => productController.loadProducts());
                },
                child: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }*/

      // Obtenir les produits filtrés mais sans appeler de méthode
      // qui pourrait modifier l'état pendant le build
      final filteredProducts = _filteredProducts;

      // Gestion des résultats vides
      if (filteredProducts.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _searchController.text.isEmpty
                    ? Icons.inventory_2_outlined
                    : Icons.search_off,
                size: 48,
                color: _textSecondaryColor,
              ),
              SizedBox(height: 16),
              Text(
                _searchController.text.isEmpty
                    ? 'Aucun produit disponible'
                    : 'Aucun résultat trouvé',
                style: TextStyle(fontSize: 18, color: _textPrimaryColor),
              ),
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextButton(
                    // Utiliser une fonction qui est appelée via un callback
                    onPressed: () {
                      // Éviter les modifications d'état pendant le build
                      Future.microtask(() => _resetFilters());
                    },
                    child: Text(
                      'Réinitialiser la recherche',
                      style: TextStyle(color: _primaryColor),
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      // Construction de la table de données
      return Container(
        constraints: BoxConstraints(minHeight: 400),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // En-tête du tableau
              Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                decoration: BoxDecoration(
                  color: _primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: _buildProductTableHeader(),
              ),

              // Contenu du tableau
              Expanded(
                child: ListView.separated(
                  itemCount: _paginatedProducts.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final product = _paginatedProducts[index];
                    return Container(
                      padding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 10,
                      ),
                      color: index.isEven ? Colors.white : Colors.grey[50],
                      child: _buildProductTableRow(product),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildProductTableHeader() {
    final columns = [
      TableColumn(flex: 10, label: 'Modèle 3D', icon: Icons.view_in_ar),
      TableColumn(flex: 15, label: 'Nom', icon: Icons.label),
      TableColumn(flex: 15, label: 'Boutique', icon: Icons.store),
      TableColumn(flex: 12, label: 'Catégorie', icon: Icons.category),
      TableColumn(flex: 12, label: 'Marque', icon: Icons.branding_watermark),
      TableColumn(flex: 10, label: 'Couleur', icon: Icons.color_lens),
      TableColumn(flex: 10, label: 'Matériel', icon: Icons.visibility),
      TableColumn(flex: 10, label: 'Genre', icon: Icons.visibility),
      TableColumn(flex: 10, label: 'Type verre', icon: Icons.visibility),
      TableColumn(flex: 8, label: 'Prix', icon: Icons.attach_money),
      TableColumn(flex: 8, label: 'Stock', icon: Icons.inventory),
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

  Widget _buildProductTableRow(Product product) {
    return Row(
      children: [
        Expanded(
          flex: 10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              width: 60, // Largeur fixe pour la cellule
              height: 60, // Hauteur fixe pour la cellule
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.grey[200],
              ),
              child: product.model3D.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Fixed3DViewer(
                        modelUrl: product.model3D,
                        compactMode:
                            true, // Ajoutez ce paramètre à votre Fixed3DViewer
                      ),
                    )
                  : Center(
                      child: Icon(Icons.do_not_disturb_on,
                          size: 24, color: Colors.grey[400]),
                    ),
            ),
          ),
        ),
// Dans la colonne Actions (flex: 10)
        if (product.model3D.isNotEmpty)
          IconButton(
            icon: Icon(Icons.view_in_ar, size: 18, color: _primaryColor),
            onPressed: () => _showFullScreen3DModel(context, product),
            tooltip: 'Voir en 3D',
          ),

        // Nom
        Expanded(
          flex: 15,
          child: _buildTableCell(
            icon: Icons.label_outline,
            text: product.name,
            isImportant: true,
          ),
        ),

        // Boutique
        Expanded(
          flex: 15,
          child: _buildTableCell(
            icon: Icons.store_mall_directory_outlined,
            text: productController.getOpticienNom(product.boutiqueId) ?? 'N/A',
          ),
        ),

        // Catégorie
        Expanded(
          flex: 12,
          child: _buildTableCell(
            icon: Icons.category_outlined,
            text: product.category,
          ),
        ),

        // Marque
        Expanded(
          flex: 12,
          child: _buildTableCell(
            icon: Icons.branding_watermark_outlined,
            text: product.marque,
          ),
        ),

        // Couleur
        Expanded(
          flex: 12,
          child: Row(
            children: [
              for (var i = 0; i < product.couleur.length; i++) ...[
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: getColorFromHex(product.couleur[i]),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
                // only add spacing if this isn’t the last dot
                if (i < product.couleur.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),

        // Type verre
        Expanded(
          flex: 10,
          child: _buildTableCell(
            icon: Icons.visibility_outlined,
            text: product.materiel ?? 'N/A',
          ),
        ),
        Expanded(
          flex: 10,
          child: _buildTableCell(
            icon: Icons.visibility_outlined,
            text: product.sexe ?? 'N/A',
          ),
        ),
        Expanded(
          flex: 10,
          child: _buildTableCell(
            icon: Icons.visibility_outlined,
            text: product.typeVerre ?? 'N/A',
          ),
        ),

        // Prix
        Expanded(
          flex: 8,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: '${product.prix.toStringAsFixed(2)} DT',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.attach_money, size: 16, color: _accentColor),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${product.prix.toStringAsFixed(2)} DT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _accentColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stock
        Expanded(
          flex: 8,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: 'Quantité en stock',
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                decoration: BoxDecoration(
                  color: product.quantiteStock > 10
                      ? _successColor.withOpacity(0.1)
                      : product.quantiteStock > 0
                          ? _warningColor.withOpacity(0.1)
                          : _errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory,
                      size: 16,
                      color: product.quantiteStock > 10
                          ? _successColor
                          : product.quantiteStock > 0
                              ? _warningColor
                              : _errorColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      product.quantiteStock.toString(),
                      style: TextStyle(
                        fontSize: 12,
                        color: product.quantiteStock > 10
                            ? _successColor
                            : product.quantiteStock > 0
                                ? _warningColor
                                : _errorColor,
                        fontWeight: FontWeight.bold,
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
          flex: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.edit, size: 18, color: _infoColor),
                onPressed: () => _showEditProductDialog(context, product),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
                tooltip: 'Modifier',
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.delete, size: 18, color: _errorColor),
                onPressed: () => _showDeleteConfirmation(context, product),
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

  void _showFullScreen3DModel(BuildContext context, Product product) {
    if (product.model3D.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aucun modèle 3D disponible pour ce produit')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Vue 3D - ${product.name}'),
          ),
          body: Rotating3DModel(modelUrl: product.model3D),
        ),
      ),
    );

    Future<bool> _checkModelAvailability(String url) async {
      if (url.isEmpty) return false;

      try {
        final response = await http.head(Uri.parse(url));
        return response.statusCode == 200;
      } catch (e) {
        print('Erreur de vérification du modèle 3D: $e');
        return false;
      }
    }

    String _normalizeModelUrl(String url) {
      // Implémentez votre logique de normalisation d'URL ici
      return GlassesManagerService.ensureAbsoluteUrl(url);
    }

    void _showFullScreen3DModel(BuildContext context, Product product) {
      if (product.model3D.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aucun modèle 3D disponible pour ce produit')),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('Vue 3D - ${product.name}'),
            ),
            body: Fixed3DViewer(modelUrl: product.model3D),
          ),
        ),
      );
    }
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

  // Helper function to generate a color from a string
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'noir':
        return Colors.black;
      case 'blanc':
        return Colors.white;
      case 'rouge':
        return Colors.red;
      case 'bleu':
        return Colors.blue;
      case 'vert':
        return Colors.green;
      case 'jaune':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'violet':
        return Colors.purple;
      case 'rose':
        return Colors.pink;
      case 'gris':
        return Colors.grey;
      case 'marron':
        return Colors.brown;
      default:
        return Color((colorName.hashCode & 0xFFFFFF) | 0xFF000000);
    }
  }

  Widget _buildPagination() {
    final totalPages = _pageCount;

    if (totalPages <= 1) {
      return Container();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Affichage de ${(_currentPage * _itemsPerPage) + 1} à ${min((_currentPage + 1) * _itemsPerPage, _filteredProducts.length)} sur ${_filteredProducts.length} produits',
            style: TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Row(
            children: [
              _buildPaginationButton(
                icon: Icons.first_page,
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage = 0)
                    : null,
                tooltip: 'Première page',
              ),
              _buildPaginationButton(
                icon: Icons.chevron_left,
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                tooltip: 'Page précédente',
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Page ${_currentPage + 1} sur $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: textPrimaryColor,
                  ),
                ),
              ),
              _buildPaginationButton(
                icon: Icons.chevron_right,
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                tooltip: 'Page suivante',
              ),
              _buildPaginationButton(
                icon: Icons.last_page,
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage = totalPages - 1)
                    : null,
                tooltip: 'Dernière page',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: onPressed != null ? primaryColor : Colors.grey.shade400,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
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

  void _filterProducts() {
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      for (var key in _filters.keys) {
        _filters[key] = null;
      }
      _searchController.clear();
      _currentSearchTerm = '';
      _filterProducts();
      _currentPage = 0;
    });
  }

  Widget _buildAdvancedFilters() {
    final boutiqueController = Get.find<BoutiqueController>();

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
                  value: _filters['name'],
                  icon: Icons.label,
                  onChanged: (value) => setState(() {
                    _filters['name'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Catégorie',
                  value: _filters['category'],
                  icon: Icons.category,
                  onChanged: (value) => setState(() {
                    _filters['category'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Marque',
                  value: _filters['marque'],
                  icon: Icons.branding_watermark,
                  onChanged: (value) => setState(() {
                    _filters['marque'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Couleur',
                  value: _filters['couleur'],
                  icon: Icons.color_lens,
                  onChanged: (value) => setState(() {
                    _filters['couleur'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Type verre',
                  value: _filters['typeVerre'],
                  icon: Icons.remove_red_eye,
                  onChanged: (value) => setState(() {
                    _filters['typeVerre'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Prix min (DT)',
                  value: _filters['prixMin'],
                  icon: Icons.attach_money,
                  onChanged: (value) => setState(() {
                    _filters['prixMin'] = value;
                    _filterProducts();
                  }),
                ),
                _buildFilterField(
                  label: 'Prix max (DT)',
                  value: _filters['prixMax'],
                  icon: Icons.money_off,
                  onChanged: (value) => setState(() {
                    _filters['prixMax'] = value;
                    _filterProducts();
                  }),
                ),
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String>(
                    value: _filters['boutique'],
                    decoration: InputDecoration(
                      labelText: 'Boutique',
                      prefixIcon: Icon(Icons.store),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Toutes les boutiques'),
                      ),
                      ...boutiqueController.opticiensList.map((boutique) {
                        return DropdownMenuItem(
                          value: boutique.id,
                          child: Text(boutique.nom),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) => setState(() {
                      _filters['boutique'] = value;
                      _filterProducts();
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        // Create local state variables for the dialog
        String? categoryFilter = _selectedCategory;
        String? opticienFilter = _selectedOpticien;
        double? minPriceFilter = _minPrice;
        double? maxPriceFilter = _maxPrice;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Filtrer les produits'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category filter
                    DropdownButtonFormField<String?>(
                      value: categoryFilter,
                      decoration: const InputDecoration(labelText: 'Catégorie'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toutes les catégories'),
                        ),
                        ...productController.products
                            .map((product) => product.category)
                            .toSet() // Remove duplicates
                            .map((category) => DropdownMenuItem<String?>(
                                  value: category,
                                  child: Text(category),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          categoryFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Opticien filter
                    DropdownButtonFormField<String?>(
                      value: opticienFilter,
                      decoration: const InputDecoration(labelText: 'Boutique'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Toutes les boutiques'),
                        ),
                        ...productController.opticiens
                            .map((opticien) => DropdownMenuItem<String?>(
                                  value: opticien.id,
                                  child: Text(opticien.nom),
                                )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          opticienFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Price range filter
                    const Text('Plage de prix',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: minPriceFilter?.toString() ?? '',
                            decoration:
                                const InputDecoration(labelText: 'Min €'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                minPriceFilter = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: maxPriceFilter?.toString() ?? '',
                            decoration:
                                const InputDecoration(labelText: 'Max €'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              setState(() {
                                maxPriceFilter = double.tryParse(value);
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    // Reset all filters
                    this.setState(() {
                      _selectedCategory = null;
                      _selectedOpticien = null;
                      _minPrice = null;
                      _maxPrice = null;
                      _currentPage = 0;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Réinitialiser'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Apply filters
                    this.setState(() {
                      _selectedCategory = categoryFilter;
                      _selectedOpticien = opticienFilter;
                      _minPrice = minPriceFilter;
                      _maxPrice = maxPriceFilter;
                      _currentPage =
                          0; // Reset to first page when applying filters
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
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

  void _showEditProductDialog(BuildContext context, Product product) {
    final formKey = GlobalKey<FormState>();
    PlatformFile? _tempSelectedFile;
    bool isModel3D = false;
    bool hasNewFile = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Modifier le produit'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sélection du type de fichier (image ou modèle 3D)
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Modèle 3D'),
                            value: true,
                            groupValue: isModel3D,
                            onChanged: (value) {
                              setState(() {
                                isModel3D = value!;
                                _tempSelectedFile = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    // Container pour le file picker (uniquement modèle 3D)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Model3DPickerWidget(
                        onFilePicked: (file) {
                          setState(() {
                            _tempSelectedFile = file;
                            hasNewFile = true;
                          });
                        },
                      ),
                    ),

                    // Aperçu du fichier actuel ou nouveau
                    if (hasNewFile && _tempSelectedFile != null)
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Nouveau Modèle 3D sélectionné: ${_tempSelectedFile?.name}',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
                      )
                    else if (product.model3D.isNotEmpty)
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          'Modèle 3D actuel',
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),

                    // Bouton pour supprimer le modèle 3D actuel
                    if (!hasNewFile && product.model3D.isNotEmpty)
                      TextButton.icon(
                        icon: Icon(Icons.delete, color: Colors.red),
                        label: Text('Supprimer modèle 3D actuel'),
                        onPressed: () {
                          setState(() {
                            product.model3D = '';
                            hasNewFile = true; // Pour forcer la mise à jour
                          });
                        },
                      ),

                    const SizedBox(height: 20),

                    // Nom du produit
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Nom du produit',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.shopping_bag),
                      ),
                      initialValue: product.name,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un nom';
                        }
                        return null;
                      },
                      onSaved: (value) => product.name = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      initialValue: product.description,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une description';
                        }
                        return null;
                      },
                      onSaved: (value) => product.description = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: product.category,
                      decoration: InputDecoration(
                        labelText: 'Catégorie',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.category),
                      ),
                      items: categories.map((String category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        product.category = value ?? '';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Marque
                    DropdownButtonFormField<String>(
                      value: product.marque,
                      decoration: InputDecoration(
                        labelText: 'Marque',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.branding_watermark),
                      ),
                      items: marques.map((String marque) {
                        return DropdownMenuItem(
                          value: marque,
                          child: Text(marque),
                        );
                      }).toList(),
                      onChanged: (value) {
                        product.marque = value ?? '';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Couleur avec un sélecteur amélioré
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.color_lens),
                            title: const Text('Couleurs'),
                            subtitle: const Text(
                                'Sélectionnez une ou plusieurs couleurs'),
                            trailing: ElevatedButton(
                              child: const Text('Ajouter'),
                              onPressed: () async {
                                // Initialize with black or last selected color
                                Color initialColor = Colors.black;
                                if (product.couleur.isNotEmpty) {
                                  initialColor =
                                      getColorFromHex(product.couleur.last);
                                }

                                final Color? pickedColor = await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: const Text(
                                          'Sélectionnez une couleur'),
                                      content: SingleChildScrollView(
                                        child: ColorPicker(
                                          pickerColor: initialColor,
                                          onColorChanged: (color) {
                                            initialColor = color;
                                          },
                                          showLabel: true,
                                          pickerAreaHeightPercent: 0.8,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context, null);
                                          },
                                          child: const Text('Annuler'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                                context, initialColor);
                                          },
                                          child: const Text('Ajouter'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (pickedColor != null) {
                                  setState(() {
                                    // Convert color to hex and add to list
                                    String colorHex = pickedColor.red
                                            .toRadixString(16)
                                            .padLeft(2, '0') +
                                        pickedColor.green
                                            .toRadixString(16)
                                            .padLeft(2, '0') +
                                        pickedColor.blue
                                            .toRadixString(16)
                                            .padLeft(2, '0');

                                    // Check if this color is already in the list
                                    if (!product.couleur.contains(colorHex)) {
                                      product.couleur.add(colorHex);
                                    }
                                  });
                                }
                              },
                            ),
                          ),

                          // Display selected colors
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: product.couleur.map((colorHex) {
                                return Stack(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: getColorFromHex(colorHex),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: InkWell(
                                        onTap: () {
                                          // Don't remove if it's the last color
                                          if (product.couleur.length > 1) {
                                            setState(() {
                                              product.couleur.remove(colorHex);
                                            });
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child:
                                              const Icon(Icons.close, size: 14),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Style
                    DropdownButtonFormField<String>(
                      value: product.style.isNotEmpty ? product.style : null,
                      decoration: InputDecoration(
                        labelText: 'Style',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.style),
                      ),
                      items: styles.map((String style) {
                        return DropdownMenuItem(
                          value: style,
                          child: Text(style),
                        );
                      }).toList(),
                      onChanged: (value) {
                        product.style = value ?? '';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Type de verre
                    DropdownButtonFormField<String>(
                      value: product.typeVerre,
                      decoration: InputDecoration(
                        labelText: 'Type de verre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.visibility),
                      ),
                      items: typesVerre.map((String type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (value) {
                        product.typeVerre = value ?? '';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Matériau',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        prefixIcon: const Icon(Icons.construction),
                      ),
                      value:
                          product.materiel.isNotEmpty ? product.materiel : null,
                      items: const [
                        DropdownMenuItem(
                            value: 'Acétate', child: Text('Acétate')),
                        DropdownMenuItem(value: 'Métal', child: Text('Métal')),
                        DropdownMenuItem(value: 'Mixte', child: Text('Mixte')),
                      ],
                      onChanged: (value) {
                        product.materiel = value ?? '';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Genre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.person),
                      ),
                      value: product.sexe.isNotEmpty ? product.sexe : null,
                      items: const [
                        DropdownMenuItem(
                            value: 'feminin', child: Text('Féminin')),
                        DropdownMenuItem(
                            value: 'masculin', child: Text('Masculin')),
                        DropdownMenuItem(
                            value: 'unisexe', child: Text('Unisexe')),
                      ],
                      onChanged: (value) {
                        product.sexe = value ?? 'unisexe';
                      },
                      validator: (value) =>
                          value == null ? 'Ce champ est requis' : null,
                    ),
                    const SizedBox(height: 16),
                    // Prix
                    TextFormField(
                      initialValue: product.prix.toString(),
                      decoration: InputDecoration(
                        labelText: 'Prix (DT)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.price_change),
                        hintText: 'Ex: 125.50',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer un prix';
                        }
                        final price = double.tryParse(value);
                        if (price == null) {
                          return 'Format invalide';
                        }
                        if (price <= 0) {
                          return 'Le prix doit être supérieur à 0';
                        }
                        return null;
                      },
                      onSaved: (value) =>
                          product.prix = double.tryParse(value ?? '0') ?? 0,
                    ),
                    const SizedBox(height: 16),

                    // Quantité en stock
                    TextFormField(
                      initialValue: product.quantiteStock.toString(),
                      decoration: InputDecoration(
                        labelText: 'Quantité en stock',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.inventory),
                        hintText: 'Ex: 25',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une quantité';
                        }
                        final quantity = int.tryParse(value);
                        if (quantity == null) {
                          return 'Format invalide';
                        }
                        if (quantity < 0) {
                          return 'La quantité ne peut pas être négative';
                        }
                        return null;
                      },
                      onSaved: (value) => product.quantiteStock =
                          int.tryParse(value ?? '0') ?? 0,
                    ),
                    const SizedBox(height: 16),

                    // Boutique dropdown
                    DropdownButtonFormField<String>(
                      value: product.boutiqueId,
                      decoration: InputDecoration(
                        labelText: 'Boutique',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.store),
                      ),
                      items: productController.opticiens.map((opticien) {
                        return DropdownMenuItem<String>(
                          value: opticien.id,
                          child: Text(opticien.nom),
                        );
                      }).toList(),
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Veuillez sélectionner une boutique'
                          : null,
                      onChanged: (value) {
                        product.boutiqueId = value ?? '';
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (formKey.currentState?.validate() ?? false) {
                    formKey.currentState?.save();

                    // Afficher l'indicateur de chargement
                    BuildContext dialogContext = context;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Modification en cours'),
                          content: Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                    'Mise à jour du produit "${product.name}"...'),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      // Upload du fichier si sélectionné
                      if (hasNewFile &&
                          _tempSelectedFile != null &&
                          _tempSelectedFile!.bytes != null) {
                        if (isModel3D) {
                          // Upload du modèle 3D
                          String? modelUrl =
                              await GlassesManagerService.uploadModel3D(
                            _tempSelectedFile!.bytes!,
                            _tempSelectedFile!.name,
                            product.id ?? '',
                          );

                          if (modelUrl == null || modelUrl.isEmpty) {
                            throw Exception(
                                'Le serveur n\'a pas renvoyé d\'URL valide');
                          }

                          product.model3D = modelUrl;
                        } else {
                          // Upload de l'image
                          final imageUrl =
                              await productController.uploadImageWeb(
                            _tempSelectedFile!.bytes!,
                            _tempSelectedFile!.name,
                            product.id ?? '',
                          );
                          product.image = imageUrl;
                        }
                      }

                      // Mettre à jour le produit
                      await productController.updateProduct(
                          product.id!, product);

                      // Fermer les dialogues
                      Navigator.of(context).pop();
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Produit mis à jour avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Voulez-vous vraiment supprimer ${product.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              productController.deleteProduct(product.id!);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<String> _uploadImageAndGetUrl(
      PlatformFile? imageFile, String productId) async {
    if (imageFile == null) {
      return '';
    }

    try {
      if (kIsWeb) {
        // Pour le web, utilisez les octets de l'image
        if (imageFile.bytes != null) {
          final imageUrl = await productController.uploadImageWeb(
            imageFile.bytes!,
            imageFile.name,
            productId, // Ajoutez le productId ici
          );
          return imageUrl;
        }
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
