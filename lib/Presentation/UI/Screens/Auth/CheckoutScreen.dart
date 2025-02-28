import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';

class CheckoutScreen extends StatelessWidget {
  final CartItemController cartController = Get.find();
  final AuthController authController = Get.find();
  final OrderController orderController = Get.find();
  final ProductController productController = Get.find();
  late final GoogleMapController? mapController;
  // Variables pour les adresses et méthodes de paiement
  final List<String> addresses = [
    '12 Rue de Paris, 75001 Paris',
    '45 Avenue des Champs-Élysées, 75008 Paris',
    'Ajouter une nouvelle adresse...',
  ];

  final List<String> paymentMethods = [
    'Carte bancaire',
    'PayPal',
    'Paiement à la livraison',
  ];

@override
Widget build(BuildContext context) {
  // Préparer l'adresse et le mode de paiement par défaut
  if (orderController.selectedAddress.value.isEmpty && addresses.isNotEmpty) {
    orderController.setAddress(addresses.first);
  }

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

      if (cartController.cartItems.isEmpty) {
        return const Center(
          child: Text(
              'Votre panier est vide, impossible de confirmer la commande'),
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
              _buildMap(), // Ajoutez la carte ici
              const SizedBox(height: 24),
            _buildSectionTitle('Méthode de paiement'),
            const SizedBox(height: 8),
            _buildPaymentMethodSelector(),
            const SizedBox(height: 24),
            _buildSummary(),
            const SizedBox(height: 24),
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
                        'Confirmer et payer',
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
 Widget _buildMap() {
    return Container(
      height: 200, // Hauteur de la carte
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: FutureBuilder<Set<Marker>>(
          future: _buildMarkers(), // Appel asynchrone pour obtenir les marqueurs
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            } else {
              return GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(48.8566, 2.3522), // Paris par défaut
                  zoom: 12,
                ),
                markers: snapshot.data ?? {}, // Utilisez les marqueurs récupérés
                onMapCreated: (controller) {
                  // Vous pouvez stocker le contrôleur si nécessaire
                },
              );
            }
          },
        ),
      ),
    );
  }

  // Méthode pour créer des marqueurs de manière asynchrone
  Future<Set<Marker>> _buildMarkers() async {
    final selectedAddress = orderController.selectedAddress.value;
    if (selectedAddress.isEmpty) {
      return {};
    }

    // Convertir l'adresse en coordonnées (latitude, longitude)
    final coordinates = await geocodeAddress(selectedAddress);
    if (coordinates == null) {
      return {};
    }

    return {
      Marker(
        markerId: const MarkerId('selectedAddress'),
        position: coordinates,
        infoWindow: InfoWindow(title: selectedAddress),
      ),
    };
  }
Future<LatLng?> geocodeAddress(String address) async {
  final String apiKey = 'VOTRE_CLE_API';
  final String url =
      'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKey';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    if (data['results'].isNotEmpty) {
      final location = data['results'][0]['geometry']['location'];
      return LatLng(location['lat'], location['lng']);
    }
  }
  return null;
}
  // Méthode pour créer des marqueurs
  

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

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.image.startsWith('assets/')
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
                          width: 50,
                          height: 50,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
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
    child: DropdownButtonFormField<String>(
      value: orderController.selectedAddress.value.isNotEmpty
          ? orderController.selectedAddress.value
          : addresses.first,
      decoration: const InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: addresses.map((address) {
        return DropdownMenuItem<String>(
          value: address,
          child: Text(address),
        );
      }).toList(),
      onChanged: (value) {
        if (value == 'Ajouter une nouvelle adresse...') {
          _showAddAddressDialog(context); // Use the passed context
        } else {
          orderController.setAddress(value!);
        }
      },
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
      child: DropdownButtonFormField<String>(
        value: orderController.selectedPaymentMethod.value,
        decoration: const InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: paymentMethods.map((method) {
          return DropdownMenuItem<String>(
            value: method,
            child: Text(method),
          );
        }).toList(),
        onChanged: (value) {
          orderController.setPaymentMethod(value!);
        },
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
                '${total.toStringAsFixed(2)} €',
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

void _showAddAddressDialog(BuildContext context) {
  final TextEditingController addressController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: const Text('Ajouter une nouvelle adresse'),
      content: TextField(
        controller: addressController,
        decoration: const InputDecoration(
          hintText: 'Entrez votre adresse complète',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (addressController.text.isNotEmpty) {
              orderController.setAddress(addressController.text);
              Get.back();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
          ),
          child: const Text('Ajouter'),
        ),
      ],
    ),
  );
}

void _placeOrder(BuildContext context) async {
  // Vérifier que l'utilisateur est connecté
  final userId = authController.currentUserId.value;
  if (userId == null) {
    Get.snackbar(
      'Erreur',
      'Vous devez être connecté pour passer une commande',
      duration: const Duration(seconds: 3),
    );
    return;
  }

  // Vérifier que l'adresse est renseignée
  if (orderController.selectedAddress.value.isEmpty) {
    Get.snackbar(
      'Erreur',
      'Veuillez sélectionner une adresse de livraison',
      duration: const Duration(seconds: 3),
    );
    return;
  }

  // Complete the method by calling createOrderFromCart
  await orderController.createOrderFromCart(userId);

  // If the order was successfully created, navigate to the order confirmation screen
  if (orderController.currentOrder.value != null) {
    // You have several options:
    
    // 1. Navigate to a dedicated order confirmation screen:
    // Get.toNamed('/order-confirmation', arguments: orderController.currentOrder.value);
    
    // 2. Navigate to the order details page:
    // Get.toNamed('/order-details', arguments: orderController.currentOrder.value?.id);
    
    // 3. Go back to the previous screen with a success message:
    Get.back();
    Get.snackbar(
      'Commande réussie',
      'Votre commande a été confirmée. Vous pouvez suivre son statut dans la section Mes Commandes.',
      duration: const Duration(seconds: 4),
    );
  }
}
}
