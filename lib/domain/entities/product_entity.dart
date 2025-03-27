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
  String model3D; // This can now be either a model ID or a filepath
  String? typeVerre;
  String boutiqueId;
  double averageRating;
  int totalReviews;
  String style;

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
    this.model3D = '',
    this.typeVerre,
    this.boutiqueId = "",
    required this.averageRating,
    required this.totalReviews,
    required this.style,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageUrl = _constructImageUrl(json['image'] ?? json['imageUrl']);
    
    // Handle model3D which could be an ObjectId string, a URL string, or null
    String model3DValue = '';
    if (json['model3D'] != null) {
      if (json['model3D'] is Map) {
        // If it's a populated mongoose reference
        model3DValue = json['model3D']['_id']?.toString() ?? '';
      } else {
        // If it's a string ID or path
        model3DValue = json['model3D'].toString();
      }
    }

    return Product(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      couleur: json['couleur']?.toString() ?? '',
      prix: json['prix'] is num ? (json['prix'] as num).toDouble() : 0.0,
      quantiteStock: json['quantite_stock'] ?? 0,
      image: imageUrl ?? '',
      model3D: model3DValue,
      typeVerre: json['type_verre']?.toString() ?? '',
      boutiqueId: json['boutiqueId']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      style: json['style']?.toString() ?? '',
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
      'model3D': model3D,
      'type_verre': typeVerre,
      'boutiqueId': boutiqueId,
      'totalReviews': totalReviews,
      'averageRating': averageRating,
      'style': style,
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
    String? boutiqueId, // Added to copyWith
    double? averageRating,
    int? totalReviews,
    String? style, // Ajout du paramètre style dans copyWith
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
      boutiqueId: boutiqueId ?? this.boutiqueId, // Handle in copyWith
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      style: style ?? this.style, // Mettre à jour la valeur de style
    );
  }
}
