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

  factory Boutique.fromJson(Map<String, dynamic> json) {
 print('Full JSON data: $json');
  print('opticien_id: ${json['opticien_id']}');
  print('opticien_nom: ${json['opticien_nom']}');
      String? extractOpticienNom() {
  // Check if opticien_nom is directly provided
  if (json['opticien_nom'] != null) {
    return json['opticien_nom'].toString();
  }

  // Check if opticien_id is an object with a name
  if (json['opticien_id'] != null) {
    if (json['opticien_id'] is Map) {
      // Try multiple ways to extract the name
      return json['opticien_id']['nom'] ?? 
             json['opticien_id']['name'] ?? 
             json['opticien_id']['prenom'] ?? 
             'Unknown';
    } else if (json['opticien_id'] is String) {
      // If it's just an ID, return 'Unknown'
      return 'Unknown';
    }
  }

  return 'Unknown';
}

   return Boutique(
      id: json['_id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      description: json['description'] ?? '',
      opening_hours: json['opening_hours'] ?? '',
      opticien_id: json['opticien_id'] != null 
          ? json['opticien_id'].toString() 
          : null,
      opticien_nom: null, // Set to null explicitly
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