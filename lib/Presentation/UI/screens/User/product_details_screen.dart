import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/Presentation/UI/screens/User/Face_detection.dart';

import 'package:opti_app/domain/entities/wishlist_item.dart';

class ProductDetailsScreen extends GetView<ProductController> {
  final Product product;
  ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: product.id!,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40),
                        bottomRight: Radius.circular(40),
                      ),
                      child: product.model3D.isNotEmpty
                          ? Flutter3DViewer(src: product.model3D)
                          : Image.network(
                              product.image,
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- New Product Summary Banner ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 8)
                          ],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Name
                            Text(
                              product.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16), // Add some space
                            // Row with Price, Stock, Delivery, Rating
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Price and Discount
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${product.prix.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(height: 4),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange[100],
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Extra ${5}% off',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.orange[800]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                // Stock, Delivery, Rating
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.green, size: 20),
                                          SizedBox(width: 8),
                                          Text('In stock',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.local_shipping, size: 20),
                                          SizedBox(width: 8),
                                          Text('Delivery: Tomorrow',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w500)),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.star,
                                              color: Colors.amber, size: 20),
                                          SizedBox(width: 4),
                                          Text(
                                              '${product.averageRating.toStringAsFixed(1)}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600)),
                                          SizedBox(width: 4),
                                          Text('(${product.totalReviews})'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      SizedBox(height: 8),
                      // Description Card
                      // --- Row containing Description and Spec ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description Card
                          Expanded(
                            flex: 2, // Less width
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 8)
                                ],
                              ),
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.only(
                                  right: 8), // Add spacing between cards
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    product.description,
                                    style: TextStyle(fontSize: 16, height: 1.4),
                                    maxLines: 10,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Spec Card
                          Expanded(
                            flex: 3, // More width
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 8)
                                ],
                              ),
                              padding: EdgeInsets.all(16),
                              margin: EdgeInsets.only(
                                  left: 8), // Add spacing between cards
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Specifications',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  // Example specs
                                  Row(
                                    children: [
                                      Icon(Icons.memory,
                                          size: 20, color: Colors.blueGrey),
                                      SizedBox(width: 8),
                                      Text('RAM: 16GB'),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.storage,
                                          size: 20, color: Colors.blueGrey),
                                      SizedBox(width: 8),
                                      Text('Storage: 512GB SSD'),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.battery_charging_full,
                                          size: 20, color: Colors.blueGrey),
                                      SizedBox(width: 8),
                                      Text('Battery: 10 hours'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomBar(product: product),
          ),
        ],
      ),
    );
  }

  Widget _specRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        Text(value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Product product;
  _BottomBar({required this.product});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find();
    final WishlistController wishlistController = Get.find();
    RxBool inWishlist = false.obs;

    // Initialize
    ever(inWishlist, (_) {});

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Obx(() {
            return IconButton(
              icon: Icon(
                inWishlist.value ? Icons.favorite : Icons.favorite_border,
                size: 28,
                color: inWishlist.value ? Colors.red : Colors.grey,
              ),
              onPressed: () async {
                // Toggle wishlist
                inWishlist.value = !inWishlist.value;
                if (inWishlist.value) {
                  await wishlistController.addToWishlist(WishlistItem(
                      userId: authController.currentUser!.email!,
                      productId: product.id!));
                } else {
                  await wishlistController.removeFromWishlist(product.id!);
                }
              },
            );
          }),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: product.quantiteStock > 0
                  ? () {
                      _launchAR(context);
                    }
                  : null,
              child: Text(
                product.quantiteStock > 0 ? 'Essayez en AR' : 'Rupture',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _launchAR(BuildContext context) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => FaceDetectionScreen()));
  }
}
