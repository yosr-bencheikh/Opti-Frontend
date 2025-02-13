class ApiConstants {
  // URL de base de votre API
  static const String baseUrl = 'http://localhost:3000/api';  // Ajustez selon votre configuration

  // Endpoints
  static const String login = '/login';
  static const String signup = '/users';
  static const String verifyToken = '/verify-token';
  static const String getUser = '/users';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String resetPassword = '/reset-password';
}