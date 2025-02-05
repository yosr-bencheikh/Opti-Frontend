import 'package:equatable/equatable.dart';

class Token extends Equatable {
  final String token;
  final String refreshToken;
  final String userId;
  final DateTime expiryDate;

  const Token(
      {required this.token,
      required this.refreshToken,
      required this.expiryDate,
      required this.userId});
  @override
  List<Object?> get props => [token, refreshToken, expiryDate, userId];
}
