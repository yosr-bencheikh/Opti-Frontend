import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

class EnhancedProductCard extends StatelessWidget {
  final Product product;
  
  const EnhancedProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final WishlistController wishlistController = Get.find();
    final AuthController authController = Get.find();
    final String normalizedModelUrl = product.model3D.isNotEmpty 
        ? GlassesManagerService.ensureAbsoluteUrl(product.model3D) 
        : '';

    return Obx(() {
      final isInWishlist = wishlistController.isProductInWishlist(product.id!);
      final Color cardBackgroundColor = const Color(0xFFF5F3FA);

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              offset: const Offset(0, 4),
              blurRadius: 12,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Container(
                color: cardBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Stack(
                        children: [
                          Container(
                            color: Colors.grey[50],
                            child: product.model3D.isNotEmpty
                                ? FutureBuilder<bool>(
                                    future: _checkModelAvailability(normalizedModelUrl),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.deepPurple[400],
                                            strokeWidth: 2,
                                          ),
                                        );
                                      }
                                      if (snapshot.hasData && snapshot.data == true) {
                                        return Flutter3DViewer(src: product.model3D);
                                      } else {
                                        return _buildImageFallback();
                                      }
                                    },
                                  )
                                : _buildImageFallback(),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple[700],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${product.prix.toStringAsFixed(2)} TND',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                product.marque,
                                style: TextStyle(
                                  color: Colors.deepPurple[800],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 3),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const NeverScrollableScrollPhysics(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < min(product.couleur.length, 3); i++)
                                    Container(
                                      margin: const EdgeInsets.only(right: 3),
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: parseHexColor(product.couleur[i]),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 1,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (product.couleur.length > 3)
                                    Container(
                                      margin: const EdgeInsets.only(left: 2),
                                      child: Text(
                                        '+${product.couleur.length - 3}',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.deepPurple[400],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              product.name,
                              style: GoogleFonts.montserrat(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.deepPurple[900],
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            if (product.style.isNotEmpty)
                              SizedBox(
                                height: 13,
                                child: Text(
                                  product.style,
                                  style: TextStyle(
                                    color: Colors.deepPurple[400],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            const Flexible(child: SizedBox(height: 5)),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple[600],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.deepPurple.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 15,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Get.to(() => ProductDetailsScreen(product: product)),
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    'More Details',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
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
              if (product.category.isNotEmpty)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: product.category.toLowerCase().contains('soleil')
                          ? Colors.amber[600]
                          : Colors.blue[600],
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      product.category.toLowerCase().contains('soleil')
                          ? 'Soleil'
                          : 'Vue',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Get.to(() => ProductDetailsScreen(product: product)),
                    splashColor: Colors.deepPurple.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _toggleWishlist,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isInWishlist ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey<bool>(isInWishlist),
                            color: isInWishlist ? Colors.red[400] : Colors.grey[400],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildImageFallback() {
    return product.image.isNotEmpty
        ? Hero(
            tag: 'product-${product.id}',
            child: Image.network(
              product.image,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                    color: Colors.deepPurple[400],
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 40,
                  color: Colors.grey[400],
                ),
              ),
            ),
          )
        : Center(
            child: Icon(
              Icons.image_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          );
  }

  Future<bool> _checkModelAvailability(String url) async {
    if (url.isEmpty) return false;
    try {
      final response = await http.head(Uri.parse(url));
      return response.statusCode == 200;
    } catch (e) {
      print('3D model check error: $e');
      return false;
    }
  }

  void _toggleWishlist() async {
    final userEmail = Get.find<AuthController>().currentUser?.email;
    if (userEmail == null) {
      Get.snackbar('Error', 'Please login first');
      return;
    }

    try {
      final wishlistController = Get.find<WishlistController>();
      if (wishlistController.isProductInWishlist(product.id!)) {
        await wishlistController.removeFromWishlist(product.id!);
      } else {
        final wishlistItem = WishlistItem(
          userId: userEmail,
          productId: product.id!,
        );
        await wishlistController.addToWishlist(wishlistItem);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update wishlist');
    }
  }

  Color parseHexColor(String hexColor) {
    try {
      hexColor = hexColor.trim().replaceFirst('#', '');
      if (hexColor.length == 3) {
        hexColor = hexColor.split('').map((e) => '$e$e').join('');
      }
      if (hexColor.length == 6) hexColor = 'FF$hexColor';
      return Color(int.parse('0x$hexColor'));
    } catch (e) {
      return Colors.grey;
    }
  }
}

class ColorUtils {
  static Map<String, int> hexToRgb(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 3) {
      hexColor = hexColor.split('').map((c) => c + c).join('');
    }
    return {
      'r': int.parse(hexColor.substring(0, 2), radix: 16),
      'g': int.parse(hexColor.substring(2, 4), radix: 16),
      'b': int.parse(hexColor.substring(4, 6), radix: 16),
    };
  }

  static bool isColorful(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final maxVal = [rgb['r']!, rgb['g']!, rgb['b']!].reduce(max);
      final minVal = [rgb['r']!, rgb['g']!, rgb['b']!].reduce(min);
      final saturation = maxVal - minVal;
      return saturation > 50 && maxVal > 50 && (maxVal - minVal) / maxVal > 0.25;
    } catch (_) {
      return false;
    }
  }

  static bool isNeutral(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final avg = (rgb['r']! + rgb['g']! + rgb['b']!) / 3;
      final diff = (rgb['r']! - avg).abs() + (rgb['g']! - avg).abs() + (rgb['b']! - avg).abs();
      return diff < 50;
    } catch (_) {
      return false;
    }
  }

  static bool isSilver(String hexColor) {
    try {
      final rgb = hexToRgb(hexColor);
      final avg = (rgb['r']! + rgb['g']! + rgb['b']!) / 3;
      return avg > 150 && 
          (rgb['r']! - avg).abs() < 30 &&
          (rgb['g']! - avg).abs() < 30 &&
          (rgb['b']! - avg).abs() < 30;
    } catch (_) {
      return false;
    }
  }
}