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
import 'package:opti_app/core/styles/colors.dart';

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
          icon: Icon(Icons.arrow_back, color: AppColors.textColor),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Confirmer la commande',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
      ),
      body: Obx(() {
        if (cartController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          );
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
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.whiteColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: AppColors.paleBlue,
                  ),
                  child: orderController.isCreating.value
                      ? CircularProgressIndicator(color: AppColors.whiteColor)
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
      backgroundColor: AppColors.softWhite,
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
            child: Text('Non', 
              style: TextStyle(color: AppColors.textColor),
            ),
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
              foregroundColor: AppColors.whiteColor,
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
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textColor,
      ),
    );
  }

  Widget _buildCartItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: cartController.cartItems.length,
        separatorBuilder: (context, index) => Divider(
          height: 1, 
          color: AppColors.paleBlue,
        ),
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
                color: AppColors.lightBlueBackground,
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
                                    color: AppColors.lightBlueBackground,
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: AppColors.greyTextColor,
                                    ),
                                  );
                                },
                              )
                        : Icon(
                            Icons.image, 
                            color: AppColors.greyTextColor,
                          ),
              ),
            ),
            title: Text(
              product.name,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textColor,
              ),
            ),
            subtitle: Text(
              'Quantité: ${cartItem.quantity}',
              style: TextStyle(
                color: AppColors.greyTextColor,
              ),
            ),
            trailing: Text(
              '${cartItem.totalPrice.toStringAsFixed(2)} €',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondaryColor,
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
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
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
                Icon(Icons.location_on, color: AppColors.accentColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Adresse de livraison actuelle:',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: AppColors.greyTextColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        orderController.selectedAddress.value,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.textColor,
                        ),
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
              icon: const Icon(Icons.map, color: AppColors.whiteColor),
              label: Text(
                orderController.selectedAddress.value.isEmpty
                    ? 'Sélectionner mon adresse sur la carte'
                    : 'Modifier mon adresse',
                style: TextStyle(color: AppColors.whiteColor),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
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
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          'Paiement à la livraison',
          style: TextStyle(color: AppColors.textColor),
        ),
        subtitle: Text(
          'Seule méthode disponible',
          style: TextStyle(color: AppColors.greyTextColor),
        ),
        leading: Icon(
          Icons.money_off_csred,
          color: AppColors.accentColor,
        ),
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
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sous-total',
                style: TextStyle(color: AppColors.textColor),
              ),
              Text(
                '${subtotal.toStringAsFixed(2)} €',
                style: TextStyle(color: AppColors.textColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Frais de livraison',
                style: TextStyle(color: AppColors.textColor),
              ),
              Text(
                '${deliveryFee.toStringAsFixed(2)} €',
                style: TextStyle(color: AppColors.textColor),
              ),
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
                '${total.toStringAsFixed(2)} TND',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.primaryColor,
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
        colorText: AppColors.whiteColor,
        backgroundColor: Colors.red.shade600,
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
        colorText: AppColors.whiteColor,
        backgroundColor: AppColors.primaryColor,
        duration: const Duration(seconds: 4),
      );
    }
  }

  void _showLocationOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.whiteColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.my_location, color: AppColors.accentColor),
                title: Text(
                  'Use Current Location',
                  style: TextStyle(color: AppColors.textColor),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _handleCurrentLocationSelection();
                },
              ),
              ListTile(
                leading: Icon(Icons.map, color: AppColors.accentColor),
                title: Text(
                  'Choose on Map',
                  style: TextStyle(color: AppColors.textColor),
                ),
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
        colorText: AppColors.whiteColor,
        backgroundColor: Colors.red.shade600,
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