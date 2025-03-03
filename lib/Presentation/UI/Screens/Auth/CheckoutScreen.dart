import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

import 'package:opti_app/Presentation/UI/screens/auth/pdf.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/Order.dart';
import 'package:pdf/widgets.dart' as pw;

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartItemController cartController = Get.find();
  final AuthController authController = Get.find();
  final OrderController orderController = Get.find();
  final ProductController productController = Get.find();

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
  void initState() {
    super.initState();
    // Préparer l'adresse et le mode de paiement par défaut
    if (orderController.selectedAddress.value.isEmpty && addresses.isNotEmpty) {
      orderController.setAddress(addresses.first);
    }

    // Initialiser la méthode de paiement par défaut si nécessaire
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
              const SizedBox(height: 24),
              _buildSectionTitle('Méthode de paiement'),
              const SizedBox(height: 8),
              _buildPaymentMethodSelector(),
              const SizedBox(height: 24),
              _buildSummary(),
              const SizedBox(height: 24),
              // Afficher le bouton d'annulation uniquement si une commande existe
              Visibility(
                visible: orderController.currentOrder.value != null,
                child: Column(
                  children: [
                    _buildCancelOrderButton(context),
                    const SizedBox(height: 16),
                  ],
                ),
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

  Widget _buildCancelOrderButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        label: const Text(
          'Annuler la commande',
          style: TextStyle(fontSize: 16),
        ),
        onPressed: orderController.currentOrder.value != null
            ? () => _showCancelConfirmationDialog(
            context, orderController.currentOrder.value!.id!)
            : null,
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

  void _showCancelConfirmationDialog(BuildContext context, String orderId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette commande?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              final success = await orderController.cancelOrder(orderId);
              if (success) {
                Get.back(); // Retourner à l'écran précédent
              }
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
            _showAddAddressDialog(context);
          } else if (value != null) {
            orderController.setAddress(value);
          }
        },
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    // S'assurer qu'une méthode de paiement par défaut est sélectionnée
    final currentPaymentMethod =
    orderController.selectedPaymentMethod.value.isNotEmpty
        ? orderController.selectedPaymentMethod.value
        : paymentMethods.first;

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
        value: currentPaymentMethod,
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
          if (value != null) {
            orderController.setPaymentMethod(value);
          }
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
                final newAddress = addressController.text;
                orderController.setAddress(newAddress);
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

  Future<void> _placeOrder(BuildContext context) async {
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

    await orderController.createOrderFromCart(userId);

    // Si la commande a été créée avec succès
    if (orderController.currentOrder.value != null) {
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
}