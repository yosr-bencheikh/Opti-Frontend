import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/Order.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

class OrderController extends GetxController {
  final OrderRepository orderRepository;
  
  OrderController({
    required this.orderRepository,
  });

  final RxList<Order> userOrders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final Rx<Order?> currentOrder = Rx<Order?>(null);
  
  // Pour les champs de la commande
  final RxString selectedAddress = ''.obs;
  final RxString selectedPaymentMethod = 'Carte bancaire'.obs;
  
  final deliveryFee = 5.50;

  Future<void> createOrderFromCart(String userId) async {
    try {
      isCreating.value = true;
      
      final cartController = Get.find<CartItemController>();
      final productController = Get.find<ProductController>();
      
      if (cartController.cartItems.value.isEmpty) {
        Get.snackbar('Erreur', 'Votre panier est vide');
        return;
      }
      
      // Log order creation attempt
      developer.log('Creating order for user: $userId');
      developer.log('Cart items count: ${cartController.cartItems.value.length}');
      
      // Préparer les éléments de la commande à partir du panier
      final List<OrderItem> orderItems = [];
      double subtotal = 0;
      
      for (var cartItem in cartController.cartItems.value) {
        final Product? product = productController.products.firstWhereOrNull(
          (p) => p.id == cartItem.productId,
        );
        
        if (product != null) {
          final double unitPrice = cartItem.totalPrice / cartItem.quantity;
          
          orderItems.add(OrderItem(
            productId: product.id!,
            productName: product.name,
            productImage: product.image,
            quantity: cartItem.quantity,
            unitPrice: unitPrice,
            totalPrice: cartItem.totalPrice,
          ));
          
          subtotal += cartItem.totalPrice;
        }
      }
      
      final double total = subtotal + deliveryFee;
      
      // Créer l'objet Order
      final order = Order(
        userId: userId,
        items: orderItems,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        address: selectedAddress.value,
        paymentMethod: selectedPaymentMethod.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Log the order data
      developer.log('Order data prepared: ${order.toJson()}');
      
      // Envoyer la commande au serveur directement via le repository
      developer.log('Sending order to server...');
      final createdOrder = await orderRepository.createOrder(order);
      
      developer.log('Order created successfully with ID: ${createdOrder.id}');
      currentOrder.value = createdOrder;
      
      // Vider le panier après une commande réussie
      developer.log('Clearing cart...');
      await cartController.clearCart(userId);
      
      Get.snackbar(
        'Succès', 
        'Votre commande a été confirmée avec succès',
        duration: const Duration(seconds: 3),
      );
      
    } catch (e) {
      developer.log('Error creating order: $e', error: e);
      
      // Show a more user-friendly error message
      String errorMessage = 'Une erreur est survenue lors de la création de la commande.';
      
      if (e.toString().contains('timed out') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet ou réessayez plus tard.';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isCreating.value = false;
    }
  }

  Future<void> loadUserOrders(String userId) async {
    try {
      isLoading.value = true;
      developer.log('Loading orders for user: $userId');
      
      final orders = await orderRepository.getUserOrders(userId);
      userOrders.value = orders;
      
      developer.log('Loaded ${orders.length} orders');
    } catch (e) {
      developer.log('Error loading orders: $e', error: e);
      
      String errorMessage = 'Une erreur est survenue lors du chargement des commandes.';
      
      if (e.toString().contains('timed out') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> getOrderDetails(String orderId) async {
    try {
      isLoading.value = true;
      developer.log('Fetching details for order: $orderId');
      
      final order = await orderRepository.getOrderById(orderId);
      currentOrder.value = order;
      
      developer.log('Order details fetched successfully');
    } catch (e) {
      developer.log('Error fetching order details: $e', error: e);
      
      String errorMessage = 'Une erreur est survenue lors du chargement des détails de la commande.';
      
      if (e.toString().contains('timed out') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> cancelOrder(String orderId) async {
    try {
      isLoading.value = true;
      developer.log('Cancelling order: $orderId');

      // Call the repository directly to cancel the order
      final success = await orderRepository.cancelOrder(orderId);

      if (success) {
        // Remove the canceled order from the userOrders list
        userOrders.removeWhere((order) => order.id == orderId);

        // Update the current order if it matches the canceled order
        if (currentOrder.value?.id == orderId) {
          currentOrder.value = null;
        }

        Get.snackbar(
          'Succès',
          'Commande supprimée avec succès',
          duration: const Duration(seconds: 3),
        );
        
        developer.log('Order cancelled successfully');
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de supprimer la commande',
          duration: const Duration(seconds: 3),
        );
        
        developer.log('Failed to cancel order');
      }

      return success;
    } catch (e) {
      developer.log('Error cancelling order: $e', error: e);
      
      String errorMessage = 'Une erreur est survenue lors de la suppression de la commande.';
      
      if (e.toString().contains('timed out') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      isLoading.value = true;
      developer.log('Updating order status: $orderId to $status');

      // Call the repository directly to update the order status
      final success = await orderRepository.updateOrderStatus(orderId, status);

      if (success) {
        // Refresh the order details if it's the current order
        if (currentOrder.value?.id == orderId) {
          await getOrderDetails(orderId);
        }
        
        // Refresh user orders list
        if (currentOrder.value?.userId != null) {
          await loadUserOrders(currentOrder.value!.userId);
        }

        Get.snackbar(
          'Succès',
          'Statut de commande mis à jour avec succès',
          duration: const Duration(seconds: 3),
        );
        
        developer.log('Order status updated successfully');
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de mettre à jour le statut de la commande',
          duration: const Duration(seconds: 3),
        );
        
        developer.log('Failed to update order status');
      }

      return success;
    } catch (e) {
      developer.log('Error updating order status: $e', error: e);
      
      String errorMessage = 'Une erreur est survenue lors de la mise à jour du statut.';
      
      if (e.toString().contains('timed out') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      }
      
      Get.snackbar(
        'Erreur', 
        errorMessage,
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
 Future<void> setAddress(String address, dynamic selectedLatitude, dynamic selectedLongitude) async {
  selectedAddress.value = address;
  
  // Try to get coordinates from the address
  try {
    List<Location> locations = await locationFromAddress(address);
    if (locations.isNotEmpty) {
      selectedLatitude = locations[0].latitude;
      selectedLongitude = locations[0].longitude;
      developer.log('Geocoded address to: ${selectedLatitude}, ${selectedLongitude}');
    }
  } catch (e) {
    developer.log('Geocoding failed: $e', error: e);
    // Reset coordinates if geocoding fails
    selectedLatitude= 0.0;
    selectedLongitude = 0.0;
  }
}

// Add a method to launch maps with specific address
Future<void> openInMaps(String address, {double? latitude, double? longitude}) async {
  try {
    String mapUrl;
    
    if (latitude != null && longitude != null && latitude != 0 && longitude != 0) {
      // Use coordinates if available
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    } else {
      // Use address string
      mapUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    }
    
    if (await canLaunchUrl(Uri.parse(mapUrl))) {
      await launchUrl(Uri.parse(mapUrl), mode: LaunchMode.externalApplication);
    } else {
      Get.snackbar(
        'Erreur',
        'Impossible d\'ouvrir Google Maps',
        duration: const Duration(seconds: 3),
      );
    }
  } catch (e) {
    developer.log('Error launching maps: $e', error: e);
    Get.snackbar(
      'Erreur',
      'Une erreur est survenue lors de l\'ouverture de la carte',
      duration: const Duration(seconds: 3),
    );
  }
}
  
  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }
}