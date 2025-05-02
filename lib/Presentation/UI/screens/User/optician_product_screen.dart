import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/core/constants/champsProduits.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

// Palette de couleurs pour l'application


class OpticianProductsScreen extends StatefulWidget {
  final String opticianId;
  final ProductController productController = Get.find();

  OpticianProductsScreen({required this.opticianId});

  @override
  _OpticianProductsScreenState createState() => _OpticianProductsScreenState();
}

class _OpticianProductsScreenState extends State<OpticianProductsScreen> {
  final WishlistController wishlistController = Get.find();
  final AuthController authController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = RangeValues(0, 1000);
  String? _selectedCategory;
  String? _selectedTypeVerre;
  String? _selectedMarque;
  String? _selectedStyle;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.productController.loadProductsByOptician(widget.opticianId);
    });
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      widget.productController.loadProductsByOptician(widget.opticianId);
    }
  }

  List<Product> _getFilteredProducts() {
    return widget.productController.products.where((product) {
      // Search filter
      final searchMatch = _searchController.text.isEmpty ||
          product.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          product.marque
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

      // Category filter
      final categoryMatch = _selectedCategory == null ||
          _selectedCategory == 'All' ||
          product.category == _selectedCategory;

      // Type verre filter
      final typeVerreMatch = _selectedTypeVerre == null ||
          _selectedTypeVerre == 'All' ||
          product.typeVerre == _selectedTypeVerre;

      // Marque filter
      final marqueMatch = _selectedMarque == null ||
          _selectedMarque == 'All' ||
          product.marque == _selectedMarque;

      // Style filter
      final styleMatch = _selectedStyle == null ||
          _selectedStyle == 'All' ||
          product.style == _selectedStyle;

      // Price filter
      final priceMatch =
          product.prix >= _priceRange.start && product.prix <= _priceRange.end;

      return searchMatch &&
          categoryMatch &&
          typeVerreMatch &&
          marqueMatch &&
          styleMatch &&
          priceMatch;
    }).toList();
  }

  void _toggleWishlist(Product product) async {
    final userEmail = authController.currentUser?.email;
    if (userEmail == null) {
      Get.snackbar(
        'Erreur', 
        'Veuillez vous connecter d\'abord',
        backgroundColor: AppColors.paleBlue.withOpacity(0.9),
        colorText: AppColors.textColor,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
      return;
    }

    try {
      final isInWishlist = wishlistController.isProductInWishlist(product.id!);

      if (isInWishlist) {
        await wishlistController.removeFromWishlist(product.id!);
      } else {
        final wishlistItem = WishlistItem(
          userId: userEmail,
          productId: product.id!,
        );
        await wishlistController.addToWishlist(wishlistItem);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Impossible de mettre à jour la liste de souhaits',
        backgroundColor: AppColors.paleBlue.withOpacity(0.9),
        colorText: AppColors.textColor,
        snackPosition: SnackPosition.BOTTOM,
        margin: EdgeInsets.all(16),
        borderRadius: 12,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Using white background as requested
      appBar: AppBar(
        title: Text(
          'Catalogue de produits',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: AppColors.whiteColor,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 233, 234, 239),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.whiteColor),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 221, 226, 239),
                AppColors.secondaryColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar with elevated design
          Container(
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou marque...',
                hintStyle: TextStyle(color: AppColors.greyTextColor),
                prefixIcon: Icon(Icons.search, color: AppColors.accentColor),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: AppColors.greyTextColor),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.whiteColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.paleBlue, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.paleBlue, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentColor, width: 2),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filters section with updated colors
          Container(
            color: AppColors.whiteColor,
            child: ExpansionTile(
              title: Text(
                'Filtres',
                style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              leading: Icon(Icons.filter_list, color: AppColors.secondaryColor),
              collapsedBackgroundColor: AppColors.whiteColor,
              backgroundColor: Colors.white, // Changed to white as requested
              iconColor: AppColors.accentColor,
              collapsedIconColor: AppColors.secondaryColor,
              childrenPadding: EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price Range Slider
                      Text(
                        'Plage de prix',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textColor,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${_priceRange.start.toInt()}TND',
                            style: TextStyle(color: AppColors.greyTextColor),
                          ),
                          Expanded(
                            child: RangeSlider(
                              values: _priceRange,
                              min: 0,
                              max: 1000,
                              divisions: 20,
                              activeColor: AppColors.accentColor,
                              inactiveColor: AppColors.paleBlue.withOpacity(0.5),
                              labels: RangeLabels(
                                '${_priceRange.start.toInt()}TND',
                                '${_priceRange.end.toInt()}TND',
                              ),
                              onChanged: (values) {
                                setState(() {
                                  _priceRange = values;
                                });
                              },
                            ),
                          ),
                          Text(
                            '${_priceRange.end.toInt()}TND',
                            style: TextStyle(color: AppColors.greyTextColor),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),

                      // Filter dropdowns with updated styling
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              'Categorie',
                              categories,
                              _selectedCategory,
                              (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              "Type de lentille",
                              typesVerre,
                              _selectedTypeVerre,
                              (value) {
                                setState(() {
                                  _selectedTypeVerre = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              "Marque",
                              marques,
                              _selectedMarque,
                              (value) {
                                setState(() {
                                  _selectedMarque = value;
                                });
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              "Style",
                              styles,
                              _selectedStyle,
                              (value) {
                                setState(() {
                                  _selectedStyle = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Redesigned reset filters button
                      Center(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedCategory = null;
                              _selectedTypeVerre = null;
                              _selectedMarque = null;
                              _selectedStyle = null;
                              _priceRange = RangeValues(0, 1000);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondaryColor,
                            foregroundColor: AppColors.whiteColor,
                            minimumSize: Size(180, 44),
                            elevation: 3,
                            shadowColor: AppColors.secondaryColor.withOpacity(0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh, size: 18),
                              SizedBox(width: 8),
                              Text(
                                "Réinitialiser les filtres",
                                style: GoogleFonts.montserrat(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: Obx(() {
              if (widget.productController.isLoading &&
                  widget.productController.products.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                  )
                );
              } else if (widget.productController.products.isEmpty) {
                return _buildEmptyState(
                  Icons.inventory_2_outlined,
                  "Aucun produit disponible",
                );
              } else {
                final filteredProducts = _getFilteredProducts();
                if (filteredProducts.isEmpty) {
                  return _buildEmptyState(
                    Icons.filter_list_off,
                    "Aucun produit ne correspond à vos filtres",
                  );
                }

                return Container(
                  color: Colors.white, // Changed to white as requested
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.65,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredProducts.length +
                        (widget.productController.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= filteredProducts.length) {
                        return Center(child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentColor),
                        ));
                      }

                      final product = filteredProducts[index];
                      return _buildProductCard(context, product);
                    },
                  ),
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String message) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Changed to white
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.paleBlue.withOpacity(0.3)), // Added subtle border
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: AppColors.greyTextColor),
            SizedBox(height: 16),
            Text(
              message,
              style: GoogleFonts.montserrat(
                fontSize: 16,
                color: AppColors.textColor,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String title, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textColor,
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.paleBlue.withOpacity(0.5)),
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            value: selectedValue,
            isExpanded: true,
            icon: Icon(Icons.arrow_drop_down, color: AppColors.accentColor),
            dropdownColor: AppColors.whiteColor,
            hint: Text(
              'Selectionner ${title.toLowerCase()}',
              style: TextStyle(color: AppColors.greyTextColor),
            ),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(color: AppColors.textColor),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Normaliser l'URL du modèle 3D
    String normalizedModelUrl =
        product.model3D.isNotEmpty ? _normalizeModelUrl(product.model3D) : '';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      shadowColor: AppColors.paleBlue.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.to(() => ProductDetailsScreen(product: product));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image ou viewer 3D avec cadre stylisé
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.paleBlue.withOpacity(0.2),
                      Colors.white, // Changed to white
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: product.model3D.isNotEmpty
                          ? FutureBuilder<bool>(
                              future: _checkModelAvailability(normalizedModelUrl),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.accentColor),
                                    ),
                                  );
                                }

                                if (snapshot.hasData && snapshot.data == true) {
                                  return Flutter3DViewer(src: product.model3D);
                                } else {
                                  // Fallback à l'image avec gestion d'erreur améliorée
                                  return product.image.isNotEmpty
                                      ? Image.network(
                                          product.image,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            return Center(
                                              child: Icon(
                                                Icons.broken_image,
                                                size: 50,
                                                color: AppColors.greyTextColor,
                                              ),
                                            );
                                          },
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                    AppColors.accentColor),
                                                value: loadingProgress.expectedTotalBytes != null
                                                    ? loadingProgress.cumulativeBytesLoaded /
                                                        loadingProgress.expectedTotalBytes!
                                                    : null,
                                              ),
                                            );
                                          },
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.image,
                                            size: 50,
                                            color: AppColors.paleBlue,
                                          ),
                                        );
                                }
                              },
                            )
                          : product.image.isNotEmpty
                              ? Image.network(
                                  product.image,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: AppColors.greyTextColor,
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: AppColors.paleBlue,
                                  ),
                                ),
                    ),
                    // Badge 3D si applicable
                    if (product.model3D.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '3D',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    // Bouton Wishlist amélioré
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Obx(() {
                          final isInWishlist =
                              wishlistController.isProductInWishlist(product.id!);
                          return IconButton(
                            icon: Icon(
                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : AppColors.greyTextColor,
                              size: 22,
                            ),
                            onPressed: () => _toggleWishlist(product),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info produit avec design amélioré
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 14,
                        color: AppColors.greyTextColor,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product.marque,
                          style: TextStyle(
                            color: AppColors.greyTextColor,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softBlue.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${product.prix.toStringAsFixed(2)} TND',
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryColor,
                        fontSize: 14,
                      ),
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
}