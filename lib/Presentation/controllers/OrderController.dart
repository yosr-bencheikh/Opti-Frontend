import 'package:get/get.dart';
import 'package:opti_app/Domain/Entities/order.dart';
import 'package:opti_app/Domain/Entities/cart_item.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/domain/entities/product_entity.dart';
import 'package:opti_app/domain/usecases/OrderUseCase.dart';
import 'package:opti_app/domain/entities/cart_item.dart';

class OrderController extends GetxController {
  final CreateOrderUseCase createOrderUseCase;
  final GetUserOrdersUseCase getUserOrdersUseCase;
  final GetOrderByIdUseCase getOrderByIdUseCase;
  final UpdateOrderStatusUseCase updateOrderStatusUseCase;
  final CancelOrderUseCase cancelOrderUseCase;
  
  OrderController({
    required this.createOrderUseCase,
    required this.getUserOrdersUseCase,
    required this.getOrderByIdUseCase,
    required this.updateOrderStatusUseCase,
    required this.cancelOrderUseCase,
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
    
    // Préparer les éléments de la commande à partir du panier
    final List<OrderItem> orderItems = [];
    double subtotal = 0;
    
    // Utilisez .value pour accéder à la liste sous-jacente
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
    
    // Envoyer la commande au serveur
    final createdOrder = await createOrderUseCase(order);
    currentOrder.value = createdOrder;
    
    // Vider le panier après une commande réussie
    // await cartController.clearCart(userId);
    
    Get.snackbar(
      'Succès', 
      'Votre commande a été confirmée avec succès',
      duration: const Duration(seconds: 3),
    );
    
  } catch (e) {
    Get.snackbar(
      'Erreur', 
      'Une erreur est survenue lors de la création de la commande: $e',
      duration: const Duration(seconds: 3),
    );
  } finally {
    isCreating.value = false;
  }
}
  Future<void> loadUserOrders(String userId) async {
    try {
      isLoading.value = true;
      final orders = await getUserOrdersUseCase(userId);
      userOrders.value = orders;
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Une erreur est survenue lors du chargement des commandes: $e',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> getOrderDetails(String orderId) async {
    try {
      isLoading.value = true;
      final order = await getOrderByIdUseCase(orderId);
      currentOrder.value = order;
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Une erreur est survenue lors du chargement des détails de la commande: $e',
        duration: const Duration(seconds: 3),
      );
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<bool> cancelOrder(String orderId) async {
    try {
      isLoading.value = true;
      final success = await cancelOrderUseCase(orderId);
      
      if (success) {
        // Mettre à jour l'affichage
        await loadUserOrders(userOrders.first.userId);
        Get.snackbar(
          'Succès', 
          'Commande annulée avec succès',
          duration: const Duration(seconds: 3),
        );
      } else {
        Get.snackbar(
          'Erreur', 
          'Impossible d\'annuler la commande',
          duration: const Duration(seconds: 3),
        );
      }
      
      return success;
    } catch (e) {
      Get.snackbar(
        'Erreur', 
        'Une erreur est survenue lors de l\'annulation de la commande: $e',
        duration: const Duration(seconds: 3),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }
  
  void setAddress(String address) {
    selectedAddress.value = address;
  }
  
  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
  }
}