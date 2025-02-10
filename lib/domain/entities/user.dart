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

  const User({
   
    required this.nom,
    required this.prenom,
    required this.email,
    required this.date,
    required this.region,
    required this.genre,
    required this.password,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      // Handle both '_id' and 'id'
      nom: json['nom'],
      prenom: json['prenom'],
      email: json['email'],
      date: json['date'],
      region: json['region'],
      genre: json['genre'],
      password: json['password'] ?? '', // Adjust based on your needs
      phone: json['phone'],
    );
  }
  
  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();

  toJson() {}
}
