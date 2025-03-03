class Review {
  final String id;
  final String productId;
  final String userId;
  final String reviewText;
  final int rating;
  final DateTime timestamp;

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });

  // Factory method to create a Review object from JSON
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'], // Handle both '_id' and 'id' fields
      productId: json['productId'],
      userId: json['userId'],
      reviewText: json['reviewText'],
      rating: json['rating'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Method to convert a Review object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productId': productId,
      'userId': userId,
      'reviewText': reviewText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}