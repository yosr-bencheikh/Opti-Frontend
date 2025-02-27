import 'package:opti_app/Domain/Entities/order.dart';
import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderDataSource dataSource;

  OrderRepositoryImpl({required this.dataSource});

  @override
  Future<Order> createOrder(Order order) async {
    final result = await dataSource.createOrder(order.toJson());
    return Order.fromJson(result);
  }

  @override
  Future<List<Order>> getUserOrders(String userId) async {
    final results = await dataSource.getUserOrders(userId);
    return results.map((data) => Order.fromJson(data)).toList();
  }

  @override
  Future<Order> getOrderById(String id) async {
    final result = await dataSource.getOrderById(id);
    return Order.fromJson(result);
  }

  @override
  Future<bool> updateOrderStatus(String id, String status) async {
    return await dataSource.updateOrderStatus(id, status);
  }

  @override
  Future<bool> cancelOrder(String id) async {
    return await dataSource.cancelOrder(id);
  }
}