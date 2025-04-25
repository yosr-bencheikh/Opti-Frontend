import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:geocoding/geocoding.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/Product3DViewer.dart';
import 'package:opti_app/Presentation/UI/screens/User/location_picker_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/pdf.dart';
import 'dart:developer' as developer;

import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartItemController cartController = Get.find();
  final AuthController authController = Get.find();
  final OrderController orderController = Get.find();
  final ProductController productController = Get.find();

  // Add RxDouble values for latitude and longitude
  final RxDouble selectedLatitude = 0.0.obs;
  final RxDouble selectedLongitude = 0.0.obs;

  // Variables pour les adresses et méthodes de paiement
  final List<String> paymentMethods = [
    'Paiement à la livraison', // Only cash on delivery
  ];

  @override
  void initState() {
    super.initState();
    // Set default payment method
    if (orderController.selectedPaymentMethod.value.isEmpty &&
        paymentMethods.isNotEmpty) {
      orderController.setPaymentMethod(paymentMethods.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Confirmer la commande',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Articles'),
              const SizedBox(height: 8),
              _buildCartItemsList(),
              const SizedBox(height: 24),
              _buildSectionTitle('Adresse de livraison'),
              const SizedBox(height: 8),
              _buildAddressSelector(context),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              _buildSectionTitle('Méthode de paiement'),
              const SizedBox(height: 8),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
              _buildSummary(),
              const SizedBox(height: 24),
              // Afficher le bouton d'annulation uniquement si une commande existe
              Column(
                children: [
                  _buildCancelOrderButton(context),
                  const SizedBox(height: 16),
                ],
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: orderController.isCreating.value
                      ? null
                      : () => _placeOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: orderController.isCreating.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Confirmer La commande',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Modify the _buildCancelOrderButton method
  Widget _buildCancelOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text(
          'Annuler la commande',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: () => _showCancelConfirmationDialog(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

// Update the _showCancelConfirmationDialog method
  void _showCancelConfirmationDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text(
            'Êtes-vous sûr de vouloir annuler cette commande et retourner au panier?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear the current order
              orderController.currentOrder.value = null;

              // Clear any order-related data if needed
              orderController.selectedAddress.value = '';
              orderController.selectedPaymentMethod.value = '';

              // Navigate back to the cart screen
              Get.offAllNamed(
                  '/cart'); // Assuming you have a named route for cart
              // If you don't have named routes, you can use:
              // Get.offAll(() => CartScreen());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCartItemsList() {
    return Container(
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
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cartController.cartItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final cartItem = cartController.cartItems[index];
          final product = productController.products.firstWhereOrNull(
            (p) => p.id == cartItem.productId,
          );

          if (product == null) {
            return const SizedBox.shrink();
          }

          final bool has3DModel = product.model3D.isNotEmpty;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: has3DModel
                    ? Fixed3DViewer(
                        modelUrl: product.model3D,
                        compactMode: true,
                        autoRotate: true,
                      )
                    : product.image.isNotEmpty
                        ? product.image.startsWith('assets/')
                            ? Image.asset(
                                product.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                product.image,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child:
                                        const Icon(Icons.image_not_supported),
                                  );
                                },
                              )
                        : Icon(Icons.image, color: Colors.grey[400]),
              ),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Quantité: ${cartItem.quantity}'),
            trailing: Text(
              '${cartItem.totalPrice.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFA837),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddressSelector(BuildContext context) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show the current selected address
          if (orderController.selectedAddress.value.isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, color: Color(0xFFFFA837)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse de livraison actuelle:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderController.selectedAddress.value,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Map button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.map, color: Colors.white),
              label: Text(
                orderController.selectedAddress.value.isEmpty
                    ? 'Sélectionner mon adresse sur la carte'
                    : 'Modifier mon adresse',
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA837),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _showLocationOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Container(
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
      child: ListTile(
        title: Text('Paiement à la livraison'),
        subtitle: Text('Seule méthode disponible'),
        leading: Icon(Icons.money_off_csred),
      ),
    );
  }

  Widget _buildSummary() {
    final subtotal = cartController.cartItems.fold<double>(
      0,
      (sum, item) => sum + item.totalPrice,
    );

    final deliveryFee = orderController.deliveryFee;
    final total = subtotal + deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Récapitulatif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sous-total'),
              Text('${subtotal.toStringAsFixed(2)} €'),
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
                '${total.toStringAsFixed(2)} TND',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFFFFA837),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _placeOrder(BuildContext context) async {
    // Vérifier que l'utilisateur est connecté
    final userId = authController.currentUserId.value;

    // Vérifier que l'adresse est renseignée
    if (orderController.selectedAddress.value.isEmpty) {
      Get.snackbar(
        'Erreur',
        'Veuillez sélectionner une adresse de livraison',
        duration: const Duration(seconds: 3),
      );
      return;
    }

    await orderController.createOrderFromCart(userId);

    // Si la commande a été créée avec succès
    if (orderController.currentOrder.value != null) {
      // Vider le panier après la création de la commande
      await cartController.clearCart(userId);

      // Générer et afficher la facture
      await generateAndOpenInvoice(orderController.currentOrder.value!);

      // Afficher un message de succès
      Get.back();
      Get.snackbar(
        'Commande réussie',
        'Votre commande a été confirmée. Vous pouvez suivre son statut dans la section Mes Commandes.',
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.my_location),
                title: Text('Use Current Location'),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleCurrentLocationSelection();
                },
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text('Choose on Map'),
                onTap: () {
                  Navigator.pop(context);
                  _selectAddressFromMap(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleCurrentLocationSelection() async {
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        if (result != LocationPermission.whileInUse &&
            result != LocationPermission.always) {
          throw Exception('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final addresses = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (addresses.isNotEmpty) {
        final place = addresses.first;
        final address =
            '${place.street}, ${place.locality}, ${place.postalCode}';
        orderController.setAddress(
          address,
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Could not get current location: ${e.toString()}',
        duration: Duration(seconds: 3),
      );
    }
  }

  Future<void> _selectAddressFromMap(BuildContext context) async {
    final result = await Get.to(() => LocationPickerScreen());
    if (result != null) {
      orderController.setAddress(
        result['address'],
        result['lat'],
        result['lng'],
      );
    }
  }
}
