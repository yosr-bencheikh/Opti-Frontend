import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    String? id, // Make id optional
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
    String? status, // Correctly define status as a String?
  }) : super(
          id: id, // Pass id to the superclass
          nom: nom ?? "", // Provide a default value for nullable fields
          prenom: prenom ?? "",
          imageUrl: imageUrl ?? '', // Pass imageUrl to the superclass
          refreshTokens: refreshTokens ?? '', // Pass refreshTokens to the superclass
          status: status ?? 'Inactive', // Pass status to the superclass with a default value
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? json['_id'], // Handle id from JSON, can be null
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      date: json['date'] ?? '',
      region: json['region'] ?? '',
      genre: json['genre'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      imageUrl: json['imageUrl'] ?? '', 
      refreshTokens: json['refreshTokens'] ?? '', 
      status: json['status'] ?? 'Inactive', // Correctly assign status from JSON
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Include id in the toJson, can be null
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
      'status': status, // Include status in the toJson
    }..removeWhere((key, value) => value == null);
  }

  // Convert UserModel to User entity
  User toEntity() {
    return User(
      id: id, // Include id in the conversion, can be null
      nom: nom,
      prenom: prenom,
      email: email,
      date: date,
      region: region,
      genre: genre,
      password: password,
      phone: phone,
      imageUrl: imageUrl,
      refreshTokens: refreshTokens,
      status: status, // Include status in the conversion
    );
  }

  // Create UserModel from User entity
  static UserModel fromEntity(User user) {
    return UserModel(
      id: user.id, // Include id in the conversion, can be null
      email: user.email,
      nom: user.nom,
      prenom: user.prenom,
      date: user.date,
      region: user.region,
      genre: user.genre,
      phone: user.phone,
      password: user.password,
      imageUrl: user.imageUrl,
      refreshTokens: user.refreshTokens,
      status: user.status, // Include status in the conversion
    );
  }

  // Optional: Add a method to create a copy of the model with some changes
  UserModel copyWith({
    String? id, // Include id in copyWith, can be null
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
    String? status, // Include status in copyWith
  }) {
    return UserModel(
      id: id ?? this.id, // Include id in copyWith, can be null
      email: email ?? this.email,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      date: date ?? this.date,
      region: region ?? this.region,
      genre: genre ?? this.genre,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      imageUrl: imageUrl ?? this.imageUrl, // Include imageUrl in copyWith
      refreshTokens: refreshTokens ?? this.refreshTokens, // Include refreshTokens in copyWith
      status: status ?? this.status, // Include status in copyWith
    );
  }
}