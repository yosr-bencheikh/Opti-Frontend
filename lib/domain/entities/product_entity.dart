class Product {
   String? id;
  String name;
  String description;
  String category;
  String marque;
  String couleur;
  double prix;
  int quantiteStock;
  String? imageUrl;
  String? typeVerre;
  String opticienId;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.marque,
    required this.couleur,
    required this.prix,
    required this.quantiteStock,
    this.imageUrl,
    this.typeVerre,
    required this.opticienId,
  });

factory Product.fromJson(Map<String, dynamic> json) {
  final imageUrl = _constructImageUrl(json['image'] ?? json['imageUrl']);
  print('Parsed imageUrl: $imageUrl'); // Ajoutez ce log pour déboguer

  return Product(
    id: json['_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    marque: json['marque']?.toString() ?? '',
    couleur: json['couleur']?.toString() ?? '',
    prix: json['prix'].toDouble() ?? 0.0,
    quantiteStock: json['quantite_stock'] ?? 0,
    imageUrl: imageUrl,
    typeVerre: json['type_verre']?.toString() ?? '',
    opticienId: json['opticienId']?.toString() ?? '',
  );
}
static String? _constructImageUrl(String? imagePath) {
  if (imagePath == null || imagePath.isEmpty) {
    return null;
  }
  
  // Si c'est déjà une URL complète, retournez-la
  if (imagePath.startsWith('http')) {
    return imagePath;
  }
  
  // Sinon, construisez l'URL complète
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
      'image': imageUrl,
      'type_verre': typeVerre,
      'opticienId': opticienId,
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
    String? imageUrl,
    String? typeVerre,
    String? opticienId,
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
      imageUrl: imageUrl ?? this.imageUrl,
      typeVerre: typeVerre ?? this.typeVerre,
      opticienId: opticienId ?? this.opticienId,
    );
  }
}