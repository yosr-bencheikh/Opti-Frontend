import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String? id;
  final String nom;
  final String prenom;
  final String email;
  final String? password;
  final String? image;
  final String role;
  final String? oAuth;
  final String? gender;
  final String? birthDate;

  const User(
      {this.id,
      required this.birthDate,
      required this.gender,
      required this.oAuth,
      required this.image,
      required this.role,
      required this.nom,
      required this.prenom,
      required this.email,
      this.password});

  @override
  List<Object?> get props =>
      [nom, prenom, email, password, id, role, image, oAuth, gender, birthDate];
}
