import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String nom;
  final String prenom;
  final String email;
  final String date;
  final String region;
  final String genre;
  final String password;
  final String phone;
  final String imageUrl;
  final String refreshTokens;

  const User({
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
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      date: json['date'],
      region: json['region'],
      genre: json['genre'],
      password: json['password'] ?? '',
      phone: json['phone'],
      imageUrl: json['imageUrl'] ?? '',
      refreshTokens: json['refreshTokens'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
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
      ];

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'date': date,
      'region': region,
      'genre': genre,
      'password': password,
      'phone': phone,
      'imageUrl': imageUrl,
      'refreshTokens': refreshTokens,
    };
  }
}
