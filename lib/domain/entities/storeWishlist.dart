class StoreWishlist {
  final String customerId; // Assuming the Customer ID is represented as a String
  final String boutiqueId; // Assuming the Boutique ID is represented as a String
  final DateTime createdAt;

  StoreWishlist({
    required this.customerId,
    required this.boutiqueId,
    required this.createdAt,
  });

  // Create an instance from a Map (e.g., from JSON response)
  factory StoreWishlist.fromMap(Map<String, dynamic> map) {
    return StoreWishlist(
      customerId: map['customerId'] as String,
      boutiqueId: map['boutiqueId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  // Convert an instance into a Map (e.g., for JSON encoding)
  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'boutiqueId': boutiqueId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
