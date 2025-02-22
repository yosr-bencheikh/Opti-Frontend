import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../domain/entities/Cart_item.dart';

abstract class CartItemDataSource {
  Future<CartItem> createCartItem(CartItem cartItem);
  Future<List<CartItem>> getCartItems(String userId);
  Future<CartItem> updateCartItem(String id, int quantity, double totalPrice);
  Future<void> deleteCartItem(String id);
}

class CartItemDataSourceImpl implements CartItemDataSource {
  final http.Client client;
  final String baseUrl = 'http://192.168.0.104:3000/api';

  CartItemDataSourceImpl({required this.client});

  @override
  Future<CartItem> createCartItem(CartItem cartItem) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/cart'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(cartItem.toJson()),
      );
      if (response.statusCode == 201) {
        return CartItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create cart item');
      }
    } catch (e) {
      throw Exception('Failed to create cart item: ${e.toString()}');
    }
  }

  @override
  Future<List<CartItem>> getCartItems(String userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/cart-items?userId=$userId'),
      );
      if (response.statusCode == 200) {
        return (json.decode(response.body) as List)
            .map((item) => CartItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Failed to get cart items');
      }
    } catch (e) {
      throw Exception('Failed to get cart items: ${e.toString()}');
    }
  }

  @override
  Future<CartItem> updateCartItem(
      String id, int quantity, double totalPrice) async {
    try {
      final response = await client.put(
        Uri.parse('$baseUrl/cart-items/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quantity': quantity,
          'totalPrice': totalPrice,
        }),
      );
      if (response.statusCode == 200) {
        return CartItem.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update cart item');
      }
    } catch (e) {
      throw Exception('Failed to update cart item: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCartItem(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/cart-items/$id'),
      );
      if (response.statusCode != 204) {
        throw Exception('Failed to delete cart item');
      }
    } catch (e) {
      throw Exception('Failed to delete cart item: ${e.toString()}');
    }
  }
}
