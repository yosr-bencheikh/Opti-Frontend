import 'package:opti_app/domain/entities/Order.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';

class CreateOrderUseCase {
  final OrderRepository repository;

  CreateOrderUseCase(this.repository);

  Future<Order> call(Order order) async {
    return await repository.createOrder(order);
  }
}

class GetUserOrdersUseCase {
  final OrderRepository repository;

  GetUserOrdersUseCase(this.repository);

  Future<List<Order>> call(String userId) async {
    return await repository.getUserOrders(userId);
  }
}

class GetOrderByIdUseCase {
  final OrderRepository repository;

  GetOrderByIdUseCase(this.repository);

  Future<Order> call(String id) async {
    return await repository.getOrderById(id);
  }
}

class UpdateOrderStatusUseCase {
  final OrderRepository repository;

  UpdateOrderStatusUseCase(this.repository);

  Future<bool> call(String id, String status) async {
    return await repository.updateOrderStatus(id, status);
  }
}

class CancelOrderUseCase {
  final OrderRepository repository;

  CancelOrderUseCase(this.repository);

  Future<bool> call(String id) async {
    return await repository.cancelOrder(id);
  }
}