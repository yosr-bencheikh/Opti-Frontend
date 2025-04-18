import 'package:shared_preferences/shared_preferences.dart';

class Product {
  String? id;
  String name;
  String description;
  String category;
  String marque;
  List<String> couleur;
  double prix;
  int quantiteStock;
  String image;
  String model3D;
  String? typeVerre;
  String materiel;
  String sexe;
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
    required this.materiel,
    required this.sexe,
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
        model3DValue = json['model3D']['_id']?.toString() ?? '';
      } else {
        model3DValue = json['model3D'].toString();
      }
    }

    // Handle couleur which is now a list
    List<String> couleurList = [];
    if (json['couleur'] != null) {
      if (json['couleur'] is List) {
        couleurList = List<String>.from(json['couleur']);
      } else if (json['couleur'] is String) {
        // Handle case where couleur might be a single string in legacy data
        couleurList = [json['couleur'].toString()];
      }
    }

    final productId = json['_id']?.toString() ?? '';
    
    return Product(
      id: productId,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      marque: json['marque']?.toString() ?? '',
      couleur: couleurList,
      prix: json['prix'] is num ? (json['prix'] as num).toDouble() : 0.0,
      quantiteStock: json['quantite_stock'] ?? 0,
      image: imageUrl ?? '',
      model3D: model3DValue,
      typeVerre: json['type_verre']?.toString() ?? '',
      materiel: json['materiel']?.toString() ?? '',
      sexe: json['sexe']?.toString() ?? 'unisexe',
      boutiqueId: json['boutiqueId']?.toString() ?? '',
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] ?? 0,
      style: json['style']?.toString() ?? '',
    );
  }

  // Load a product with persisted ratings data
  static Future<Product> fromJsonWithPersistedRatings(Map<String, dynamic> json) async {
    Product product = Product.fromJson(json);
    
    if (product.id != null && product.id!.isNotEmpty) {
      await product.loadPersistedRatings();
    }
    
    return product;
  }

  // Load persisted ratings from local storage
  Future<void> loadPersistedRatings() async {
    if (id == null || id!.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final rating = prefs.getDouble('product_rating_$id') ?? 0.0;
    final reviews = prefs.getInt('product_reviews_$id') ?? 0;
    
    averageRating = rating;
    totalReviews = reviews;
  }

  // Save ratings to local storage
  Future<void> saveRatings() async {
    if (id == null || id!.isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('product_rating_$id', averageRating);
    await prefs.setInt('product_reviews_$id', totalReviews);
  }

  // Update the ratings and save them to persistence
  Future<void> updateRatings(double newRating, {bool isNewReview = true}) async {
    // Calculate new average rating
    double totalRatingPoints = averageRating * totalReviews;
    
    if (isNewReview) {
      totalReviews += 1;
    }
    
    totalRatingPoints += newRating;
    averageRating = totalReviews > 0 ? totalRatingPoints / totalReviews : 0;
    
    // Save to local persistence
    await saveRatings();
  }

  static String? _constructImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return null;
    }

    if (imagePath.startsWith('http')) {
      return imagePath;
    }

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
      'materiel': materiel,
      'sexe': sexe,
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
    List<String>? couleur,
    double? prix,
    int? quantiteStock,
    String? image,
    String? typeVerre,
    String? materiel,
    String? sexe,
    String? boutiqueId,
    double? averageRating,
    int? totalReviews,
    String? style,
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
      boutiqueId: boutiqueId ?? this.boutiqueId,
      averageRating: averageRating ?? this.averageRating,
      materiel: materiel ?? this.materiel,
      sexe: sexe ?? this.sexe,
      totalReviews: totalReviews ?? this.totalReviews,
      style: style ?? this.style,
    );
  }
}