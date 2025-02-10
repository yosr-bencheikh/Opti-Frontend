import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String email,
    String? nom,
    String? prenom,
    required String date,
    required String phone,
    required String password,
    required String region,
    required String genre,
    String? id,
  }) : super(
          email: email,
          nom: nom ?? "", // Provide a default value for nullable fields
          prenom: prenom ?? "",
          date: date,
          region: region,
          genre: genre,
          phone: phone,
          password: password,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      nom: json['nom'],
      prenom: json['prenom'],
      date: json['date'],
      region: json['region'] ?? '',
      genre: json['genre'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '', 
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'date': date,
      'region': region,
      'genre': genre,
      'phone': phone,
      'password': password,
    }..removeWhere((key, value) => value == null); 
  }

  // Optional: Add a method to create a copy of the model with some changes
  UserModel copyWith({
    String? email,
    String? nom,
    String? prenom,
    String? date,
    String? region,
    String? genre,
    String? phone,
    String? password,
    String? photoUrl,
  }) {
    return UserModel(
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      date: date ?? this.date,
      region: region ?? this.region,
      genre: genre ?? this.genre,
      phone: phone ?? this.phone,
      password: password ?? this.password,
    );
  }
}
