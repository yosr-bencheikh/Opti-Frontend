import 'package:flutter/widgets.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/domain/entities/Order.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';
import 'dart:developer' as developer;

import 'package:url_launcher/url_launcher.dart';

class OrderController extends GetxController {
  final OrderRepository orderRepository;
  final BoutiqueRepository boutiqueRepository;
  final UserController userController = Get.find<UserController>();
  final RxList<User> users = <User>[].obs;
  final Rxn<String> error = Rxn<String>();
  OrderController({
    required this.orderRepository,
    required this.boutiqueRepository,
  });

  final RxList<Order> userOrders = <Order>[].obs;
  final RxList<Order> allOrders =
      <Order>[].obs; // Liste pour toutes les commandes
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final Rx<Order?> currentOrder = Rx<Order?>(null);
  bool get isloading => isLoading.value;

  // Pour les champs de la commande
  final RxString selectedAddress = ''.obs;
  final RxString selectedPaymentMethod = ''.obs;

  final deliveryFee = 5.50;
  Future<void> refreshOrders() async {
    try {
      isLoading.value = true;

      // Si c'est un opticien qui est connecté
      final opticianController = Get.find<OpticianController>();
      if (opticianController.isLoggedIn.value) {
        await loadOrdersForCurrentOpticianWithDetails();
      } else {
        // Si c'est un administrateur ou un autre type d'utilisateur
        final orders = await orderRepository.getAllOrders();
        allOrders.assignAll(orders);
      }

      error.value = null;
    } catch (e) {
      error.value = 'Erreur lors du chargement des commandes: ${e.toString()}';
      print('Erreur dans refreshOrders: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<String>> getUserIdsByOptician(String opticianId) async {
    try {
      final orders = await orderRepository.getAllOrders();
      final userIds = orders
          .where((order) =>
              order.items.any((item) => item.boutiqueId == opticianId))
          .map((order) => order.userId)
          .toSet()
          .toList();
      return userIds;
    } catch (e) {
      error.value = 'Failed to get user IDs: ${e.toString()}';
      rethrow;
    }
  }

// Dans OrderController, modifiez getUsersByOptician
  Future<List<User>> getUsersByOptician(String connectedOpticianId) async {
    try {
      // 1. Récupérer les boutiques associées à l'opticien
      final boutiqueController = Get.find<BoutiqueController>();
      await boutiqueController.getboutiqueByOpticianId(connectedOpticianId);
      final boutiques = boutiqueController.opticiensList;

      // Debugging
      print("Nombre de boutiques trouvées: ${boutiques.length}");
      print("IDs des boutiques: ${boutiques.map((b) => b.id).toList()}");

      // Si aucune boutique trouvée, retourner liste vide
      if (boutiques.isEmpty) {
        print("Aucune boutique trouvée pour l'opticien: $connectedOpticianId");
        return [];
      }

      final boutiqueIds = boutiques.map((b) => b.id).toList();

      // 2. Récupérer toutes les commandes
      final orders = await orderRepository.getAllOrders();
      print("Nombre total de commandes: ${orders.length}");

      // 3. Filtrer les commandes pertinentes
      final filteredOrders = orders.where((order) {
        return order.items.any((item) {
          final matchesBoutique = boutiqueIds.contains(item.boutiqueId);
          final matchesOpticien = item.opticienId != null &&
              (item.opticienId == connectedOpticianId ||
                  boutiqueIds.contains(item.opticienId));
          return matchesBoutique || matchesOpticien;
        });
      }).toList();

      print("Nombre de commandes filtrées: ${filteredOrders.length}");

      // 4. Extraire les IDs utilisateurs uniques
      final userIds = filteredOrders.map((o) => o.userId).toSet().toList();
      print("Nombre d'utilisateurs uniques: ${userIds.length}");

      if (userIds.isEmpty) {
        print("Aucun utilisateur trouvé avec des commandes pour cet opticien");
        return [];
      }

      // 5. Récupérer les détails des utilisateurs
      final users = await userController.getUsersByIds(userIds);

      // Defer error clearing to after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        error.value = null;
      });

      return users;
    } catch (e) {
      // Defer error setting to after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        error.value = e.toString();
      });
      rethrow;
    }
  }

  Future<void> loadOrdersForCurrentOpticianWithDetails() async {
    try {
      isLoading.value = true;

      final opticianController = Get.find<OpticianController>();
      final boutiqueController = Get.find<BoutiqueController>();

      // 1. Get boutiques for current optician
      await boutiqueController
          .getboutiqueByOpticianId(opticianController.currentUserId.value);
      final boutiqueIds =
          boutiqueController.opticiensList.map((b) => b.id).toList();

      // 2. Load all orders
      final orders = await orderRepository.getAllOrders();

      // 3. Filter and enrich with boutique details
      final enrichedOrders = orders.where((order) {
        return order.items.any((item) => boutiqueIds.contains(item.boutiqueId));
      }).map((order) {
        // Add boutique details to each order
        final boutiqueId = order.items
            .firstWhere(
              (item) => boutiqueIds.contains(item.boutiqueId),
            )
            ?.boutiqueId;

        if (boutiqueId != null) {
          final boutique = boutiqueController.opticiensList.firstWhere(
            (b) => b.id == boutiqueId,
          );
          return order.copyWith(boutique: boutique);
        }
        return order;
      }).toList();

      allOrders.assignAll(enrichedOrders);
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

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
      developer
          .log('Cart items count: ${cartController.cartItems.value.length}');

      // Préparer les éléments de la commande à partir du panier
      final List<OrderItem> orderItems = [];
      double subtotal = 0;
      String? boutiqueId;

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
            boutiqueId: product.boutiqueId,
          ));

          subtotal += cartItem.totalPrice;

          // Récupérer le boutiqueId du premier produit
          if (boutiqueId == null && product.boutiqueId != null) {
            boutiqueId = product.boutiqueId;
          }
        }
      }

      final double total = subtotal + deliveryFee;

      // Créer l'objet Order avec le boutiqueId
      final order = Order(
        userId: userId,
        boutiqueId: boutiqueId, // Ajoutez le boutiqueId ici
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
      String errorMessage =
          'Une erreur est survenue lors de la création de la commande.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet ou réessayez plus tard.';
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

  Future<void> getOrderDetails(String orderId) async {
    try {
      isLoading.value = true;
      developer.log('Fetching details for order: $orderId');

      final order = await orderRepository.getOrderById(orderId);

      if (order.boutiqueId != null && order.boutiqueId!.isNotEmpty) {
        try {
          // Fetch the boutique details
          final boutique =
              await boutiqueRepository.getOpticienById(order.boutiqueId!);
          currentOrder.value = order.copyWith(boutique: boutique);
        } catch (e) {
          developer.log('Error fetching boutique details: $e', error: e);
          currentOrder.value = order;
        }
      } else {
        currentOrder.value = order;
      }

      developer.log('Order details fetched successfully');
      developer.log('Boutique details: ${order.boutique}'); // Debug statement
    } catch (e) {
      developer.log('Error fetching order details: $e', error: e);

      String errorMessage =
          'Une erreur est survenue lors du chargement des détails de la commande.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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

  void updateLocalOrderStatus(String orderId, String newStatus) {
    // Find the order in the allOrders list
    final int index = allOrders.indexWhere((order) => order.id == orderId);

    if (index != -1) {
      // Create a copy of the order with the updated status
      Order updatedOrder = Order(
        id: allOrders[index].id,
        userId: allOrders[index].userId,
        boutiqueId: allOrders[index].boutiqueId,
        items: allOrders[index].items,
        status: newStatus,
        address: allOrders[index].address,
        paymentMethod: allOrders[index].paymentMethod,
        subtotal: allOrders[index].subtotal,
        deliveryFee: allOrders[index].deliveryFee,
        total: allOrders[index].total,
        createdAt: allOrders[index].createdAt,
        updatedAt: allOrders[index].updatedAt,
      );

      // Update the order in the list
      allOrders[index] = updatedOrder;

      // Notify the UI that the data has changed
      update();
    }
  }

  final RxString currentUserName = ''.obs;

  Future<String> getOrderUserName(String userId) async {
    try {
      // First, check if the user is already loaded in the controller's users list
      final user = userController.users.firstWhere(
        (user) => user.email == userId,
      );

      if (user != null) {
        currentUserName.value = '${user.nom} ${user.prenom}'.trim();
        return currentUserName.value;
      }

      // If not found in the current list, fetch the user by ID
      try {
        final fetchedUser = await userController.fetchUserById(userId);
        currentUserName.value =
            '${fetchedUser.nom} ${fetchedUser.prenom}'.trim();
        return currentUserName.value;
      } catch (fetchError) {
        print('Error fetching user by ID: $fetchError');
      }

      // Last resort if no user is found
      currentUserName.value = 'Utilisateur ${userId.substring(0, 8)}';
      return currentUserName.value;
    } catch (e) {
      print('Error in getOrderUserName: $e');
      currentUserName.value = 'Utilisateur Inconnu';
      return currentUserName.value;
    }
  }

  Future<void> loadUserOrders(String userId) async {
    try {
      // Add null and empty string checks
      if (userId == null || userId.isEmpty || userId.trim() == '') {
        developer.log('Invalid user ID for fetching orders');
        Get.snackbar(
          'Erreur',
          'Impossible de charger les commandes. Utilisateur non identifié.',
          duration: const Duration(seconds: 3),
        );
        return;
      }

      isLoading.value = true;
      developer.log('Loading orders for user: $userId');

      final orders = await orderRepository.getUserOrders(userId);
      developer.log('Orders fetched: ${orders.length}');

      userOrders.value = orders;

      // Add a log to show more details about the fetched orders
      orders.forEach((order) {
        developer.log(
            'Order ID: ${order.id}, Total: ${order.total}, Status: ${order.status}');
      });
    } catch (e) {
      developer.log('Error loading orders: $e', error: e);

      String errorMessage =
          'Une erreur est survenue lors du chargement des commandes.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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

  Future<void> loadAllOrders() async {
    try {
      isLoading.value = true;
      developer.log('Loading all orders...');

      final orders = await orderRepository.getAllOrders();
      allOrders.value = orders;

      developer.log('Loaded ${orders.length} orders');
    } catch (e) {
      developer.log('Error loading all orders: $e', error: e);

      String errorMessage =
          'Une erreur est survenue lors du chargement des commandes.';
      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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

      String errorMessage =
          'Une erreur est survenue lors de la suppression de la commande.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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

  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String?
        cancellationReason, // Add cancellationReason as an optional parameter
  }) async {
    try {
      isLoading.value = true;
      developer.log('Updating order status: $orderId to $status');

      // Call the repository to update the order status with cancellation reason
      final success = await orderRepository.updateOrderStatus(
        orderId,
        status,
        cancellationReason: cancellationReason, // Pass cancellationReason
      );

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

      String errorMessage =
          'Une erreur est survenue lors de la mise à jour du statut.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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

  Future<void> setAddress(String address, dynamic selectedLatitude,
      dynamic selectedLongitude) async {
    selectedAddress.value = address;

    // Try to get coordinates from the address
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        selectedLatitude = locations[0].latitude;
        selectedLongitude = locations[0].longitude;
        developer.log(
            'Geocoded address to: ${selectedLatitude}, ${selectedLongitude}');
      }
    } catch (e) {
      developer.log('Geocoding failed: $e', error: e);
      // Reset coordinates if geocoding fails
      selectedLatitude = 0.0;
      selectedLongitude = 0.0;
    }
  }

// Add a method to launch maps with specific address
  Future<void> openInMaps(String address,
      {double? latitude, double? longitude}) async {
    try {
      String mapUrl;

      if (latitude != null &&
          longitude != null &&
          latitude != 0 &&
          longitude != 0) {
        // Use coordinates if available
        mapUrl =
            'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
      } else {
        // Use address string
        mapUrl =
            'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
      }

      if (await canLaunchUrl(Uri.parse(mapUrl))) {
        await launchUrl(Uri.parse(mapUrl),
            mode: LaunchMode.externalApplication);
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
  // Add this method to your OrderController class

  Future<bool> deleteOrder(String orderId) async {
    try {
      isLoading.value = true;
      developer.log('Permanently deleting order: $orderId');

      // Call the repository to delete the order
      final success = await orderRepository.deleteOrder(orderId);

      if (success) {
        // Remove the deleted order from both userOrders and allOrders lists
        userOrders.removeWhere((order) => order.id == orderId);
        allOrders.removeWhere((order) => order.id == orderId);

        // Clear the current order if it matches the deleted order
        if (currentOrder.value?.id == orderId) {
          currentOrder.value = null;
        }

        Get.snackbar(
          'Succès',
          'Commande supprimée définitivement',
          duration: const Duration(seconds: 3),
        );

        developer.log('Order permanently deleted successfully');
      } else {
        Get.snackbar(
          'Erreur',
          'Impossible de supprimer définitivement la commande',
          duration: const Duration(seconds: 3),
        );

        developer.log('Failed to delete order');
      }

      return success;
    } catch (e) {
      developer.log('Error deleting order: $e', error: e);

      String errorMessage =
          'Une erreur est survenue lors de la suppression définitive de la commande.';

      if (e.toString().contains('timed out') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
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
}
