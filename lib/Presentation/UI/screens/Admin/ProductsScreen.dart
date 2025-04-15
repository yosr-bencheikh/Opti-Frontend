import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Model3DPickerWidget.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/ProductFilterWidget.dart';
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
  TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 5;

  // Filter variables
  String? _selectedCategory;
  String? _selectedOpticien;
  String? _selectedMarque; // Ajout de cette variable manquante
  String? _selectedStyle; // Ajout de cette variable manquante
  String? _selectedTypeVerre;
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
  final Color _infoColor = Color(0xFF1976D2); // Info blue
  final Color _errorColor = Color(0xFFD32F2F); // Error red
  final Color _successColor = Color(0xFF388E3C); // Success green
  final Color _warningColor = Color(0xFFFFA000); // Warning amber

  // Palette de couleurs pour un design cohérent
  final Color _primaryColor = const Color.fromARGB(255, 33, 199, 146);
  final Color _secondaryColor = const Color.fromARGB(255, 16, 16, 17);
  final Color _accentColor = const Color(0xFFFF4081);
  final Color _lightPrimaryColor = const Color(0xFFC5CAE9);
  final Color _backgroundColor = const Color(0xFFF5F7FA);
  final Color _cardColor = Colors.white;
  final Color _textPrimaryColor = const Color(0xFF212121);
  final Color _textSecondaryColor = const Color(0xFF757575);

  String _currentSearchTerm = '';

  @override
  void initState() {
    super.initState();
    // Ajout d'un listener pour tracker la valeur de recherche
    _searchController.addListener(() {
      setState(() {
        _currentSearchTerm = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Product> get _filteredProducts {
    // Utilisez productController.products directement (déjà un RxList)
    List<Product> filteredList = productController.products;

    // Appliquer le filtre de recherche
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

    // Appliquer les autres filtres
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.category == _selectedCategory)
          .toList();
    }

    if (_selectedOpticien != null && _selectedOpticien!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.boutiqueId == _selectedOpticien)
          .toList();
    }

    if (_selectedMarque != null && _selectedMarque!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.marque == _selectedMarque)
          .toList();
    }

    if (_selectedStyle != null && _selectedStyle!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.style == _selectedStyle)
          .toList();
    }

    if (_selectedTypeVerre != null && _selectedTypeVerre!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.typeVerre == _selectedTypeVerre)
          .toList();
    }

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

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _currentSearchTerm = '';
      _selectedCategory = null;
      _selectedOpticien = null;
      _selectedMarque = null;
      _selectedStyle = null;
      _minPrice = null;
      _maxPrice = null;
      _currentPage = 0;
    });
  }

  void _filterProducts() {
    setState(() {
      // Forcer le recalcul en modifiant une variable
      _currentPage = 0;
    });
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
      body: Container(
        padding: EdgeInsets.all(16),
        color: _backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 16),
            _buildSearchFilterBar(),
            if (_showFilters) ...[
              SizedBox(height: 12),
              ProductFilterWidget(
                initialFilters: {
                  'nom': _currentSearchTerm,
                  'boutique': _selectedOpticien ?? '',
                  'categorie': _selectedCategory ?? '',
                  'marque': _selectedMarque ?? '',
                  'typesVerre': _selectedStyle ?? '',
                  'minPrice': _minPrice?.toString() ?? '',
                  'maxPrice': _maxPrice?.toString() ?? '',
                },
                onFilterChanged: (newFilters) {
                  setState(() {
                    _currentSearchTerm = newFilters['nom'] ?? '';
                    _selectedOpticien = newFilters['boutique']!.isNotEmpty
                        ? newFilters['boutique']
                        : null;
                    _selectedCategory = newFilters['categorie']!.isNotEmpty
                        ? newFilters['categorie']
                        : null;
                    _selectedMarque = newFilters['marque']!.isNotEmpty
                        ? newFilters['marque']
                        : null;
                    _selectedStyle = newFilters['typesVerre']!.isNotEmpty
                        ? newFilters['typesVerre']
                        : null;
                    _minPrice = newFilters['minPrice']!.isNotEmpty
                        ? double.tryParse(newFilters['minPrice']!)
                        : null;
                    _maxPrice = newFilters['maxPrice']!.isNotEmpty
                        ? double.tryParse(newFilters['maxPrice']!)
                        : null;
                    _currentPage = 0;
                  });
                },
              ),
            ],
            SizedBox(height: 16),
            Expanded(
              // Prend tout l'espace disponible
              child: _buildDataTable(),
            ),
            _buildPaginationControls(),
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

  Widget _buildSearchFilterBar() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
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
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterProducts(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 8),
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
                        contentPadding: const EdgeInsets.symmetric(
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
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.symmetric(
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
                            Icons.shopping_bag_rounded,
                            size: 16,
                            color: _primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_filteredProducts.length} résultats',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8),
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
                    'Produits',
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
                        text: '${_filteredProducts.length} ',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      TextSpan(
                        text: 'Produits enregistrés',
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
              onPressed: () => _showAddProductDialog(context),
              icon: Icon(Icons.add, size: 20),
              label: Text(
                'Nouvel produits',
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

  Widget _buildDataTable() {

  return Obx(() {
    // Gestion des états de chargement et d'erreur
    if (productController.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: _primaryColor),
      );
    }

if (productController.error != null) {
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
          onPressed: () => productController.loadProducts(),
          child: Text('Réessayer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}



    // Obtenir les produits filtrés
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
                  onPressed: _resetFilters,
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
      TableColumn(flex: 10, label: 'Image', icon: Icons.image),
      TableColumn(flex: 15, label: 'Nom', icon: Icons.label),
      TableColumn(flex: 15, label: 'Boutique', icon: Icons.store),
      TableColumn(flex: 12, label: 'Catégorie', icon: Icons.category),
      TableColumn(flex: 12, label: 'Marque', icon: Icons.branding_watermark),
      TableColumn(flex: 10, label: 'Couleur', icon: Icons.color_lens),
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
        // Image
        Expanded(
          flex: 10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: product.name,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  image: product.image.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(product.image),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: product.image.isEmpty
                    ? Icon(Icons.image_not_supported,
                        size: 20, color: Colors.grey[400])
                    : null,
              ),
            ),
          ),
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
          flex: 10,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Tooltip(
              message: product.couleur,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.color_lens_outlined,
                      size: 16, color: _textSecondaryColor),
                  SizedBox(width: 6),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getColorFromString(product.couleur),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      product.couleur,
                      style: TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Type verre
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

  Widget _buildActionButtons(Product product) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.edit_outlined,
          onPressed: () => _showEditProductDialog(context, product),
          tooltip: 'Modifier',
          color: primaryColor,
        ),
        _buildActionButton(
          icon: Icons.delete_outline,
          onPressed: () => _showDeleteConfirmation(context, product),
          tooltip: 'Supprimer',
          color: accentColor,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          icon: Icon(icon, size: 20),
          onPressed: onPressed,
          color: color,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: color.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    PlatformFile? _tempSelectedFile;
    bool isModel3D = false;

    // Variable pour stocker la couleur sélectionnée avec une valeur par défaut
    Color selectedColor = Colors.black;

    // Créer un objet produit avec des champs vides
    Product product = Product(
      name: '',
      description: '',
      category: '',
      marque: '',
      couleur: '000000', // Noir par défaut en format hexadécimal
      prix: 0,
      quantiteStock: 0,
      image: '',
      model3D: '',
      typeVerre: '',

      averageRating: 0.0,
      totalReviews: 0, style: '',
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Ajouter un produit'),
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
                            title: const Text('Image'),
                            value: false,
                            groupValue: isModel3D,
                            onChanged: (value) {
                              setState(() {
                                isModel3D = value!;
                                _tempSelectedFile = null;
                              });
                            },
                          ),
                        ),
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

                    // Container pour le file picker
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: isModel3D
                          ? Model3DPickerWidget(
                              onFilePicked: (file) {
                                setState(() {
                                  _tempSelectedFile = file;
                                });
                              },
                            )
                          : FilePickerExample(
                              // Utilisez votre composant FilePickerExample existant
                              onImagePicked: (image) {
                                setState(() {
                                  _tempSelectedFile = image;
                                });
                              },
                            ),
                    ),

                    // Aperçu du modèle 3D ou de l'image
                    if (_tempSelectedFile != null)
                      Container(
                        height: 50,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          '${isModel3D ? 'Modèle 3D' : 'Image'} sélectionné: ${_tempSelectedFile?.name}',
                          style: TextStyle(color: Colors.blue[700]),
                        ),
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
                      child: ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: const Text('Couleur '),
                        subtitle: const Text('Sélectionnez une couleur'),
                        trailing: Container(
                          width: 50,
                          height: 30,
                          decoration: BoxDecoration(
                            color: getColorFromHex(product.couleur),
                            borderRadius: BorderRadius.circular(
                                8), // Rectangle avec coins arrondis
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        onTap: () async {
                          // Initialiser le color picker avec la couleur actuelle
                          Color initialColor = selectedColor;

                          final Color? pickedColor = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Sélectionnez une couleur'),
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
                                      Navigator.pop(context, initialColor);
                                    },
                                    child: const Text('Valider'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (pickedColor != null) {
                            setState(() {
                              selectedColor = pickedColor;

                              // Convertir la couleur en format hexadécimal RGB
                              String colorHex = pickedColor.red
                                      .toRadixString(16)
                                      .padLeft(2, '0') +
                                  pickedColor.green
                                      .toRadixString(16)
                                      .padLeft(2, '0') +
                                  pickedColor.blue
                                      .toRadixString(16)
                                      .padLeft(2, '0');

                              product.couleur = colorHex;

                              // Afficher la couleur pour débogage
                              print('Couleur sélectionnée: $colorHex');
                              print('Couleur objet: ${pickedColor.toString()}');
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
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
                      decoration: InputDecoration(
                        labelText: 'Type de verre ',
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

                    // Prix avec validation améliorée
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Prix (DT) ',
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

                    // Quantité en stock avec validation améliorée
                    TextFormField(
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

                    // Opticien dropdown
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Boutique ',
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
                          ? 'Veuillez sélectionner un opticien'
                          : null,
                      onChanged: (value) {
                        product.boutiqueId = value ?? '';
                      },
                      onSaved: (value) {
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

                    // Afficher l'indicateur de chargement dans le bouton
                    BuildContext dialogContext = context;

                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Ajout en cours'),
                          content: Row(
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                    'Ajout du produit "${product.name}"...'),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    try {
                      // Upload file based on type
                      if (_tempSelectedFile != null &&
                          _tempSelectedFile!.bytes != null) {
                        if (isModel3D) {
                          // Upload model 3D using GlassesManagerService
                          final modelUrl =
                              await GlassesManagerService.uploadModel3D(
                            _tempSelectedFile!.bytes!,
                            _tempSelectedFile!.name,
                            product.id ??
                                '', // Utilisez l'ID s'il existe, sinon chaîne vide
                          );
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
                      } else if (_tempSelectedFile == null) {
                        // Si aucun fichier n'est sélectionné, afficher un message d'erreur
                        Navigator.of(context)
                            .pop(); // Fermer le dialogue de chargement
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Veuillez sélectionner une image ou un modèle 3D'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return; // Ne pas continuer
                      }

                      // Création du produit
                      final success =
                          await productController.addProduct(product);

                      // Fermer la boîte de dialogue de chargement
                      Navigator.of(context).pop();

                      if (success) {
                        // Fermer la boîte de dialogue du formulaire
                        Navigator.of(dialogContext).pop();

                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('Produit ajouté avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text('Erreur: ${productController.error}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      // Fermer la boîte de dialogue de chargement
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

  void _showEditProductDialog(BuildContext context, Product product) {
    final formKey = GlobalKey<FormState>();
    final editedProduct = product.copyWith();
    PlatformFile? _tempSelectedImage;

    Color selectedColor = Colors.black;

    bool hasNewImage = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Modifier le produit'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Affichage conditionnel: soit la nouvelle image, soit l'ancienne
                  if (hasNewImage && _tempSelectedImage != null)
                    // Afficher la nouvelle image sélectionnée
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: _tempSelectedImage!.bytes != null
                          ? Image.memory(
                              _tempSelectedImage!.bytes!,
                              fit: BoxFit.contain,
                            )
                          : Center(child: Text('Aperçu non disponible')),
                    )
                  else if (product.image.isNotEmpty)
                    // Afficher l'image actuelle du produit
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(product.image),
                          fit: BoxFit.contain,
                        ),
                        border: Border.all(color: Colors.grey),
                      ),
                    )
                  else
                    // Aucune image disponible
                    Container(
                      height: 120,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(child: Text('Aucune image')),
                    ),
                  const SizedBox(height: 8),

                  // Image picker pour choisir une nouvelle image
                  FilePickerExample(
                    onImagePicked: (image) {
                      setState(() {
                        _tempSelectedImage = image;
                        hasNewImage = true;
                      });
                    },
                  ),

                  // Bouton pour revenir à l'image précédente
                  if (hasNewImage && product.image.isNotEmpty)
                    TextButton.icon(
                      icon: Icon(Icons.restore),
                      label: Text('Revenir à l\'image précédente'),
                      onPressed: () {
                        setState(() {
                          _tempSelectedImage = null;
                          hasNewImage = false;
                        });
                      },
                    ),

                  const SizedBox(height: 16),

                  // Champs pour le formulaire (les mêmes que précédemment)
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Nom du produit'),
                    initialValue: product.name,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },
                    onSaved: (value) => product.name = value ?? '',
                  ),
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Description '),
                    initialValue: product.description,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },
                    onSaved: (value) => product.description = value ?? '',
                  ),
                  const SizedBox(height: 16),
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
                    child: ListTile(
                      leading: const Icon(Icons.color_lens),
                      title: const Text('Couleur '),
                      subtitle: const Text('Sélectionnez une couleur'),
                      trailing: Container(
                        width: 50,
                        height: 30,
                        decoration: BoxDecoration(
                          color: getColorFromHex(product.couleur),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey),
                        ),
                      ),
                      onTap: () async {
                        // Initialiser le color picker avec la couleur actuelle
                        Color initialColor = selectedColor;

                        final Color? pickedColor = await showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Sélectionnez une couleur'),
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
                                    Navigator.pop(context, initialColor);
                                  },
                                  child: const Text('Valider'),
                                ),
                              ],
                            );
                          },
                        );

                        if (pickedColor != null) {
                          setState(() {
                            selectedColor = pickedColor;

                            // Convertir la couleur en format hexadécimal RGB
                            String colorHex = pickedColor.red
                                    .toRadixString(16)
                                    .padLeft(2, '0') +
                                pickedColor.green
                                    .toRadixString(16)
                                    .padLeft(2, '0') +
                                pickedColor.blue
                                    .toRadixString(16)
                                    .padLeft(2, '0');

                            product.couleur = colorHex;

                            // Afficher la couleur pour débogage
                            print('Couleur sélectionnée: $colorHex');
                            print('Couleur objet: ${pickedColor.toString()}');
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: product.style.isNotEmpty ? product.style : null,
                    decoration: InputDecoration(
                      labelText: 'Style',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.visibility),
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
                      labelText: 'Type de verre ',
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

                  // Prix avec validation améliorée
                  TextFormField(
                    initialValue: product.prix.toString(),
                    decoration: InputDecoration(
                      labelText: 'Prix (DT) ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.price_change_rounded),
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

                  // Quantité en stock avec validation améliorée
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
                    onSaved: (value) =>
                        product.quantiteStock = int.tryParse(value ?? '0') ?? 0,
                  ),
                  const SizedBox(height: 16),

                  // Opticien dropdown
                  DropdownButtonFormField<String>(
                    value: product.boutiqueId,
                    decoration: InputDecoration(
                      labelText: 'Boutique ',
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
                        ? 'Veuillez sélectionner un opticien'
                        : null,
                    onChanged: (value) {
                      product.boutiqueId = value ?? '';
                    },
                    onSaved: (value) {
                      product.boutiqueId = value ?? '';
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
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
                    // Uploader la nouvelle image si sélectionnée
                    if (hasNewImage &&
                        _tempSelectedImage != null &&
                        _tempSelectedImage!.bytes != null) {
                      final imageUrl = await productController.uploadImageWeb(
                        _tempSelectedImage!.bytes!,
                        _tempSelectedImage!.name,
                        product.id ?? '', // Utiliser l'ID existant du produit
                      );
                      product.image =
                          imageUrl; // Mettre à jour l'URL de l'image
                    }

                    // Mettre à jour le produit avec tous les champs
                    await productController.updateProduct(product.id!, product);

                    // Fermer la boîte de dialogue de chargement
                    Navigator.of(context).pop();

                    // Fermer la boîte de dialogue du formulaire
                    Navigator.of(dialogContext).pop();

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                        content: Text('Produit mis à jour avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Fermer la boîte de dialogue de chargement
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
              child: const Text('Mettre à jour'),
            ),
          ],
        );
      }),
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
