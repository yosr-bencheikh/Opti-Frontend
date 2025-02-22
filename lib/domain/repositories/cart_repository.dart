import '../entities/Cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems();
  Future<CartItem> addToCart(CartItem item);
  Future<CartItem> updateQuantity(String id, int quantity);
  Future<void> removeFromCart(String id);
  Future<void> clearCart();
}
