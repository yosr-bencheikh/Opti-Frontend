import 'dart:convert';

class Cart {
  final String userId;
  final List<String> items; // List of CartItem IDs
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.userId,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a Cart from JSON
  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      userId: json['userId'],
      items: List<String>.from(json['items'].map((item) => item.toString())),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Method to convert Cart to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'items': items,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
