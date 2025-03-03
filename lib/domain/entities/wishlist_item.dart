import 'package:equatable/equatable.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class WishlistItem extends Equatable {
  
  
  final String userId;
  final String productId;
  final DateTime? addedAt;
  final DateTime? updatedAt;
  

  const WishlistItem({
    
    
    required this.userId,
    required this.productId,
    this.addedAt,
    this.updatedAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    try {
      return WishlistItem(
        
        
        userId: json['userId']?.toString() ?? '',
        productId: (json['productId'] as Map<String, dynamic>)['_id']?.toString() ?? '',
        addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt'] as String) : null,
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
    
      'productId': productId,
      'userId': userId,
      
      'addedAt': addedAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [  userId, productId, addedAt, updatedAt];
}