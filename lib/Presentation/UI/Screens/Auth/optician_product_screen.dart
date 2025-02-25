import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:google_fonts/google_fonts.dart';

class OpticianProductsScreen extends StatefulWidget {
  final String opticianId;

  OpticianProductsScreen({required this.opticianId});

  @override
  _OpticianProductsScreenState createState() => _OpticianProductsScreenState();
}

class _OpticianProductsScreenState extends State<OpticianProductsScreen> {
  final ProductController productController = Get.find();

@override
void initState() {
  super.initState();
  // Use a post-frame callback to ensure the widget is fully built before updating state
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Load products for THIS optician (not all products)
    productController.loadProductsByOptician(widget.opticianId);
  });
}
  
  @override
  Widget build(BuildContext context) {
    // Load products for the selected optician
    // productController.loadProductsByOptician(opticianId);

    return Scaffold(
    appBar: AppBar(
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Color(0xFF2A2A2A)),
    onPressed: () {
      // Reset product list to show all products
      Get.find<ProductController>().showAllProducts();
      Get.back();
    },
  ),
  title: Text(
    'Eyewear Collection',
    style: GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF2A2A2A),
    ),
  ),
  backgroundColor: Colors.white,
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.search, color: Color(0xFF2A2A2A)),
      onPressed: () {
        // Implement search functionality
      },
    ),
    IconButton(
      icon: const Icon(Icons.filter_list, color: Color(0xFF2A2A2A)),
      onPressed: () {
        // Implement filter functionality
      },
    ),
  ],
),
      body: Column(
        children: [
          _buildCategorySelector(),
          _buildFeaturedBanner(),
          Expanded(child: _buildProductList()),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'name': 'Prescription', 'icon': Icons.visibility},
      {'name': 'Sunglasses', 'icon': Icons.wb_sunny},
      {'name': 'On Sale', 'icon': Icons.local_offer},
    ];

    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              onTap: () {
                // Handle category selection
              },
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    color: const Color(0xFF4A80F0),
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF2A2A2A),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedBanner() {
    return Container(
        height: 120,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4A80F0), Color(0xFF8A63E8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/glasses_banner.avif', // Add this image to your assets
              fit: BoxFit.cover,
              width: double.infinity, // Ensure the image takes full width
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'NEW COLLECTION',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(width: 20),
                  Container(
                    // Wrap the text in a Container for alignment
                    alignment: Alignment.centerRight, // Align text to the left
                    child: Text(
                      'Up to 30% Off',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ));
  }

Widget _buildProductList() {
  return Obx(() {
    // Check loading state first
    if (productController.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    final products = productController.products;
    
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

      return GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
            onTap: () {
              // Navigate to product details
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      image: DecorationImage(
                        image: NetworkImage(product.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF2A2A2A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${product.prix.toStringAsFixed(2)} €',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: const Color(0xFF4A80F0),
                              ),
                            ),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4A80F0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }
}