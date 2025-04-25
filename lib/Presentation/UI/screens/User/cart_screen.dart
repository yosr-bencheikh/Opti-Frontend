import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Product3DViewer.dart';
import 'package:opti_app/Presentation/UI/screens/User/Rotating3DModel.dart';
import 'package:opti_app/Presentation/UI/screens/User/home_screen.dart';

import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

class CartScreen extends StatelessWidget {
  final NavigationController navigationController = Get.find();
  final CartItemController cartController = Get.find();
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    // Load cart items when screen builds
    _loadCartItems();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.offAll(() => HomeScreen()),
        ),
        title: const Text(
          'Mon Panier',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return Column(
          children: [
            Expanded(
              child: cartController.cartItems.isEmpty
                  ? const Center(child: Text('Votre panier est vide'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: cartController.cartItems.length,
                      itemBuilder: (context, index) {
                        final cartItem = cartController.cartItems[index];
                        return _buildCartItem(
                          cartItem.id!,
                          cartItem.productId,
                          cartItem.quantity,
                          cartItem.totalPrice,
                          context,
                        );
                      },
                    ),
            ),
            _buildCheckoutSection(),
          ],
        );
      }),
    );
  }

  void _loadCartItems() {
    final userId = authController.currentUserId.value;
    cartController.loadCartItems(userId);
  }

  Widget _buildCartItem(
    String id,
    String productId,
    int quantity,
    double price,
    BuildContext context,
  ) {
    final productController = Get.find<ProductController>();
    final product = productController.products.firstWhereOrNull(
      (p) => p.id == productId,
    );

    if (product == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        child: const Center(child: Text('Produit introuvable')),
      );
    }

    final String volumeText = 'Volume 80ml';
    final bool has3DModel = product.model3D.isNotEmpty;

    // Normaliser l'URL du modèle 3D
    String normalizedModelUrl =
        product.model3D.isNotEmpty ? _normalizeModelUrl(product.model3D) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ajout du modèle 3D ou de l'image ici
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: has3DModel
                  ? FutureBuilder<bool>(
                      future: _checkModelAvailability(normalizedModelUrl),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                              child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.blue),
                          ));
                        }

                        if (snapshot.hasData && snapshot.data == true) {
                          return Stack(
                            children: [
                              Rotating3DModel(modelUrl: normalizedModelUrl),
                              Positioned(
                                right: 4,
                                top: 4,
                                child: GestureDetector(
                                  onTap: () =>
                                      _showFullScreen3DModel(context, product),
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.view_in_ar,
                                      size: 16,
                                      color: const Color(0xFFFFA837),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        } else {
                          // Fallback à l'image si le modèle n'est pas disponible
                          return product.image.isNotEmpty
                              ? Image.network(product.image, fit: BoxFit.cover)
                              : Center(
                                  child: Icon(Icons.image,
                                      size: 40, color: Colors.grey));
                        }
                      },
                    )
                  : product.image.isNotEmpty
                      ? Image.network(
                          product.image,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Center(
                              child: Icon(Icons.broken_image,
                                  size: 40, color: Colors.grey)),
                        )
                      : Center(
                          child:
                              Icon(Icons.image, size: 40, color: Colors.grey)),
            ),
          ),

          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  volumeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFFA837)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove, size: 16),
                        color: const Color(0xFFFFA837),
                        onPressed: () {
                          if (quantity > 1) {
                            final newQuantity = quantity - 1;
                            final unitPrice = price / quantity;
                            final newTotalPrice = unitPrice * newQuantity;
                            cartController.updateCartItem(
                              id,
                              newQuantity,
                              newTotalPrice,
                            );
                          }
                        },
                      ),
                      Text(
                        '$quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add, size: 16),
                        color: const Color(0xFFFFA837),
                        onPressed: () {
                          final newQuantity = quantity + 1;
                          final unitPrice = price / quantity;
                          final newTotalPrice = unitPrice * newQuantity;
                          cartController.updateCartItem(
                            id,
                            newQuantity,
                            newTotalPrice,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBD9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${price.toStringAsFixed(2)} €',
              style: const TextStyle(
                color: Color(0xFFFFA837),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => cartController.deleteCartItem(id),
          ),
        ],
      ),
    );
  }

  // Méthodes pour gérer les modèles 3D
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

  void _showFullScreen3DModel(BuildContext context, dynamic product) {
    if (product.model3D.isEmpty) return;

    final String normalizedModelUrl = _normalizeModelUrl(product.model3D);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(
              product.name,
              style: TextStyle(color: Colors.black87, fontSize: 18),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Rotating3DModel(modelUrl: normalizedModelUrl),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckoutSection() {
    final total = cartController.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    final deliveryFee = 5.50;
    final totalWithDelivery = total + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Facture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total panier'),
              Text('${total.toStringAsFixed(2)} €'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Frais de livraison'),
              Text('${deliveryFee.toStringAsFixed(2)} €'),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${totalWithDelivery.toStringAsFixed(2)} €',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: cartController.cartItems.isEmpty
                ? null
                : () {
                    // Navigate to the checkout screen
                    Get.toNamed('/order');
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Confirmer la commande'),
          ),
        ],
      ),
    );
  }
}
