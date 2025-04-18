import 'dart:convert';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/FilePickerExample.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Model3DPickerWidget.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Multipickercolor.dart';
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

    // Ajout du filtre par marque
    if (_selectedMarque != null && _selectedMarque!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.marque == _selectedMarque)
          .toList();
    }

    // Ajout du filtre par style
    if (_selectedStyle != null && _selectedStyle!.isNotEmpty) {
      filteredList = filteredList
          .where((product) => product.style == _selectedStyle)
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
    // Cette fonction est appelée depuis le bouton "Appliquer les filtres"
    setState(() {
      _currentPage = 0; // Retour à la première page
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
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: Builder(
          builder: (BuildContext context) {
            if (productController.isLoading) {
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
                      'Chargement des produits...',
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

            if (productController.error != null) {
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
                      productController.error!,
                      style: TextStyle(
                        fontSize: 16,
                        color: _textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }

            return SafeArea(
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
                'Gestion des Produits',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _textPrimaryColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${_filteredProducts.length} produits',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Nouveau produit'),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
            Icon(Icons.search_off,
                size: 64, color: textSecondaryColor.withOpacity(0.6)),
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
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: _buildProductsTable(),
        ),
      ],
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
                    hintText: 'Rechercher un produits par nom, catégorie...',
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
                label: Text(_showFilters ? 'Masquer filtres' : 'Filtrer'),
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
          if (_filteredProducts.isNotEmpty)
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
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_alt, color: _primaryColor),
              const SizedBox(width: 8),
              Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 24),

          // Première rangée de filtres
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Opticien',
                  hint: 'Tous les opticiens',
                  icon: Icons.store_outlined,
                  value: _selectedOpticien,
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Tous les opticiens'),
                    ),
                    ...productController.opticiens.map((opticien) {
                      return DropdownMenuItem<String>(
                        value: opticien.id,
                        child: Text(opticien.nom),
                      );
                    }).toList(),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedOpticien = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
          const SizedBox(height: 24),

          // Deuxième rangée de filtres
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix minimum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: TextEditingController(
                            text: _minPrice?.toString() ?? ''),
                        onChanged: (value) {
                          setState(() {
                            _minPrice = value.isNotEmpty
                                ? double.tryParse(value)
                                : null;
                          });
                        },
                        style: TextStyle(color: textPrimaryColor),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Prix min',
                          hintStyle: TextStyle(color: textSecondaryColor),
                          prefixIcon:
                              Icon(Icons.euro, color: primaryColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prix maximum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: TextEditingController(
                            text: _maxPrice?.toString() ?? ''),
                        onChanged: (value) {
                          setState(() {
                            _maxPrice = value.isNotEmpty
                                ? double.tryParse(value)
                                : null;
                          });
                        },
                        style: TextStyle(color: textPrimaryColor),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Prix max',
                          hintStyle: TextStyle(color: textSecondaryColor),
                          prefixIcon:
                              Icon(Icons.euro, color: primaryColor, size: 20),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Actions
        ],
      ),
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
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(hint, style: TextStyle(color: textSecondaryColor)),
              icon: const Icon(Icons.keyboard_arrow_down),
              isExpanded: true,
              style: TextStyle(color: textPrimaryColor, fontSize: 15),
              dropdownColor: Colors.white,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical, // Défilement vertical
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal, // Défilement horizontal
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(backgroundColor),
          dataRowMaxHeight: 100,
          dataRowMinHeight: 80,
          headingRowHeight: 56,
          horizontalMargin: 24,
          dividerThickness: 0.5,
          showCheckboxColumn: false,
          columns: [
            DataColumn(label: _buildColumnHeader('Image')),
            DataColumn(label: _buildColumnHeader('Modèle 3D')),
            DataColumn(label: _buildColumnHeader('Boutique')),
            DataColumn(label: _buildColumnHeader('Nom')),
            DataColumn(label: _buildColumnHeader('Catégorie')),
            DataColumn(label: _buildColumnHeader('Description')),
            DataColumn(label: _buildColumnHeader('Marque')),
            DataColumn(label: _buildColumnHeader('Couleur')),
            DataColumn(label: _buildColumnHeader('Style')),
            DataColumn(label: _buildColumnHeader('Type de verre')),
            DataColumn(label: _buildColumnHeader('Materiel')),
            DataColumn(label: _buildColumnHeader('Genre')),
            DataColumn(label: _buildColumnHeader('Prix')),
            DataColumn(label: _buildColumnHeader('Stock')),
            DataColumn(label: _buildColumnHeader('Actions')),
          ],
          rows: _paginatedProducts.map((product) {
            return DataRow(
              cells: [
                // Cellule pour l'image
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

                // Cellule pour le modèle 3D
                // Modification du GestureDetector dans DataCell pour le modèle 3D
                DataCell(
                  GestureDetector(
                    onTap: () async {
                      if (product.model3D != null &&
                          product.model3D.isNotEmpty) {
                        try {
                          String modelUrl;

                          // Vérifier si model3D est un ID MongoDB (24 caractères hexadécimaux)
                          bool isMongoId = RegExp(r'^[0-9a-fA-F]{24}$')
                              .hasMatch(product.model3D);

                          if (isMongoId) {
                            // Si c'est un ID MongoDB, récupérer les détails du modèle via l'API
                            final response = await http.get(
                              Uri.parse(
                                  'http://localhost:3000/products/model3d-url/${product.model3D}'),
                              headers: {'Content-Type': 'application/json'},
                            );

                            if (response.statusCode == 200) {
                              final data = jsonDecode(response.body);
                              modelUrl =
                                  'http://localhost:3000${data['filePath']}';
                            } else {
                              throw Exception(
                                  'Erreur lors de la récupération du modèle: ${response.statusCode}');
                            }
                          } else {
                            // Si c'est déjà une URL ou un chemin, l'utiliser directement
                            modelUrl = product.model3D.startsWith('http')
                                ? product.model3D
                                : 'http://localhost:3000${product.model3D}';
                          }

                          print('URL du modèle 3D: $modelUrl');

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('Modèle 3D - ${product.name}'),
                              content: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.8,
                                height:
                                    MediaQuery.of(context).size.height * 0.6,
                                child: ModelViewer(
                                  src: modelUrl,
                                  alt: 'Modèle 3D de ${product.name}',
                                  ar: false,
                                  autoRotate: true,
                                  cameraControls: true,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Fermer'),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Erreur lors du chargement du modèle 3D: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          print('Erreur lors du chargement du modèle 3D: $e');
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Aucun modèle 3D disponible pour ce produit'),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                        color: Colors.grey.shade50,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child:
                          product.model3D != null && product.model3D.isNotEmpty
                              ? Icon(
                                  Icons.view_in_ar,
                                  color: Colors.blue,
                                  size: 30,
                                )
                              : Icon(
                                  Icons.view_in_ar_outlined,
                                  color: Colors.grey.shade400,
                                ),
                    ),
                  ),
                ),

                // Cellule pour la boutique
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      productController.getOpticienNom(product.boutiqueId) ??
                          'N/A',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Cellule pour le nom du produit
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

                // Cellule pour la catégorie
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
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

                // Cellule pour la description
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

                // Cellule pour la marque
                DataCell(Text(product.marque)),

                // Cellule pour la couleur
                DataCell(
                  Row(
                    children: [
                      for (var color in product.couleur) ...[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: getColorFromHex(color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ]..removeLast(), // Remove the last SizedBox to avoid extra spacing
                  ),
                ),

                // Cellule pour le style
                DataCell(
                  Text(
                    product.style ?? 'N/A',
                    style: TextStyle(
                      color: product.style?.isNotEmpty == true
                          ? textPrimaryColor
                          : Colors.grey.shade400,
                      fontStyle: product.style?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),

                // Cellule pour le type de verre
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
                    product.materiel ?? 'N/A',
                    style: TextStyle(
                      color: product.materiel?.isNotEmpty == true
                          ? textPrimaryColor
                          : Colors.grey.shade400,
                      fontStyle: product.materiel?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    product.sexe ?? 'N/A',
                    style: TextStyle(
                      color: product.sexe?.isNotEmpty == true
                          ? textPrimaryColor
                          : Colors.grey.shade400,
                      fontStyle: product.sexe?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),

                // Cellule pour le prix
                DataCell(
                  Text(
                    '${product.prix.toStringAsFixed(2)} DT',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accentColor,
                    ),
                  ),
                ),

                // Cellule pour le stock
                DataCell(
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: product.quantiteStock > 10
                          ? Colors.green.shade50
                          : product.quantiteStock > 0
                              ? Colors.orange.shade50
                              : Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.quantiteStock > 0
                          ? product.quantiteStock.toString()
                          : 'Rupture de stock',
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

                // Cellule pour les actions
                DataCell(_buildActionButtons(product)),
              ],
            );
          }).toList(),
        ),
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
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor; // Add alpha if not present
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  void _showAddProductDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    PlatformFile? _tempSelectedFile;
    bool isModel3D = false;

    // Create a product object with empty fields, now with a List for colors
    Product product = Product(
      name: '',
      description: '',
      category: '',
      marque: '',
      couleur: ['000000'], // Start with black as default in a list
      prix: 0,
      quantiteStock: 0,
      image: '',
      model3D: '',
      typeVerre: '',
      averageRating: 0.0,
      totalReviews: 0,
      style: '', materiel: '', sexe: '',
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
                    // File type selection (image or 3D model)
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

                    // Container for file picker
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
                              onImagePicked: (image) {
                                setState(() {
                                  _tempSelectedFile = image;
                                });
                              },
                            ),
                    ),

                    // Preview of selected file
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

                    // Product name
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

                    // Category
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

                    // Brand
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

                    // UPDATED: Multiple color selection
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

                    // Glass type
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

                    // Price with validation
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

                    // Stock quantity with validation
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

                    // Store selection dropdown
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

                    // Display loading indicator
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
                          // Upload 3D model
                          final modelUrl =
                              await GlassesManagerService.uploadModel3D(
                            _tempSelectedFile!.bytes!,
                            _tempSelectedFile!.name,
                            product.id ?? '',
                          );
                          product.model3D = modelUrl;
                        } else {
                          // Upload image
                          final imageUrl =
                              await productController.uploadImageWeb(
                            _tempSelectedFile!.bytes!,
                            _tempSelectedFile!.name,
                            product.id ?? '',
                          );
                          product.image = imageUrl;
                        }
                      } else if (_tempSelectedFile == null) {
                        // Show error if no file is selected
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Veuillez sélectionner une image ou un modèle 3D'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      // Create the product
                      final success =
                          await productController.addProduct(product);

                      // Close loading dialog
                      Navigator.of(context).pop();

                      if (success) {
                        // Close form dialog
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
                      // Close loading dialog
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

                  // UPDATED: Multiple color selection
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
                                    title:
                                        const Text('Sélectionnez une couleur'),
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
