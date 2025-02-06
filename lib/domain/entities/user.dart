class User {
  final String nom;
  final String prenom;
  final String email;
  final String date;
  final String password;
  final String? phone;
  final String? region;
  final String? gender;

  User({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.date,
    required this.password,
    this.phone,
    this.region,
    this.gender,
  });
}