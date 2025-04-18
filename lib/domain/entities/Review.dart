class BoutiqueReview {
  final String id;
  final String boutiqueId;
  final String customerId;
  final String reviewText;
  final int rating;
  final DateTime timestamp;

  BoutiqueReview({
    required this.id,
    required this.boutiqueId,
    required this.customerId,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });

  // Factory method to create a BoutiqueReview object from JSON
  factory BoutiqueReview.fromJson(Map json) {
    return BoutiqueReview(
      id: json['_id'] ?? json['id'], // Handle both '_id' and 'id' fields
      boutiqueId: json['boutiqueId'],
      customerId: json['customerId'],
      reviewText: json['reviewText'],
      rating: json['rating'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  // Method to convert a BoutiqueReview object to JSON
  Map toJson() {
    return {
      'id': id,
      'boutiqueId': boutiqueId,
      'customerId': customerId,
      'reviewText': reviewText,
      'rating': rating,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
