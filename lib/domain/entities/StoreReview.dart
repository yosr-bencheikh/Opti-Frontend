class StoreReview {
  final String id;
  final String boutiqueId;
  final String customerId;
  final String customerName;
  final String? customerAvatar;
  final String reviewText;
  final int rating;
  final DateTime timestamp;

  StoreReview({
    required this.id,
    required this.boutiqueId,
    required this.customerId,
    required this.customerName,
    this.customerAvatar,
    required this.reviewText,
    required this.rating,
    required this.timestamp,
  });
factory StoreReview.fromJson(Map<String, dynamic> json) {
  // Handle both customerId and userId fields
  final dynamic userData = json['customerId'] ?? json['userId'];

  // Extract user information safely
  final String customerId;
  final String customerName;
  final String? customerAvatar;

  if (userData is Map<String, dynamic>) {
    customerId = userData['_id']?.toString() ?? '';
    // Try all possible name field combinations
    customerName = userData['name']?.toString() ?? 
                  userData['nom']?.toString() ?? 
                  userData['prenom']?.toString() ?? 
                  (userData['prenom']?.toString() != null && userData['nom']?.toString() != null ? 
                    "${userData['prenom']} ${userData['nom']}" : 
                    userData['username']?.toString()) ?? 
                  'Unknown Customer';
    customerAvatar = userData['avatarUrl']?.toString() ?? 
                    userData['avatar']?.toString();
  } else {
    customerId = userData?.toString() ?? '';
    customerName = 'Unknown Customer';
    customerAvatar = null;
  }

  return StoreReview(
    id: json['_id']?.toString() ?? '',
    boutiqueId: json['boutiqueId']?.toString() ?? '',
    customerId: customerId,
    customerName: customerName,
    customerAvatar: customerAvatar,
    reviewText: json['reviewText']?.toString() ?? '',
    rating: (json['rating'] as num?)?.toInt() ?? 0,
    timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
  );
}
}
