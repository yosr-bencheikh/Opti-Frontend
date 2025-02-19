import '../../domain/entities/user.dart';

class UserModel extends User {
  // Removed 'const' from the constructor
  UserModel({
    required super.email,
    required super.date,
    required super.phone,
    required super.password,
    required super.region,
    required super.genre,
    String? nom,
    String? prenom,
    String? imageUrl,
    String? refreshTokens,
    String? id,
  }) : super(
          nom: nom ?? "", // Provide a default value for nullable fields
          prenom: prenom ?? "",
          imageUrl: imageUrl ?? '', // Pass imageUrl to the superclass
          refreshTokens:
              refreshTokens ?? '', // Pass refreshTokens to the superclass
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
      imageUrl: json['imageUrl'] ?? '', // Include imageUrl in the factory
      refreshTokens:
          json['refreshTokens'] ?? '', // Include refreshTokens in the factory
    );
  }

  @override
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
      'imageUrl': imageUrl, // Include imageUrl in the toJson
      'refreshTokens': refreshTokens, // Include refreshTokens in the toJson
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
    String? imageUrl,
    String? refreshTokens,
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
      imageUrl: imageUrl ?? this.imageUrl, // Include imageUrl in copyWith
      refreshTokens: refreshTokens ??
          this.refreshTokens, // Include refreshTokens in copyWith
    );
  }
}
