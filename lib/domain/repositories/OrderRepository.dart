import 'package:opti_app/Domain/Entities/order.dart';

abstract class OrderRepository {
  Future<Order> createOrder(Order order);
  Future<List<Order>> getUserOrders(String userId);
  Future<Order> getOrderById(String id);
  Future<bool> updateOrderStatus(String id, String status);
  Future<bool> cancelOrder(String id);
}