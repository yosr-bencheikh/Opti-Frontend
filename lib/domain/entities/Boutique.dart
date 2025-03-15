class Opticien {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final String phone;
  final String email;
  final String description;
  final String opening_hours;
  
  Opticien({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville, // New field
    required this.phone,
    required this.email,
    required this.description,
    required this.opening_hours,
  });
  
  factory Opticien.fromJson(Map<String, dynamic> json) {
    return Opticien(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '', // New field
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      opening_hours: json['opening_hours'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'adresse': adresse,
      'ville': ville, // New field
      'phone': phone,
      'email': email,
      'description': description,
      'opening_hours': opening_hours,
    };
  }
}