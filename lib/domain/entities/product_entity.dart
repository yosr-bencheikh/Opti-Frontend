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
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      marque: json['marque'],
      couleur: json['couleur'],
      prix: json['prix'].toDouble(),
      quantiteStock: json['quantite_stock'],
      image: json['image'],
      typeVerre: json['type_verre'],
    );
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
    );
  }
}
