// exception.dart

class LoginException implements Exception {
  final String message;
  LoginException(this.message);

  @override
  String toString() => 'LoginException: $message';
}

class EmptyResponseException implements Exception {
  final String message;
  EmptyResponseException(this.message);

  @override
  String toString() => 'EmptyResponseException: $message';
}

class InvalidTokenException implements Exception {
  final String message;
  InvalidTokenException(this.message);

  @override
  String toString() => 'InvalidTokenException: $message';
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}