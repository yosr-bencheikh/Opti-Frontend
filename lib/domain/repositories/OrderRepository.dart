import 'package:opti_app/domain/entities/Order.dart';

abstract class OrderRepository {
  Future<Order> createOrder(Order order);
  Future<List<Order>> getUserOrders(String userId);
  Future<Order> getOrderById(String id);
  Future<bool> updateOrderStatus(String id, String status,
      {String? cancellationReason});
  Future<bool> cancelOrder(String id);
  Future<List<Order>> getAllOrders();
  Future<bool> deleteOrder(String id);
}
