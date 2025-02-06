import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required String email,
    String? name,
    String? prenom,
    required String date,
    required phone,
    required String password,  // Ensure this is required if needed
    required String region,
    required String genre,
    String? photoUrl,
    String? id,
  }) : super(
          email: email,
          name: name ??"",
          prenom: prenom??"",
          date: date,
          region: region,
          genre: genre,
          
        
          phone: phone,
          password: password, // Pass password to super
        );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'] ?? '',
      name: json['name'],
      prenom: json['prenom'],
      date: json['date'],
      region: json['region'] ?? '',
      genre: json['genre'] ?? '',
      photoUrl: json['photoUrl'], 
      password: json['password'], phone:json['phone'],  // Assign default empty string for password
    );
  }

  Map<String, dynamic> toJson() {
    return {
      
      'email': email,
      'name': name,
      'prenom': prenom,
      'date': date,
      'region': region,
      'genre': genre,
     
    }..removeWhere((key, value) => value == null); // Remove null values
  }

  // Optional: Add a method to create a copy of the model with some changes
  UserModel copyWith({
    String? email,
    String? name,
    String? prenom,
    String? date,
    String? region,
    String? genre,
    String? photoUrl,
    String? id,
    String? password,  // Optional password parameter
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      prenom: prenom ?? this.prenom,
      date: date ?? this.date,
      region: region ?? this.region,
      genre: genre ?? this.genre,
   
      password: password ?? this.password, phone: phone,  // Use the existing password if not provided
    );
  }
}
