import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({Key? key}) : super(key: key);

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductController productController = Get.find();
  File? _imageFile;
PlatformFile? _tempSelectedImage;
  TextEditingController _searchController = TextEditingController();
  
  // Pagination variables
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  
  // Filter variables
  String? _selectedCategory;
  String? _selectedOpticien;
  double? _minPrice;
  double? _maxPrice;

  
  // Color scheme for the app
  final Color primaryColor = const Color(0xFF1A73E9);
  final Color secondaryColor = const Color(0xFF4285F4);
  final Color accentColor = const Color(0xFFEA4335);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF202124);
  final Color textSecondaryColor = const Color(0xFF5F6368);
  
  @override
  void initState() {
    super.initState();
  }

  List<Product> get _filteredProducts {
    List<Product> filteredList = productController.products;
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filteredList = filteredList.where((product) {
        final opticienNom = productController.getOpticienNom(product.boutiqueId) ?? '';
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query) ||
            opticienNom.toLowerCase().contains(query);
      }).toList();
    }
    
    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filteredList = filteredList.where((product) => 
        product.category == _selectedCategory).toList();
    }
    
    // Apply shop filter
    if (_selectedOpticien != null && _selectedOpticien!.isNotEmpty) {
      filteredList = filteredList.where((product) => 
        product.boutiqueId == _selectedOpticien).toList();
    }
    
    // Apply price filters
    if (_minPrice != null) {
      filteredList = filteredList.where((product) => 
        product.prix >= _minPrice!).toList();
    }
    
    if (_maxPrice != null) {
      filteredList = filteredList.where((product) => 
        product.prix <= _maxPrice!).toList();
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
      backgroundColor: backgroundColor,
      body: Obx(() =>
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion Produits',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredProducts.length} produits',
                style: TextStyle(
                  fontSize: 14,
                  color: const Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Row(
            children: [
              FilledButton.icon(
                onPressed: () => _showFilterDialog(),
                icon: const Icon(Icons.filter_alt, size: 18),
                label: const Text('Filtrer'),
                style: FilledButton.styleFrom(
                  backgroundColor: cardColor,
                  foregroundColor: textPrimaryColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _showAddProductDialog(context),
                icon: const Icon(Icons.person_add),
            label: const Text('Nouveau produit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 84, 151, 198),
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
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (productController.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 100),
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 24),
            Text(
              'Chargement des produits...',
              style: TextStyle(color: textSecondaryColor, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (productController.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.error_outline, size: 64, color: accentColor),
            const SizedBox(height: 16),
            Text(
              'Erreur: ${productController.error}',
              style: TextStyle(color: textSecondaryColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => productController.loadProducts(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 80),
            Icon(Icons.search_off, size: 64, color: textSecondaryColor.withOpacity(0.6)),
            const SizedBox(height: 16),
            Text(
              'Aucun produit trouvé',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez de modifier vos filtres ou d\'ajouter un nouveau produit',
              style: TextStyle(
                fontSize: 16,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() {
                _selectedCategory = null;
                _selectedOpticien = null;
                _minPrice = null;
                _maxPrice = null;
                _searchController.clear();
                _currentPage = 0;
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Effacer les filtres'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSearchAndFilterSection(),
        const SizedBox(height: 16),
        _buildFilterChips(),
        const SizedBox(height: 16),
        _buildProductsTable(),
      ],
    );
  }
  
  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(4),
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
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _currentPage = 0; // Reset to first page on search
          });
        },
        decoration: InputDecoration(
                    hintText: 'Rechercher un produit',
                    prefixIcon: Icon(Icons.search, color:  Color.fromARGB(255, 84, 151, 198)),
                    filled: true,
                    fillColor: Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Color.fromARGB(255, 84, 151, 198), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    hintStyle: TextStyle(color: Color(0xFF757575)),
                  ),
                  style: TextStyle(color: const Color(0xFF212121), fontSize: 15),
      ),
    );
  }
  
  Widget _buildFilterChips() {
    if (_selectedCategory == null && _selectedOpticien == null && 
        _minPrice == null && _maxPrice == null) {
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
                  label: 'Boutique: ${productController.getOpticienNom(_selectedOpticien!) ?? ''}',
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
  
  Widget _buildProductsTable() {
    return Container(
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
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(backgroundColor),
              dataRowMaxHeight: 100,
              dataRowMinHeight: 80,
              headingRowHeight: 56,
              horizontalMargin: 24,
              dividerThickness: 0.5,
              showCheckboxColumn: false,
              columns: [
                DataColumn(
                  label: _buildColumnHeader('Image'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Boutique'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Nom'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Catégorie'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Description'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Marque'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Couleur'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Type de verre'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Prix'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Stock'),
                ),
                DataColumn(
                  label: _buildColumnHeader('Actions'),
                ),
              ],
              rows: _paginatedProducts.map((product) {
                return DataRow(
                  cells: [
                    DataCell(
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                          color: Colors.grey.shade50,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: product.image.isNotEmpty
                            ? Image.network(
                                product.image,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.grey.shade400,
                                ),
                              )
                            : Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey.shade400,
                              ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          productController.getOpticienNom(product.boutiqueId) ?? 'N/A',
                          style: TextStyle(
                            color: textSecondaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: textPrimaryColor,
                            ),
                          ),
                          if (product.averageRating > 0)
                            Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  '${product.averageRating.toStringAsFixed(1)} (${product.totalReviews})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.category,
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Tooltip(
                        message: product.description,
                        child: Text(
                          product.description.length > 50
                              ? '${product.description.substring(0, 50)}...'
                              : product.description,
                          style: TextStyle(color: textSecondaryColor),
                        ),
                      ),
                    ),
                    DataCell(Text(product.marque)),
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                          color: getColorFromHex(product.couleur),
                          borderRadius: BorderRadius.circular(8), // Rectangle avec coins arrondis
                          border: Border.all(color: Colors.grey),
                        ),
                          ),
                          const SizedBox(width: 8),
                          Text(product.couleur),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        product.typeVerre ?? 'N/A',
                        style: TextStyle(
                          color: product.typeVerre?.isNotEmpty == true
                              ? textPrimaryColor
                              : Colors.grey.shade400,
                          fontStyle: product.typeVerre?.isNotEmpty == true
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        '${product.prix.toStringAsFixed(2)} DT',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: product.quantiteStock > 10
                              ? Colors.green.shade50
                              : product.quantiteStock > 0
                                  ? Colors.orange.shade50
                                  : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.quantiteStock.toString(),
                          style: TextStyle(
                            color: product.quantiteStock > 10
                                ? Colors.green.shade700
                                : product.quantiteStock > 0
                                    ? Colors.orange.shade700
                                    : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    DataCell(_buildActionButtons(product)),
                  ],
                );
              }).toList(),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
  
  Widget _buildColumnHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
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
        // Generate a color from the string hash
        final int hash = colorName.hashCode;
        return Color((hash & 0xFFFFFF) | 0xFF000000);
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
                    const Text('Plage de prix', style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: minPriceFilter?.toString() ?? '',
                            decoration: const InputDecoration(labelText: 'Min €'),
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
                            decoration: const InputDecoration(labelText: 'Max €'),
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
                      _currentPage = 0; // Reset to first page when applying filters
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
  String? uploadedImageUrl;
  PlatformFile? _tempSelectedImage;

  // Listes étendues avec plus d'options
  final List<String> categories = ['Solaire', 'Vue', 'Sport', 'Lecture', 'Enfant', 'Luxe', 'Tendance', 'Protection'];
  final List<String> marques = ['Ray-Ban', 'Oakley', 'Gucci', 'Prada', 'Dior', 'Chanel', 'Versace', 'Tom Ford', 'Persol', 'Carrera'];
  final List<String> typesVerre = ['Simple', 'Progressif', 'Bifocal', 'Photochromique', 'Antireflet', 'Polarisé', 'Anti-lumière bleue'];

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
    typeVerre: '',
    boutiqueId: '',
    averageRating: 0.0,
    totalReviews: 0,
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
                  // Image picker avec style amélioré
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: FilePickerExample(
                      onImagePicked: (image) {
                        setState(() {
                          _tempSelectedImage = image;
                        });
                      },
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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
                          borderRadius: BorderRadius.circular(8), // Rectangle avec coins arrondis
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
                            String colorHex = pickedColor.red.toRadixString(16).padLeft(2, '0') +
                                              pickedColor.green.toRadixString(16).padLeft(2, '0') +
                                              pickedColor.blue.toRadixString(16).padLeft(2, '0');

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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    onSaved: (value) => product.prix = double.tryParse(value ?? '0') ?? 0,
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
                    onSaved: (value) => product.quantiteStock = int.tryParse(value ?? '0') ?? 0,
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
                        child: Text(opticien.nom ?? 'Sans nom'),
                      );
                    }).toList(),
                    validator: (value) => value?.isEmpty ?? true ? 'Veuillez sélectionner un opticien' : null,
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
                              child: Text('Ajout du produit "${product.name}"...'),
                            ),
                          ],
                        ),
                      );
                    },
                  );

                  try {
                    // Upload image first if selected
                    if (_tempSelectedImage != null && _tempSelectedImage!.bytes != null) {
                      final imageUrl = await productController.uploadImageWeb(
                        _tempSelectedImage!.bytes!,
                        _tempSelectedImage!.name,
                        '', // Empty productId for now
                      );
                      product.image = imageUrl; // Set the image URL
                    }

                    // Now create the product with all fields populated
                    final success = await productController.addProduct(product);

                    if (success) {
                      // Fermer la boîte de dialogue de chargement
                      Navigator.of(context).pop();

                      // Fermer la boîte de dialogue du formulaire
                      Navigator.of(dialogContext).pop();

                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(
                          content: Text('Produit ajouté avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      // Fermer la boîte de dialogue de chargement
                      Navigator.of(context).pop();

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
  // Variable pour stocker l'image temporairement sélectionnée
  PlatformFile? _tempSelectedImage;
    final List<String> categories = ['Solaire', 'Vue', 'Sport', 'Lecture', 'Enfant', 'Luxe', 'Tendance', 'Protection'];
  final List<String> marques = ['Ray-Ban', 'Oakley', 'Gucci', 'Prada', 'Dior', 'Chanel', 'Versace', 'Tom Ford', 'Persol', 'Carrera'];
  final List<String> typesVerre = ['Simple', 'Progressif', 'Bifocal', 'Photochromique', 'Antireflet', 'Polarisé', 'Anti-lumière bleue'];
// Initialiser les valeurs des dropdowns
String initialCategory = product.category;
String initialMarque = product.marque;
String? initialTypeVerre = product.typeVerre;
String initialOpticienId = product.boutiqueId;
  // Variable pour stocker la couleur sélectionnée avec une valeur par défaut
  Color selectedColor = Colors.black;
  // Variable d'état pour contrôler l'affichage des images
  bool hasNewImage = false;
  
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
                    decoration: const InputDecoration(labelText: 'Nom du produit'),
                    initialValue: product.name,
  validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nom';
                      }
                      return null;
                    },                    onSaved: (value) => product.name = value ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description '),
                    initialValue: product.description,
                  validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer une description';
                      }
                      return null;
                    },                    onSaved: (value) => product.description = value ?? '',
                  ),
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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
      String colorHex = pickedColor.red.toRadixString(16).padLeft(2, '0') +
                        pickedColor.green.toRadixString(16).padLeft(2, '0') +
                        pickedColor.blue.toRadixString(16).padLeft(2, '0');
      
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
                    validator: (value) => value == null ? 'Ce champ est requis' : null,
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                    onSaved: (value) => product.prix = double.tryParse(value ?? '0') ?? 0,
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
                    onSaved: (value) => product.quantiteStock = int.tryParse(value ?? '0') ?? 0,
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
                        child: Text(opticien.nom ?? 'Sans nom'),
                      );
                    }).toList(),
                    validator: (value) => value?.isEmpty ?? true ? 'Veuillez sélectionner un opticien' : null,
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
                              child: Text('Mise à jour du produit "${product.name}"...'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                  
                  try {
                    // Uploader la nouvelle image si sélectionnée
                    if (hasNewImage && _tempSelectedImage != null && _tempSelectedImage!.bytes != null) {
                      final imageUrl = await productController.uploadImageWeb(
                        _tempSelectedImage!.bytes!,
                        _tempSelectedImage!.name ?? 'image.jpg',
                        product.id ?? '', // Utiliser l'ID existant du produit
                      );
                      product.image = imageUrl; // Mettre à jour l'URL de l'image
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
      }
    ),
  );
}

