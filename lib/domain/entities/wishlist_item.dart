import 'package:equatable/equatable.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class WishlistItem extends Equatable {
  final String id;
  final Product product;
  final String userId;
  final String productId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WishlistItem({
    required this.id,
    required this.product,
    required this.userId,
    required this.productId,
    this.createdAt,
    this.updatedAt,
  });

factory WishlistItem.fromJson(Map<String, dynamic> json) {
  try {
    return WishlistItem(
      id: json['_id']?.toString() ?? '', // Valeur par défaut si null
      product: Product.fromJson(json['productId'] as Map<String, dynamic>),
      userId: json['userId']?.toString() ?? '', // Valeur par défaut si null
      productId: (json['productId'] as Map<String, dynamic>)['_id']?.toString() ?? '', // Valeur par défaut si null
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  } catch (e, stackTrace) {
    print('Error parsing WishlistItem: $json');
    print('Error details: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
}
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productId': productId,
      'userId': userId,
      'product': product,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, product, userId, productId, createdAt, updatedAt];
}