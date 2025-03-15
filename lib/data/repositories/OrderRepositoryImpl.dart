import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/domain/entities/Order.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource dataSource;
  

  OrderRepositoryImpl({required this.dataSource});

  @override
  Future<Order> createOrder(Order order) async {
    final result = await dataSource.createOrder(order.toJson());
    return Order.fromJson(
        result.cast<String, dynamic>()); // Cast to Map<String, dynamic>
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    final results = await dataSource.getUserOrders(userId);
    return results
        .map((data) => Order.fromJson(data.cast<String, dynamic>()))
        .toList(); // Cast to Map<String, dynamic>
  }

  @override
  Future<Order> getOrderById(String id) async {
    final result = await dataSource.getOrderById(id);
    return Order.fromJson(
        result.cast<String, dynamic>()); // Cast to Map<String, dynamic>
  }

  @override
  Future<bool> updateOrderStatus(String id, String status,
      {String? cancellationReason}) async {
    return await dataSource.updateOrderStatus(id, status,
        cancellationReason: cancellationReason);
  }

  @override
  Future<bool> cancelOrder(String id) async {
    return await dataSource.cancelOrder(id);
  }

  @override
  Future<List<Order>> getAllOrders() async {
    final results = await dataSource.getAllOrders();
    return results;
  }
    @override
   Future<bool> deleteOrder(String id) async {
    final results = await dataSource.deleteOrder(id);
    return results;
  }
}
