
import 'package:opti_app/domain/entities/Cart_item.dart';

abstract class CartItemRepository {
  Future<CartItem> createCartItem({
    required String cartId,
    required String productId,
    required int quantity,
    required double totalPrice,
  });
  Future<List<CartItem>> getCartItems(String userId);
  Future<CartItem> updateCartItem(String id, int quantity, double totalPrice);
  Future<void> deleteCartItem(String id);
  Future<void> clearCartItems(String userId);
}
