import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool isHorizontalList;
  final WishlistController? wishlistController;
  final AuthController? authController;

  const ProductCard({
    Key? key,
    required this.product,
    this.isHorizontalList = false,
    this.wishlistController,
    this.authController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductController productController = Get.find<ProductController>();

    return GestureDetector(
      onTap: () async {
        final result =
            await Get.to(() => ProductDetailsScreen(product: product));
        if (result == true && product.id != null) {
          // Refresh the product with latest ratings
          await productController.fetchProductRatingAndReviews(product.id!);

          // Force UI update if needed
          productController.update();
        }
      },
      child: Obx(() {
        final currentProduct =
            productController.getProductById(product.id!) ?? product;

        return Container(
          width: isHorizontalList ? 160 : null,
          margin: isHorizontalList ? const EdgeInsets.only(right: 16) : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: FlexFit.tight,
                child: Container(
                  height: 98,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: Colors.grey[200],
                  ),
                  child: _buildProductImage(currentProduct),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandName(currentProduct),
                    _buildProductName(currentProduct),
                    _buildPriceAndDiscount(currentProduct),
                    if (isHorizontalList) _buildRatingSection(currentProduct),
                    if (!isHorizontalList) _buildCategoryTag(currentProduct),
                    if (wishlistController != null)
                      _buildActionButtons(currentProduct),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProductImage(dynamic product) {
    return product.image != null && product.image.isNotEmpty
        ? ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
        : const Center(child: Icon(Icons.shopping_bag, size: 40));
  }

  Widget _buildBrandName(dynamic product) {
    return product.marque != null && product.marque.isNotEmpty
        ? Text(
            product.marque,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : const SizedBox.shrink();
  }

  Widget _buildProductName(dynamic product) {
    return Text(
      product.name,
      style: const TextStyle(fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPriceAndDiscount(dynamic product) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${product.prix.toStringAsFixed(2)}${isHorizontalList ? '\$' : 'TND'}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.pink.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '-5%',
            style: TextStyle(
              color: Colors.pink[700],
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSection(dynamic product) {
    // Extract rating values with null safety
    final double rating = product.averageRating != null
        ? (product.averageRating is double)
            ? product.averageRating
            : double.tryParse(product.averageRating.toString()) ?? 0.0
        : 0.0;

    final int reviews = product.totalReviews != null
        ? (product.totalReviews is int)
            ? product.totalReviews
            : int.tryParse(product.totalReviews.toString()) ?? 0
        : 0;

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 16),
        Text(
          ' ${rating.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        Text(
          ' ($reviews)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTag(dynamic product) {
    return product.category != null && product.category.isNotEmpty
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              product.category,
              style: TextStyle(
                fontSize: 9,
                color: Colors.blue.shade700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          )
        : const SizedBox.shrink();
  }

  Widget _buildActionButtons(dynamic product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStockStatusOrCartButton(product),
        _buildWishlistButton(product),
      ],
    );
  }

  Widget _buildStockStatusOrCartButton(dynamic product) {
    final isOutOfStock = product.quantiteStock != null &&
        (product.quantiteStock is int || product.quantiteStock is double) &&
        product.quantiteStock <= 0;

    return isOutOfStock
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Text(
              'Rupture de stock',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          )
        : IconButton(
            icon:
                const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
            onPressed: () => _handleCartPress(product),
          );
  }

  void _handleCartPress(dynamic product) {
    if (product.id == null || product.id!.isEmpty) {
      Get.snackbar('Erreur', 'Données produit invalides');
      return;
    }
    // showProductDialog(context, product);
  }

  Widget _buildWishlistButton(dynamic product) {
    return Obx(() {
      final isInWishlist = wishlistController!.isProductInWishlist(product.id!);
      return IconButton(
        icon: Icon(
          isInWishlist ? Icons.favorite : Icons.favorite_border,
          color: isInWishlist ? Colors.red : Colors.black87,
        ),
        onPressed: () => _handleWishlistPress(product, isInWishlist),
      );
    });
  }

  void _handleWishlistPress(dynamic product, bool isInWishlist) async {
    final userEmail = authController?.currentUser?.email;
    if (userEmail == null) {
      Get.snackbar('Erreur', 'Veuillez vous connecter d\'abord');
      return;
    }

    try {
      if (isInWishlist) {
        await wishlistController!.removeFromWishlist(product.id!);
      } else {
        final wishlistItem = WishlistItem(
          userId: userEmail,
          productId: product.id!,
        );
        await wishlistController!.addToWishlist(wishlistItem);
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Échec de la mise à jour de la liste de souhaits: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }
}
