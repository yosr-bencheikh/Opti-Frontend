import 'dart:convert';
import 'package:http/http.dart' as http;

// Abstract class defining order data source operations
abstract class OrderDataSource {
  Future<Map> createOrder(Map orderData);
  Future<List<Map>> getUserOrders(String userId);
  Future<Map> getOrderById(String id);
  Future<bool> updateOrderStatus(String id, String status);
  Future<bool> cancelOrder(String id);
}

// Implementation of the OrderDataSource interface
class OrderDataSourceImpl implements OrderDataSource {
  final http.Client client;
  final String baseUrl = "http://localhost:3000";
  
  OrderDataSourceImpl({required this.client});
  
  @override
  Future<Map> createOrder(Map orderData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(orderData),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec de création de la commande: ${response.body}');
    }
  }
  
  @override
  Future<List<Map>> getUserOrders(String userId) async {
    final response = await client.get(
      Uri.parse('$baseUrl/orders/user/$userId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((item) => item as Map).toList();
    } else {
      throw Exception('Échec de récupération des commandes: ${response.body}');
    }
  }
  
  @override
  Future<Map> getOrderById(String id) async {
    final response = await client.get(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Échec de récupération de la commande: ${response.body}');
    }
  }
  
  @override
  Future<bool> updateOrderStatus(String id, String status) async {
    final response = await client.patch(
      Uri.parse('$baseUrl/orders/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
    return response.statusCode == 200;
  }
  
  @override
  Future<bool> cancelOrder(String id) async {
    final response = await client.delete(
      Uri.parse('$baseUrl/orders/$id'),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }
}