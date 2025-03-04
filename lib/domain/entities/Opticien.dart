class Opticien {
  final String id;
  final String nom;
  final String adresse;
  final String phone; // Changed from `telephone` to `phone`
  final String email;
  final String description;
  final String opening_hours; // Changed from `openingHours` to `opening_hours`

  Opticien({
    required this.id,
    required this.nom,
    required this.adresse,
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
      phone: json['phone'] ?? '', // Changed from `telephone` to `phone`
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      opening_hours: json['opening_hours'] ?? '', // Changed from `openingHours` to `opening_hours`
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'adresse': adresse,
      'phone': phone, // Changed from `telephone` to `phone`
      'email': email,
      'description': description,
      'opening_hours': opening_hours, // Changed from `openingHours` to `opening_hours`
    };
  }
}