import 'package:equatable/equatable.dart';

class User extends Equatable {
   String? id; // Make id optional
  String nom;
   String prenom;
  String email;
   String date;
   String region;
   String genre;
   String password;
   String phone;
  String imageUrl;
  final String refreshTokens;
  String status;

  User({
    this.id, // Make id optional in the constructor
    required this.nom,
    required this.prenom,
    required this.email,
    required this.date,
    required this.region,
    required this.genre,
    required this.password,
    required this.phone,
    this.imageUrl = '',
    this.refreshTokens = '',
    this.status = 'Inactive',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'], // Handle id from JSON, can be null
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      date: json['date'] ?? '',
      region: json['region'] ?? '',
      genre: json['genre'] ?? '',
      password: json['password'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      refreshTokens: json['refreshToken'] ?? '',
      status: json['status'] ?? 'Inactive',
    );
  }

  @override
  List<Object?> get props => [
    id, // Include id in the props, can be null
    nom,
    prenom,
    email,
    date,
    region,
    genre,
    password,
    phone,
    imageUrl,
    refreshTokens,
    status,
  ];

  get value => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in the JSON output, can be null
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'date': date,
      'region': region,
      'genre': genre,
      'password': password,
      'phone': phone,
      'imageUrl': imageUrl,
      'refreshToken': refreshTokens,
      'status': status,
    };
  }
  User copyWith({
  String? nom,
  String? prenom,
  String? email,
  String? date,
  String? region,
  String? genre,
  String? password,
  String? phone,
  String? status,
  String? imageUrl,
}) {
  return User(
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    email: email ?? this.email,
    date: date ?? this.date,
    region: region ?? this.region,
    genre: genre ?? this.genre,
    password: password ?? this.password,
    phone: phone ?? this.phone,
    status: status ?? this.status,
    imageUrl: imageUrl ?? this.imageUrl,
  );
}
}