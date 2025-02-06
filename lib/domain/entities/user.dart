class User {
  final String name;
  final String prenom;
  final String email;
  final String date;
  final String password;
  final String phone;
  final String region;
  final String genre;

  User({
    required this.name,
    required this.prenom,
    required this.email,
    required this.date,
    required this.password,
    required this.phone,
    required this.region,
    required this.genre,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'prenom': prenom,
      'email': email,
      'date': date,
      'password': password,
      'phone': phone,
      'region': region,
      'genre': genre,
    };
  }
}
