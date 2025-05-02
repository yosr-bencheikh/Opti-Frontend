import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/home_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';

class ProductCard extends StatelessWidget {
  final dynamic product;
  final bool isHorizontalList;
  final WishlistController? wishlistController;
  final AuthController? authController;
  final Widget? customImageWidget;

  const ProductCard({
    Key? key,
    required this.product,
    this.isHorizontalList = false,
    this.wishlistController,
    this.authController,
    this.customImageWidget, 
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.to(() => ProductDetailsScreen(product: product));
      },
      child: Container(
        width: isHorizontalList ? 160 : null,
        margin: isHorizontalList ? const EdgeInsets.only(right: 16) : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.greyTextColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Remplacez la partie Product Image par ceci:
Flexible(
  fit: FlexFit.tight,
  child: Container(
    height: isHorizontalList ? 120 : 98, // Ajustement de la hauteur
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(12),
      ),
      color: Colors.grey[200],
    ),
    child: customImageWidget ?? (product.image != null && product.image.isNotEmpty
        ? ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
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
        : const Center(child: Icon(Icons.shopping_bag, size: 40))),
),),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand (if available)
                  if (product.marque != null && product.marque.isNotEmpty)
                    Text(
                      product.marque,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryColor, 
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                  // Product Name
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Price and Discount
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${product.prix.toStringAsFixed(2)}${isHorizontalList ? '\$' : 'TND'}',
                          style: const TextStyle(
                            color: AppColors.accentColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
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
                  ),

                  // Ratings (if in horizontal list)
                  if (isHorizontalList && product.averageRating != null)
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        Text(
                          ' ${product.averageRating.toStringAsFixed(1)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          ' (${product.totalReviews})',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),

                  // Category tag (if not in horizontal list)
                  if (!isHorizontalList &&
                      product.category != null &&
                      product.category.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
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
                    ),

                  // Action buttons (if in horizontal list)
                  if (isHorizontalList && wishlistController != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        product.quantiteStock == 0
                            ? Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 0),
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
                                icon: const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.black87,
                                ),
                                onPressed: () {
                                  if (product.id == null ||
                                      product.id!.isEmpty) {
                                    Get.snackbar(
                                        'Erreur', 'Données produit invalides');
                                    return;
                                  }
                                  showProductDialog(context, product);
                                },
                              ),
                        Obx(() {
                          final isInWishlist = wishlistController!
                              .isProductInWishlist(product.id!);
                          return IconButton(
                            icon: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist ? Colors.red : Colors.black87,
                            ),
                            onPressed: () async {
                              final userEmail =
                                  authController?.currentUser?.email;
                              if (userEmail == null) {
                                Get.snackbar('Erreur',
                                    'Veuillez vous connecter d\'abord');
                                return;
                              }

                              try {
                                if (isInWishlist) {
                                  await wishlistController!
                                      .removeFromWishlist(product.id!);
                                } else {
                                  final wishlistItem = WishlistItem(
                                    userId: userEmail,
                                    productId: product.id!,
                                  );
                                  await wishlistController!
                                      .addToWishlist(wishlistItem);
                                }
                              } catch (e) {
                                Get.snackbar(
                                  'Erreur',
                                  'Échec de la mise à jour de la liste de souhaits: ${e.toString()}',
                                  backgroundColor: Colors.red[100],
                                  colorText: Colors.red[900],
                                );
                              }
                            },
                          );
                        }),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}