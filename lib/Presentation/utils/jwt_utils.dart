// utils/jwt_utils.dart
import 'dart:convert';

class JwtUtils {
  static String getUserId(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }
    final payload = parts[1];
    final normalized = base64Url.normalize(payload);
    final decoded = utf8.decode(base64Url.decode(normalized));
    final payloadMap = json.decode(decoded) as Map<String, dynamic>;

    // Print the payload to inspect its structure
    print('Decoded Payload: $payloadMap');

    // Check if 'userId' or an alternative key is available in the payload
    final userId = payloadMap['userId'] as String?;
    if (userId == null) {
      // Check for other potential keys, like 'id'
      final alternativeUserId = payloadMap['id'] as String?;
      if (alternativeUserId == null) {
        throw Exception('userId or id not found in the token');
      }
      return alternativeUserId;
    }

    return userId;
  } catch (e) {
    throw Exception('Error decoding token: $e');
  }
}

}
