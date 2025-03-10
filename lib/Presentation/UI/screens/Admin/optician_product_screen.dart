import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:google_fonts/google_fonts.dart';

class OpticianProductsScreen extends StatefulWidget {
  final String opticianId;
  final ProductController productController = Get.find();

  OpticianProductsScreen({required this.opticianId});

  @override
  _OpticianProductsScreenState createState() => _OpticianProductsScreenState();
}

class _OpticianProductsScreenState extends State<OpticianProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues _priceRange = RangeValues(0, 1000);
  String? _selectedCategory;
  String? _selectedTypeVerre;
  String? _selectedMarque;

  final List<String> categories = ['All', 'Sunglasses', 'Lenses', 'Frames'];
  final List<String> typeVerres = [
    'All',
    'Single Vision',
    'Bifocal',
    'Progressive'
  ];
  final List<String> marques = [
    'All',
    'Ray-Ban',
    'Oakley',
    'Gucci',
    'Prada',
    'Versace'
  ];

  @override
  void initState() {
    super.initState();
    // Load products for this optician
    //widget.productController.fetchProductsByOptician(widget.opticianId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<dynamic> _getFilteredProducts() {
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

      // Price filter
      final priceMatch =
          product.prix >= _priceRange.start && product.prix <= _priceRange.end;

      return searchMatch &&
          categoryMatch &&
          typeVerreMatch &&
          marqueMatch &&
          priceMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Catalogue de produits',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou marque...',
                prefixIcon: Icon(Icons.search, color: Colors.blue.shade700),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade700, width: 1),
                ),
              ),
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Filters section
          ExpansionTile(
            title: Text(
              'Filtres',
              style: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            leading: Icon(Icons.filter_list, color: Colors.blue.shade700),
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
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Text('${_priceRange.start.toInt()}TND'),
                        Expanded(
                          child: RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000,
                            divisions: 20,
                            activeColor: Colors.blue.shade700,
                            inactiveColor: Colors.blue.shade100,
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
                        Text('${_priceRange.end.toInt()}TND'),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Filter dropdowns
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
                            typeVerres,
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
                    _buildDropdown(
                      "Marque",
                      marques,
                      _selectedMarque,
                      (value) {
                        setState(() {
                          _selectedMarque = value;
                        });
                      },
                    ),
                    SizedBox(height: 16),

                    // Reset filters button
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _selectedCategory = null;
                            _selectedTypeVerre = null;
                            _selectedMarque = null;
                            _priceRange = RangeValues(0, 1000);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          minimumSize: Size(120, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text("Réinitialiser les filtres"),
                      ),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),

          // Products List
          Expanded(
            child: Obx(() {
              if (widget.productController.isLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (widget.productController.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        "Aucun produit disponible",
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                final filteredProducts = _getFilteredProducts();
                if (filteredProducts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_list_off,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "Aucun produit ne correspond à vos filtres",
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _buildProductCard(product);
                  },
                );
              }
            }),
          ),
        ],
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
          ),
        ),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
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
            hint: Text('Selectionner ${title.toLowerCase()}'),
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to product details
          Get.to(() => ProductDetailsScreen(product: product));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                width: double.infinity,
                child: product.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.inventory_2_outlined,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
              ),
            ),

            // Product Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.marque,
                          style: GoogleFonts.montserrat(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          product.name,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    // Fix for overflow - Wrap Row in Flexible widget
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Price with overflow protection
                          Flexible(
                            child: Text(
                              '${product.prix.toStringAsFixed(2)}TND',
                              style: GoogleFonts.montserrat(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Small gap to ensure separation
                          SizedBox(width: 4),
                          // Category tag with fixed width
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category,
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
