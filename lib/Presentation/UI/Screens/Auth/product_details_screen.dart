import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/UI/screens/auth/home_screen.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/wishlist_item.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/presentation/widgets/product_dialog.dart';

class ProductDetailsScreen extends GetView<ProductController> {
  final Product product;

  ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  final RxBool isInWishlist = false.obs;
  final RxBool isCheckingWishlist = true.obs;

  @override
  void initState() {
    _checkWishlistStatus();

    final AuthController authController = Get.find<AuthController>();
    final WishlistController wishlistController =
        Get.find<WishlistController>();

    if (authController.currentUser?.email != null) {
      if (wishlistController.currentUserEmail !=
          authController.currentUser!.email) {
        wishlistController.initUser(authController.currentUser!.email);
      }
    }
  }

  Future<void> _checkWishlistStatus() async {
    final WishlistController wishlistController =
        Get.find<WishlistController>();
    final AuthController authController = Get.find<AuthController>();

    isCheckingWishlist.value = true;

    if (authController.currentUser?.email != null) {
      // Vérifier si l'utilisateur est déjà initialisé
      if (wishlistController.currentUserEmail !=
          authController.currentUser!.email) {
        // Initialiser l'utilisateur et attendre que ce soit terminé
        wishlistController.initUser(authController.currentUser!.email);
        // Attendre un court instant pour que l'initialisation se fasse
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Vérifier si le produit est dans la wishlist
      try {
        // Option plus robuste: vérifier en temps réel
        final bool inWishlist = await wishlistController
            .checkProductInWishlistRealtime(product.id!);
        isInWishlist.value = inWishlist;
      } catch (e) {
        // En cas d'erreur, utiliser la méthode locale
        isInWishlist.value =
            wishlistController.isProductInWishlist(product.id!);
      }
    }

    isCheckingWishlist.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Sticky Image Section
          SliverAppBar(
            expandedHeight: 300, // Height of the image when expanded
            pinned: true, // Make the image stick to the top
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                ),
                child: product.image != null && product.image!.isNotEmpty
                    ? Container(
                        width: 50, // Full width
                        height: 50, // Fixed height
                        child: Image.network(
                          product.image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: double.infinity, // Full width for placeholder
                        height: 300, // Fixed height for placeholder
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: Icon(Icons.image, size: 100, color: Colors.grey),
                      ),
              ),
            ),
          ),
          // Scrollable Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                _buildProductInfo(),
                _buildProductDescription(),
                _buildProductSpecs(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 50,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.black87),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_outlined, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }



  Widget _buildProductInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              
              const SizedBox(width: 8),
            _buildRatingSection(),
              
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '€${product.prix.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'En stock',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ]));
  }

  Widget _buildProductDescription() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.description ?? 'Aucune description disponible.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSpecs() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spécifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                _buildSpecRow('Marque', product.marque ?? 'Non spécifié'),
                const Divider(),
                _buildSpecRow('Catégorie', product.category ?? 'Non spécifié'),
                const Divider(),
                _buildSpecRow('Référence', product.id ?? 'Non spécifié'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
 // Rating Section
  Widget _buildRatingSection() {
    return GestureDetector(
      onTap: () => Get.to(() => ReviewsScreen(product: product)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.star, color: Colors.amber, size: 20),
            SizedBox(width: 4),
            Text(
              '4.8',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber[800],
              ),
            ),
            SizedBox(width: 4),
            Text(
              '(25 reviews)',
              style: TextStyle(color: Colors.grey),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
  Widget _buildBottomBar() {
    final WishlistController wishlistController =
        Get.find<WishlistController>();
    final AuthController authController = Get.find<AuthController>();

    return Builder(builder: (BuildContext context) {
      // Add this Builder widget to get context
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Obx(() {
              // Utilisez isInWishlist.value plutôt que d'appeler directement wishlistController
              return IconButton(
                icon: Icon(
                  isInWishlist.value ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist.value ? Colors.red : Colors.grey,
                  size: 28,
                ),
                onPressed: () async {
                  final userEmail = authController.currentUser?.email;
                  if (userEmail == null) {
                    Get.snackbar('Erreur', 'Veuillez vous connecter d\'abord');
                    return;
                  }

                  try {
                    if (isInWishlist.value) {
                      // Si produit est dans la liste de souhaits, le supprimer
                      final wishlistItem = wishlistController
                          .getWishlistItemByProductId(product.id!);
                      if (wishlistItem != null) {
                        await wishlistController
                            .removeFromWishlist(wishlistItem.id);
                        isInWishlist.value =
                            false; // Mettre à jour l'état local immédiatement
                      }
                    } else {
                      // Si produit n'est pas dans la liste de souhaits, l'ajouter
                      final wishlistItem = WishlistItem(
                        id: '', // ID sera généré côté serveur
                        product: product,
                        userId: userEmail,
                        productId: product.id!,
                      );
                      await wishlistController.addToWishlist(wishlistItem);
                      isInWishlist.value =
                          true; // Mettre à jour l'état local immédiatement
                    }
                    // Rafraîchir l'état après l'opération
                  } catch (e) {
                    Get.snackbar(
                      'Erreur',
                      'Impossible de mettre à jour la liste de souhaits',
                      backgroundColor: Colors.red[100],
                      colorText: Colors.red[900],
                    );
                  }
                },
              );
            }),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (product.id == null || product.id!.isEmpty) {
                    Get.snackbar('Error', 'Invalid product data');
                    return;
                  }
                  // Make sure you have access to context here
                  showProductDialog(context, product);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pink[80],
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Ajouter au panier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// Reviews Screen with Floating Dialog
class ReviewsScreen extends StatelessWidget {
  final Product product;

  ReviewsScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer Reviews'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReviewDialog(context),
        child: Icon(Icons.edit),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          _buildOverallRating(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: 25,
              itemBuilder: (context, index) => _buildReviewItem(),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Write a Review"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              // Wrap the Row in a SingleChildScrollView
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: Row(
                  children: [
                    Text('Rating:'),
                    SizedBox(width: 12),
                    ...List.generate(
                        5,
                        (index) => IconButton(
                              icon: Icon(
                                Icons.star_border,
                                color: Colors.amber,
                                size: 32,
                              ),
                              onPressed: () {
                                // Handle star rating selection
                              },
                            )),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Submit logic
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
            ),
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '4.8',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              Row(
                children: List.generate(
                    5,
                    (index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 20,
                        )),
              ),
              Text(
                '25 reviews',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildRatingProgress('5', 0.8),
                _buildRatingProgress('4', 0.15),
                _buildRatingProgress('3', 0.05),
                _buildRatingProgress('2', 0.0),
                _buildRatingProgress('1', 0.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingProgress(String stars, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(stars),
          Icon(Icons.star, size: 16, color: Colors.amber),
          SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              color: Colors.amber,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewItem() {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundImage: NetworkImage("https://i.pravatar.cc/50"),
              ),
              title: Text("John Doe"),
              subtitle: Text("2 days ago"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                    5,
                    (index) => Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        )),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Excellent product! The glasses are very comfortable and the quality is top-notch. Highly recommended!",
                style: TextStyle(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
