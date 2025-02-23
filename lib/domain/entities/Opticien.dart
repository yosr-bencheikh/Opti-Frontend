class Opticien {
  final String id;
  final String nom;
  final String adresse;
  final String phone;
  final String email;
  final String description;
  final String openingHours;

  Opticien({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.phone,
    required this.email,
    required this.description,
    required this.openingHours,
  });

  factory Opticien.fromJson(Map<String, dynamic> json) {
    return Opticien(
      id: json['_id'] ?? '',
      nom: json['nom'] ?? '',
      adresse: json['addresse'] ?? '',
      phone: json['phone'] ?? '',
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
      'phone': phone,
      'email': email,
      'description': description,
      'opening_hours': openingHours,
    };
  }
}
