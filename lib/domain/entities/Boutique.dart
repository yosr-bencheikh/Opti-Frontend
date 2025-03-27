import 'package:equatable/equatable.dart';

class Boutique extends Equatable {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final String phone;
  final String email;
  final String description;
  final String opening_hours;
  final String? opticien_id;
  final String? opticien_nom;

  Boutique({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.phone,
    required this.email,
    required this.description,
    required this.opening_hours,
    this.opticien_id,
    this.opticien_nom,
  });

  // Méthode helper pour convertir les IDs
  static String? _convertId(dynamic id) {
    if (id == null) return null;
    if (id is Map) return id['\$oid']?.toString(); // Pour les ObjectId MongoDB
    return id.toString();
  }

factory Boutique.fromJson(Map<String, dynamic> json) {
  // Conversion robuste des IDs
  String? parseId(dynamic id) {
    if (id == null) return null;
    if (id is Map) return id['\$oid']?.toString();
    return id.toString();
  }

  return Boutique(
    id: parseId(json['_id']) ?? '',
    nom: json['nom'] ?? '',
    adresse: json['adresse'] ?? '',
    ville: json['ville'] ?? '',
    phone: json['phone']?.toString() ?? '',
    email: json['email'] ?? '',
    description: json['description'] ?? '',
    opening_hours: json['opening_hours'] ?? '',
    opticien_id: parseId(json['opticien_id']), // Conversion garantie
    opticien_nom: json['opticien_nom']?.toString(),
  );
}
  @override
  List<Object?> get props => [
        id,
        nom,
        adresse,
        ville,
        phone,
        email,
        description,
        opening_hours,
        opticien_id,
        opticien_nom,
      ];

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'phone': phone,
      'email': email,
      'description': description,
      'opening_hours': opening_hours,
      'opticien_id': opticien_id,
      'opticien_nom': opticien_nom,
    };
  }
}