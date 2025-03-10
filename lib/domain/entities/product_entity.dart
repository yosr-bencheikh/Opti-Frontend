class Product {
  String? id;
  String name;
  String description;
  String category;
  String marque;
  String couleur;
  double prix;
  int quantiteStock;
  String image;
  String? typeVerre;
  String opticienId;
  double averageRating;
  int totalReviews;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.marque,
    required this.couleur,
    required this.prix,
    required this.quantiteStock,
    this.image = "",
    this.typeVerre,
    required this.opticienId,
    required this.averageRating,
    required this.totalReviews,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageUrl = _constructImageUrl(json['image'] ?? json['imageUrl']);
    print('Parsed imageUrl: $imageUrl'); // Debug log

    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      couleur: json['couleur']?.toString() ?? '',
      prix: json['prix'].toDouble() ?? 0.0,
      quantiteStock: json['quantite_stock'] ?? 0,
      image: imageUrl ?? '', // Use the constructed image URL
      typeVerre: json['type_verre']?.toString() ?? '',
      opticienId: json['opticienId']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
    );
  }

  static String? _constructImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    // If it's already a full URL, return it
    if (imagePath.startsWith('http')) {
      return imagePath;
    }

    // Otherwise, construct the full URL
    return 'http://localhost:3000/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'category': category,
      'marque': marque,
      'couleur': couleur,
      'prix': prix,
      'quantite_stock': quantiteStock,
      'image': image,
      'type_verre': typeVerre,
      'opticienId': opticienId,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? marque,
    String? couleur,
    double? prix,
    int? quantiteStock,
    String? image,
    String? typeVerre,
    String? opticienId,
    double? averageRating,
    int? totalReviews,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      marque: marque ?? this.marque,
      couleur: couleur ?? this.couleur,
      prix: prix ?? this.prix,
      quantiteStock: quantiteStock ?? this.quantiteStock,
      image: image ?? this.image,
      typeVerre: typeVerre ?? this.typeVerre,
      opticienId: opticienId ?? this.opticienId,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
    );
  }
}