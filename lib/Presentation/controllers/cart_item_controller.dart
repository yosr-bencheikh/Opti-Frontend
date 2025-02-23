import 'package:get/get.dart';
import 'package:opti_app/data/repositories/cart_item_repository_impl.dart';
import '../../domain/entities/Cart_item.dart';
import '../../domain/repositories/product_repository.dart';
import 'auth_controller.dart'; // Par exemple pour récupérer l'userId

class CartItemController extends GetxController {
  final CartItemRepositoryImpl repository;
  final ProductRepository productRepository;
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxBool isLoading = false.obs;

  CartItemController({
    required this.repository,
    required this.productRepository,
  });

  /// Création d'un article dans le panier
  Future<void> createCartItem({
    required String userId,
    required String productId,
    required int quantity,
    required double totalPrice,
  }) async {
    try {
      isLoading(true);
      print('Creating cart item...');
      print('Cart ID: $userId');
      print('Product ID: $productId');
      print('Quantity: $quantity');
      print('Total Price: \$${totalPrice.toStringAsFixed(2)}');

      final cartItem = await repository.createCartItem(
        userId: userId,
        productId: productId,
        quantity: quantity,
        totalPrice: totalPrice,
      );

      cartItems.add(cartItem);
      Get.snackbar('Success', 'Item added to cart');
      print('Cart item created successfully: ${cartItem.toString()}');
    } catch (e) {
      print('Error occurred while creating cart item: $e'); // Log the error
      Get.snackbar('Error',
          'Failed to add item to cart: ${e.toString()}'); // Include error details in the snackbar
    } finally {
      isLoading(false);
      print('Loading state set to false');
    }
  }

  Future<void> loadCartItems(String userId) async {
    try {
      isLoading(true);
      final items = await repository.getCartItems(userId);
      cartItems.assignAll(items);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load cart items');
    } finally {
      isLoading(false);
    }
  }

  Future<String> getProductName(String productId) async {
    try {
      final product = await productRepository.getProductById(productId);
      return product.name;
    } catch (e) {
      return 'Unknown Product';
    }
  }

  Future<String?> getProductImage(String productId) async {
    try {
      final product = await productRepository.getProductById(productId);
      return product.imageUrl;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateCartItem(
      String id, int quantity, double totalPrice) async {
    try {
      isLoading(true);
      final updatedItem =
          await repository.updateCartItem(id, quantity, totalPrice);
      final index = cartItems.indexWhere((item) => item.id == id);
      if (index != -1) {
        cartItems[index] = updatedItem;
        cartItems.refresh();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update item');
    } finally {
      isLoading(false);
    }
  }

  Future<void> deleteCartItem(String id) async {
    try {
      isLoading(true);
      await repository.deleteCartItem(id);
      cartItems.removeWhere((item) => item.id == id);
      Get.snackbar('Success', 'Item removed from cart');
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove item');
    } finally {
      isLoading(false);
    }
  }
}
