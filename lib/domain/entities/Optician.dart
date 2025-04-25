import 'package:equatable/equatable.dart';

class Optician extends Equatable {
  String? id; // Make id optional
  String nom;
  String prenom;
  String date;
  String genre;
  final String password;
  String address;
  String email;
  String phone;
  String region;
  String imageUrl;
  String status;

  Optician({
    this.id,
    required this.nom,
    required this.prenom,
    required this.date,
    required this.genre,
    required this.password, // Fixed: Added a comma here
    required this.address,
    required this.email,
    required this.phone,
    required this.region,
    this.imageUrl = '',
    this.status = 'Inactive',
  });

  factory Optician.fromJson(Map<String, dynamic> json) {
    return Optician(
      id: json['id'] ?? json['_id'], // Handle id from JSON, can be null
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      date: json['date'] ?? '',
      genre: json['genre'] ?? '',
      password: json['password'] ?? '',
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      region: json['region'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'Inactive',
    );
  }

  @override
  List<Object?> get props => [
        id, // Include id in the props, can be null
        nom,
        prenom,
        date,
        genre,
        password,
        address,
        email,
        phone,
        region,
        imageUrl,
        status,
      ];

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in the JSON output, can be null
      'nom': nom,
      'prenom': prenom,
      'date': date,
      'genre': genre,
      'password': password,
      'address': address,
      'email': email,
      'phone': phone,
      'region': region,
      'imageUrl': imageUrl,
      'status': status,
    };
  }

  Optician copyWith({
    String? id,
    String? nom,
    String? prenom,
    String? email,
    String? date,
    String? genre,
    String? password,
    String? phone,
    String? region,
    String? address,
    String? status,
    String? imageUrl,
  }) {
    return Optician(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      date: date ?? this.date,
      genre: genre ?? this.genre,
      password: password ?? this.password,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      address: address ?? this.address,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
