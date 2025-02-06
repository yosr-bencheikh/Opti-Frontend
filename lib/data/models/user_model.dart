import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String email,
    String? name,
    String? prenom,
    required DateTime date,
    required String region,
    required String genre,
    String? photoUrl,
    String? id,
  }) : super(
          email: email,
          name: name,
          prenom: prenom,
          date: date,
          region: region,
          genre: genre,
          photoUrl: photoUrl,
          id: id,
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'],
      prenom: json['prenom'],
      date: json['date'] != null 
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      region: json['region'] ?? '',
      genre: json['genre'] ?? '',
      photoUrl: json['photoUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'prenom': prenom,
      'date': date.toIso8601String(),
      'region': region,
      'genre': genre,
      'photoUrl': photoUrl,
    }..removeWhere((key, value) => value == null); // Remove null values
  }

  // Optional: Add a method to create a copy of the model with some changes
  UserModel copyWith({
    String? email,
    String? name,
    String? prenom,
    DateTime? date,
    String? region,
    String? genre,
    String? photoUrl,
    String? id,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      prenom: prenom ?? this.prenom,
      date: date ?? this.date,
      region: region ?? this.region,
      genre: genre ?? this.genre,
      photoUrl: photoUrl ?? this.photoUrl,
      id: id ?? this.id,
    );
  }
}