Widget _buildProductForm(GlobalKey<FormState> formKey, Product product,
    {required bool isEditing}) {
  return Form(
    key: formKey,
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dropdown pour sélectionner la boutique (opticien)
          DropdownButtonFormField<String>(
            value: product.boutiqueId.isEmpty ||
                    !productController.opticiens
                        .any((opticien) => opticien.id == product.boutiqueId)
                ? null
                : product.boutiqueId,
            decoration: const InputDecoration(labelText: 'Boutique'),
            items: productController.opticiens.map((opticien) {
              return DropdownMenuItem<String>(
                value: opticien.id,
                child: Text(opticien.nom),
              );
            }).toList(),
            validator: (value) => value?.isEmpty ?? true ? 'Champ requis' : null,
            onChanged: (value) {
              if (value != null) {
                product.boutiqueId = value;
              }
            },
          ),
          const SizedBox(height: 16),

          // Champ pour le nom du produit
          TextFormField(
            initialValue: product.name,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.name = value ?? '',
          ),
          const SizedBox(height: 16),

          // Champ pour le prix du produit
          TextFormField(
            initialValue: product.prix.toString(),
            decoration: const InputDecoration(labelText: 'Prix'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Champ requis';
              if (double.tryParse(value!) == null) return 'Prix invalide';
              return null;
            },
            onSaved: (value) => product.prix = double.tryParse(value!) ?? 0,
          ),
          const SizedBox(height: 16),

          // Champ pour la quantité en stock
          TextFormField(
            initialValue: product.quantiteStock.toString(),
            decoration: const InputDecoration(labelText: 'Quantité en stock'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Champ requis';
              if (int.tryParse(value!) == null) return 'Quantité invalide';
              return null;
            },
            onSaved: (value) =>
                product.quantiteStock = int.tryParse(value!) ?? 0,
          ),
          const SizedBox(height: 16),

          // Champ pour la catégorie du produit
          TextFormField(
            initialValue: product.category,
            decoration: const InputDecoration(labelText: 'Catégorie'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.category = value ?? '',
          ),
          const SizedBox(height: 16),

          // Champ pour la marque du produit
          TextFormField(
            initialValue: product.marque,
            decoration: const InputDecoration(labelText: 'Marque'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.marque = value ?? '',
          ),
          const SizedBox(height: 16),

          // Champ pour la couleur du produit
          TextFormField(
            initialValue: product.couleur,
            decoration: const InputDecoration(labelText: 'Couleur'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.couleur = value ?? '',
          ),
          const SizedBox(height: 16),

          // Champ pour la description du produit
          TextFormField(
            initialValue: product.description,
            decoration: const InputDecoration(labelText: 'Description'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.description = value ?? '',
          ),
          const SizedBox(height: 16),

          // Section pour l'image du produit
          Column(
            children: [
              const Text('Image du produit', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child:  Column(
                        children: [
                          FilePickerExample(
                            onImagePicked: (PlatformFile? file) {
                              setState(() {
                                _tempSelectedImage = file;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                        
                        ],
                      ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),

          // Champ pour le type de verre
          TextFormField(
            initialValue: product.typeVerre,
            decoration: const InputDecoration(labelText: 'Type de verre'),
            validator: (value) =>
                value?.isEmpty ?? true ? 'Champ requis' : null,
            onSaved: (value) => product.typeVerre = value ?? '',
          ),
          const SizedBox(height: 16),
        ],
      ),
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

Future<String> _uploadImageAndGetUrl(PlatformFile? imageFile, String productId) async {
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
    _showSnackBar('Erreur de téléchargement de l\'image: ${e.toString()}', isError: true);
    return '';
  }
}
}
