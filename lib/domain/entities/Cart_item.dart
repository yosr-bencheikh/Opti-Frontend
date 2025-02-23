class CartItem {
  final String? id;
  final String userId;
  final String productId;
  final int quantity;
  final double totalPrice;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  CartItem({
    this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.createdAt,
    this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['_id'] ?? json['id'], // Handle both MongoDB _id and regular id
      userId: json['userId'],
      productId: json['productId'],
      quantity: json['quantity'],
      totalPrice: json['totalPrice'].toDouble(),
      createdAt:
          json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'productId': productId,
      'quantity': quantity,
      'totalPrice': totalPrice,
    };
  }
}
