import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/User/product_details_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class WishlistPage extends StatelessWidget {
  final String userEmail;
  final ProductController productController = Get.find();

  WishlistPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final WishlistController controller = Get.find();
    controller.initUser(userEmail);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Liste de souhaits',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.black87, size: 26),
            onPressed: () {},
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  'Chargement de votre liste...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.wishlistItems.isEmpty) {
          return _buildEmptyWishlist();
        }

        return _buildWishlistContent(controller);
      }),
    );
  }

  Widget _buildEmptyWishlist() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Votre liste de souhaits est vide',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez des articles à votre liste pour les retrouver facilement plus tard',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Get.to(() => StoresScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize: const Size(220, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 20),
                SizedBox(width: 8),
                Text(
                  'Découvrir les produits',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistContent(WishlistController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${controller.wishlistItems.length} article${controller.wishlistItems.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              TextButton.icon(
                onPressed: () => controller.refreshWishlist(),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Actualiser'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: controller.wishlistItems.length,
            itemBuilder: (context, index) {
              final wishlistItem = controller.wishlistItems[index];
              final product = productController.products.firstWhereOrNull(
                    (p) => p.id == wishlistItem.productId,
                  ) ??
                  Product(
                    id: 'not_found',
                    name: 'Produit non disponible',
                    prix: 0,
                    image: '',
                    description: '',
                    category: '',
                    marque: '',
                    couleur: [''],
                    quantiteStock: 0,
                    averageRating: 0,
                    totalReviews: 0,
                    style: '',
                    materiel: '',
                    sexe: '',
                  );

              if (product.id == 'not_found') {
                // Instead of hiding items not found, display them with different styling
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Produit non disponible',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Ce produit a été supprimé ou n\'est plus disponible',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () async {
                                  try {
                                    await controller.removeFromWishlist(wishlistItem.productId);
                                  } catch (e) {
                                    Get.snackbar(
                                      'Erreur',
                                      'Échec de la suppression de l\'article',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                      colorText: Colors.white,
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[400],
                                  side: BorderSide(color: Colors.red[400]!),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Dismissible(
                key: Key('${wishlistItem.productId}_${product.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red[400],
                    size: 28,
                  ),
                ),
                onDismissed: (direction) async {
                  final removedItem = controller.wishlistItems[index];
                  controller.wishlistItems.removeAt(index);

                  try {
                    await controller.removeFromWishlist(product.id!);
                    Get.snackbar(
                      'Supprimé',
                      'Article retiré de la liste',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.black87,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 8,
                      duration: const Duration(seconds: 2),
                    );
                  } catch (e) {
                    if (index <= controller.wishlistItems.length) {
                      controller.wishlistItems.insert(index, removedItem);
                    } else {
                      controller.wishlistItems.add(removedItem);
                    }
                    Get.snackbar(
                      'Erreur',
                      'Échec de la suppression de l\'article',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: Colors.red,
                      colorText: Colors.white,
                      margin: const EdgeInsets.all(16),
                      borderRadius: 8,
                    );
                  }
                },
                child: GestureDetector(
                  onTap: () => Get.to(() => ProductDetailsScreen(product: product)),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Product image with badge
                          Stack(
                            children: [
                              Hero(
                                tag: 'product-${product.id}',
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SizedBox(
                                    width: 90,
                                    height: 120,
                                    child: product.image.isEmpty
                                        ? Container(
                                            color: Colors.grey[100],
                                            child: const Icon(
                                              Icons.image_rounded,
                                              color: Colors.grey,
                                              size: 32,
                                            ),
                                          )
                                        : Image.network(
                                            product.image,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return Center(
                                                child: CircularProgressIndicator(
                                                  value: loadingProgress.expectedTotalBytes != null
                                                      ? loadingProgress.cumulativeBytesLoaded /
                                                          loadingProgress.expectedTotalBytes!
                                                      : null,
                                                  strokeWidth: 2,
                                                ),
                                              );
                                            },
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              color: Colors.grey[100],
                                              child: const Icon(
                                                Icons.broken_image_rounded,
                                                color: Colors.grey,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                              // Add availability badge if stock is low
                              if (product.quantiteStock > 0 && product.quantiteStock < 5)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[700],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: Text(
                                      'Stock limité',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Brand name
                                if (product.marque.isNotEmpty)
                                  Text(
                                    product.marque,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // Product name
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Color indicators if available
                                if (product.couleur.isNotEmpty && product.couleur.first.isNotEmpty)
                                  Row(
                                    children: [
                                      Text(
                                        'Couleur: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      ...product.couleur.take(3).map((color) {
                                        Color? displayColor;
                                        switch (color.toLowerCase()) {
                                          case 'rouge':
                                            displayColor = Colors.red;
                                            break;
                                          case 'bleu':
                                            displayColor = Colors.blue;
                                            break;
                                          case 'noir':
                                            displayColor = Colors.black;
                                            break;
                                          case 'blanc':
                                            displayColor = Colors.white;
                                            break;
                                          case 'vert':
                                            displayColor = Colors.green;
                                            break;
                                          case 'jaune':
                                            displayColor = Colors.yellow;
                                            break;
                                          case 'rose':
                                            displayColor = Colors.pink;
                                            break;
                                          case 'violet':
                                            displayColor = Colors.purple;
                                            break;
                                          case 'orange':
                                            displayColor = Colors.orange;
                                            break;
                                          case 'marron':
                                          case 'brun':
                                            displayColor = Colors.brown;
                                            break;
                                          case 'gris':
                                            displayColor = Colors.grey;
                                            break;
                                          default:
                                            displayColor = Colors.grey[300];
                                        }
                                        return Container(
                                          margin: const EdgeInsets.only(right: 4),
                                          width: 14,
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: displayColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                        );
                                      }).toList(),
                                      if (product.couleur.length > 3)
                                        Text(
                                          '+${product.couleur.length - 3}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                const SizedBox(height: 6),
                                // Rating indicators
                                if (product.averageRating > 0)
                                  Row(
                                    children: [
                                      ...List.generate(5, (i) {
                                        return Icon(
                                          i < product.averageRating.floor()
                                              ? Icons.star_rounded
                                              : i < product.averageRating
                                                  ? Icons.star_half_rounded
                                                  : Icons.star_border_rounded,
                                          size: 16,
                                          color: Colors.amber,
                                        );
                                      }),
                                      const SizedBox(width: 4),
                                      Text(
                                        '(${product.totalReviews})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                // Price and action buttons
                                Row(
                                  children: [
                                    Text(
                                      '€${product.prix.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 22,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        try {
                                          await controller.removeFromWishlist(product.id!);
                                        } catch (e) {
                                          Get.snackbar(
                                            'Erreur',
                                            'Échec de la suppression de l\'article',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                          );
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Add to cart button
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                                  label: const Text('Ajouter au panier'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 42),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}