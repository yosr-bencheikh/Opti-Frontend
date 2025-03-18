import 'package:equatable/equatable.dart';
import 'package:opti_app/domain/entities/Boutique.dart';

class Order extends Equatable {
  final String? id;
  final String userId;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String address;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? boutiqueId;
  final Opticien? boutique;

  const Order({
    this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.address,
    required this.paymentMethod,
    this.status = 'En attente',
    required this.createdAt,
    required this.updatedAt,
    this.boutiqueId,
    this.boutique,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        subtotal,
        deliveryFee,
        total,
        address,
        paymentMethod,
        status,
        createdAt,
        updatedAt,
        boutiqueId,
        boutique,
      ];
  factory Order.fromJson(Map<String, dynamic> json) {
    // Check if the data is nested inside a 'data' field
    final orderData = json.containsKey('data') ? json['data'] : json;

    return Order(
      id: orderData['_id'],
      userId: orderData['userId'],
      boutiqueId:
          orderData['opticienId'], // Use opticienId instead of boutiqueId
      items: (orderData['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      subtotal: (orderData['subtotal'] as num).toDouble(),
      deliveryFee: (orderData['deliveryFee'] as num).toDouble(),
      total: (orderData['total'] as num).toDouble(),
      address: orderData['address'],
      paymentMethod: orderData['paymentMethod'],
      status: orderData['status'] ?? 'En attente',
      createdAt: DateTime.parse(orderData['createdAt']),
      updatedAt: DateTime.parse(orderData['updatedAt']),
    );
  } // Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'boutiqueId': boutiqueId,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'address': address,
      'paymentMethod': paymentMethod,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Add the copyWith method
  Order copyWith({
    String? id,
    String? userId,
    List<OrderItem>? items,
    double? subtotal,
    double? deliveryFee,
    double? total,
    String? address,
    String? paymentMethod,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? boutiqueId,
    Opticien? boutique,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      address: address ?? this.address,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      boutiqueId: boutiqueId ?? this.boutiqueId,
      boutique: boutique ?? this.boutique,
    );
  }
}

class OrderItem extends Equatable {
  final String productId;
  final String productName;
  final String productImage;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String opticienId; // Added field

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.opticienId, // Added to constructor
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        productImage,
        quantity,
        unitPrice,
        totalPrice,
        opticienId, // Added to props
      ];

  // Factory method to create OrderItem from JSON
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      productName: json['productName'],
      productImage: json['productImage'],
      quantity: json['quantity'],
      unitPrice: (json['unitPrice'] is int)
          ? (json['unitPrice'] as int).toDouble()
          : json['unitPrice'],
      totalPrice: (json['totalPrice'] is int)
          ? (json['totalPrice'] as int).toDouble()
          : json['totalPrice'],
      opticienId: json['opticienId'] ?? '', // Provide default value if null
    );
  }
  // Convert OrderItem to JSON
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'opticienId': opticienId, // Added serialization
    };
  }
}
