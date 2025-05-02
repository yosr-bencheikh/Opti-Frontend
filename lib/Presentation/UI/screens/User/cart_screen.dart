import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/Presentation/UI/screens/Admin/3D.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Product3DViewer.dart';
import 'package:opti_app/Presentation/UI/screens/User/Rotating3DModel.dart';
import 'package:opti_app/Presentation/UI/screens/User/home_screen.dart';

import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/core/styles/colors.dart';

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
        title: Text(
          'Mon panier',
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
      body: Obx(() {
        if (cartController.isLoading.value) {
          return Center(child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
          ));
        }
        return Column(
          children: [
            Expanded(
              child: cartController.cartItems.isEmpty
                  ? Center(child: Text('Votre panier est vide', 
                      style: TextStyle(color: AppColors.greyTextColor)))
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
        child: Center(child: Text('Produit introuvable', 
            style: TextStyle(color: AppColors.greyTextColor))),
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
            color: AppColors.primaryColor.withOpacity(0.05),
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
              color: AppColors.softWhite,
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
                                AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
                          ));
                        }

                        if (snapshot.hasData && snapshot.data == true) {
                          return Stack(
                            children: [
                              Flutter3DViewer(src: product.model3D),
                            ],
                          );
                        } else {
                          // Fallback à l'image si le modèle n'est pas disponible
                          return product.image.isNotEmpty
                              ? Image.network(product.image, fit: BoxFit.cover)
                              : Center(
                                  child: Icon(Icons.image,
                                      size: 40, color: AppColors.greyTextColor));
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
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondaryColor),
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
                                  size: 40, color: AppColors.greyTextColor)),
                        )
                      : Center(
                          child:
                              Icon(Icons.image, size: 40, color: AppColors.greyTextColor)),
            ),
          ),

          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  volumeText,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.greyTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accentColor),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.remove, size: 16),
                        color: AppColors.accentColor,
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
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textColor,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.add, size: 16),
                        color: AppColors.accentColor,
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
              color: AppColors.paleBlue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${price.toStringAsFixed(2)} €',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.greyTextColor),
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
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Facture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total panier', style: TextStyle(color: AppColors.textColor)),
              Text('${total.toStringAsFixed(2)} €', style: TextStyle(color: AppColors.textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Frais de livraison', style: TextStyle(color: AppColors.textColor)),
              Text('${deliveryFee.toStringAsFixed(2)} €', style: TextStyle(color: AppColors.textColor)),
            ],
          ),
          Divider(height: 24, color: AppColors.paleBlue),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              Text(
                '${totalWithDelivery.toStringAsFixed(2)} €',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
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
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              disabledBackgroundColor: AppColors.paleBlue.withOpacity(0.5),
            ),
            child: const Text('Confirmer la commande'),
          ),
        ],
      ),
    );
  }
}