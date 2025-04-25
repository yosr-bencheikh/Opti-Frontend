import 'package:dio/dio.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class GlassesManagerService {
  // Utiliser l'adresse IP du serveur au lieu de localhost pour Android
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: getBaseUrl(),
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Méthode pour obtenir la bonne URL de base selon la plateforme
  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:3000'; // URL pour le web
    } else if (Platform.isAndroid) {
      return 'http://192.168.1.19:3000'; // Remplacer par l'adresse IP réelle de votre serveur sur le réseau
    } else {
      return 'http://localhost:3000'; // Fallback pour les autres plateformes
    }
  }

  /// Upload a 3D model file to the server
  static Future<String> uploadModel3D(
    Uint8List bytes,
    String fileName,
    String productId,
  ) async {
    try {
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
        'productId': productId,
      });

      final response = await _dio.post(
        '/upload-model',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        ),
      );

      // Debug: Afficher la réponse complète
      print('Réponse du serveur: ${response.data}');

      if (response.statusCode == 200) {
        // Plusieurs formats de réponse possibles
        final responseData = response.data;

        if (responseData is String) {
          return ensureAbsoluteUrl(
              responseData); // Assurer que l'URL est absolue
        } else if (responseData is Map) {
          // Essayer différents formats de clés et assurer que l'URL est absolue
          String url = responseData['url'] ??
              responseData['filePath'] ??
              responseData['modelUrl'] ??
              (throw Exception('Format de réponse inattendu: ${responseData}'));
          return ensureAbsoluteUrl(url);
        } else {
          throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}');
        }
      } else {
        throw Exception('Upload failed: ${response.statusMessage}');
      }
    } catch (e) {
      // Debug plus détaillé
      print('Erreur d\'upload: $e');
      if (e is DioException) {
        print('Erreur Dio: ${e.response?.data}');
      }
      throw Exception('Upload error: ${e.toString()}');
    }
  }

  static String ensureAbsoluteUrl(String url) {
    // Si l'URL est déjà absolue, on la vérifie quand même
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Remplacer localhost par l'adresse IP si sur Android
      if (!kIsWeb &&
          Platform.isAndroid &&
          (url.contains('localhost') || url.contains('127.0.0.1'))) {
        return url.replaceFirst(RegExp(r'http://(localhost|127\.0\.0\.1):3000'),
            'http://192.168.1.19:3000');
      }
      return url;
    }

    // Si l'URL est relative
    return '${getBaseUrl()}${url.startsWith('/') ? '' : '/'}$url';
  }

  /// Récupérer les détails d'un modèle 3D spécifique
  static Future<Map<String, dynamic>> getModelDetails(String productId) async {
    try {
      final response = await _dio.get('/products/model3d/$productId');
      Map<String, dynamic> details = Map<String, dynamic>.from(response.data);

      // Assurer que l'URL du modèle est absolue
      if (details.containsKey('filePath')) {
        details['filePath'] = ensureAbsoluteUrl(details['filePath']);
      }

      return details;
    } catch (e) {
      print('Erreur lors de la récupération des détails du modèle: $e');
      throw Exception(
          'Erreur lors de la récupération des détails du modèle: $e');
    }
  }

  /// Supprimer un modèle 3D
  static Future<void> deleteModel(String id) async {
    try {
      await _dio.delete('/products/$id');
    } catch (e) {
      print('Erreur lors de la suppression du modèle: $e');
      throw Exception('Erreur lors de la suppression du modèle: $e');
    }
  }
}
