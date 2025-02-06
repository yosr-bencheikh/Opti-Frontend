class User {
  final String email;
  final String? name;
  final String? prenom;
  final DateTime date;
  final String region;
  final String genre;
  final String? photoUrl;
  final String? id;

  User({
    required this.email,
    this.name,
    this.prenom,
    required this.date,
    required this.region,
    required this.genre,
    this.photoUrl,
    this.id,
  });

  // Optional: Add a factory constructor to create from a DateTime string
  factory User.fromDateString({
    required String email,
    String? name,
    String? prenom,
    required String dateString,
    required String region,
    required String genre,
    String? photoUrl,
    String? id,
  }) {
    return User(
      email: email,
      name: name,
      prenom: prenom,
      date: DateTime.parse(dateString),
      region: region,
      genre: genre,
      photoUrl: photoUrl,
      id: id,
    );
  }
}