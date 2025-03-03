import 'package:equatable/equatable.dart';

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
  ];

  // Factory method to create Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse items from JSON
    List<OrderItem> items = [];
    if (json['items'] != null) {
      if (json['items'] is List) {
        items = (json['items'] as List)
            .map((item) => OrderItem.fromJson(item))
            .toList();
      }
    }

    // Parse dates
    DateTime createdAt;
    DateTime updatedAt;
    
    try {
      createdAt = json['createdAt'] != null
          ? json['createdAt'] is String
              ? DateTime.parse(json['createdAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.now();
      
      updatedAt = json['updatedAt'] != null
          ? json['updatedAt'] is String
              ? DateTime.parse(json['updatedAt'])
              : DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.now();
    } catch (e) {
      print('Error parsing dates: $e');
      createdAt = DateTime.now();
      updatedAt = DateTime.now();
    }

    return Order(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      items: items,
      subtotal: (json['subtotal'] is int) 
          ? (json['subtotal'] as int).toDouble() 
          : json['subtotal'],
      deliveryFee: (json['deliveryFee'] is int) 
          ? (json['deliveryFee'] as int).toDouble() 
          : json['deliveryFee'],
      total: (json['total'] is int) 
          ? (json['total'] as int).toDouble() 
          : json['total'],
      address: json['address'],
      paymentMethod: json['paymentMethod'],
      status: json['status'] ?? 'En attente',
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  // Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
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

  // Create a copy of Order with some fields replaced
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

  const OrderItem({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [
    productId,
    productName,
    productImage,
    quantity,
    unitPrice,
    totalPrice,
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
    };
  }
}