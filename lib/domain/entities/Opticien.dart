class Opticien {
  final String id;
  final String nom;
  final String adresse;
  final String telephone;
  final String email;
  final String description;
  final String openingHours;

  Opticien({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.telephone,
    required this.email,
    required this.description,
    required this.openingHours,
  });

  factory Opticien.fromJson(Map<String, dynamic> json) {
    return Opticien(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      telephone: json['telephone'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      openingHours: json['opening_hours'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'adresse': adresse,
      'telephone': telephone,
      'email': email,
      'description': description,
      'opening_hours': openingHours,
    };
  }
}
