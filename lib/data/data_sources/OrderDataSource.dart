import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

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
  final String baseUrl = "http://192.168.1.22:3000";
  OrderDataSourceImpl({required this.client});
  
  
@override
Future<Map> createOrder(Map orderData) async {
  try {
    developer.log('Creating order with data: ${jsonEncode(orderData)}');
    developer.log('Sending request to: $baseUrl/orders');
    
    final response = await client.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(orderData),
    ).timeout(const Duration(seconds: 15));
    
    developer.log('Response status code: ${response.statusCode}');
    developer.log('Response body: ${response.body}');
    
    // Test if we can make a GET request to retrieve the created order
    try {
      final Map order = json.decode(response.body);
      if (order.containsKey('_id')) {
        final getResponse = await client.get(
          Uri.parse('$baseUrl/orders/${order['_id']}'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        
        developer.log('GET order verification status: ${getResponse.statusCode}');
        developer.log('GET order verification body: ${getResponse.body}');
      }
    } catch (verifyError) {
      developer.log('Error verifying order: $verifyError', error: verifyError);
    }
    
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create order: ${response.statusCode}, ${response.body}');
    }
  } catch (e) {
    developer.log('Error creating order: $e', error: e);
    throw Exception('Failed to create order: $e');
  }
}
  @override
  Future<List<Map>> getUserOrders(String userId) async {
    try {
      
      final response = await client.get(
        Uri.parse('$baseUrl/orders/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((item) => item as Map).toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching orders: $e', error: e);
      throw Exception('Failed to fetch orders: $e');
    }
  }
  
  @override
  Future<Map> getOrderById(String id) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/orders/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch order: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      developer.log('Error fetching order: $e', error: e);
      throw Exception('Failed to fetch order: $e');
    }
  }
  
  @override
  Future<bool> updateOrderStatus(String id, String status) async {
    try {
      final response = await client.patch(
        Uri.parse('$baseUrl/orders/$id/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error updating order status: $e', error: e);
      return false;
    }
  }
  
  @override
  Future<bool> cancelOrder(String id) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/orders/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));
      
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Error cancelling order: $e', error: e);
      return false;
    }
  }
}