import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/Cart_item.dart';

abstract class CartDataSource {
  Future<List<CartItem>> getCartItems();
  Future<CartItem> addToCart(CartItem item);
  Future<CartItem> updateQuantity(String id, int quantity);
  Future<void> removeFromCart(String id);
  Future<void> clearCart();
}

class CartDataSourceImpl implements CartDataSource {
  final http.Client client;

  // Use your server's IP and port (make sure this is accessible from your phone)
  final String baseUrl = 'http://192.168.1.19:3000/api';

  CartDataSourceImpl({required this.client});

  @override
  Future<List<CartItem>> getCartItems() async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/cart'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => CartItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load cart items: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to load cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartItem> addToCart(CartItem item) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(item.toJson()),
      );
      if (response.statusCode == 201) {
        return CartItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add item to cart: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to add item to cart: ${e.toString()}');
    }
  }

  @override
  Future<CartItem> updateQuantity(String id, int quantity) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/cart/$id/quantity'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      );
      if (response.statusCode == 200) {
        return CartItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update quantity: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to update quantity: ${e.toString()}');
    }
  }

  @override
  Future<void> removeFromCart(String id) async {
    try {
      final response = await client.delete(Uri.parse('$baseUrl/cart/$id'));
      if (response.statusCode != 204) {
        throw Exception(
            'Failed to remove item from cart: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to remove item from cart: ${e.toString()}');
    }
  }

  @override
  Future<void> clearCart() async {
    try {
      final response = await client.delete(Uri.parse('$baseUrl/cart'));
      if (response.statusCode != 204) {
        throw Exception('Failed to clear cart: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Failed to clear cart: ${e.toString()}');
    }
  }
}
