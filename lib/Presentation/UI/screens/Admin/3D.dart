import 'package:dio/dio.dart';
import 'dart:typed_data';

class GlassesManagerService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

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
        return responseData; // Si le serveur renvoie directement l'URL
      } else if (responseData is Map) {
        // Essayer différents formats de clés
        return responseData['url'] ?? 
               responseData['filePath'] ?? 
               responseData['modelUrl'] ??
               (throw Exception('Format de réponse inattendu: ${responseData}'));
      } else {
        throw Exception('Format de réponse inattendu: ${responseData.runtimeType}');
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


  /// Récupérer tous les modèles 3D
  static Future<List<Map<String, dynamic>>> fetchAllModels() async {
    try {
      final response = await _dio.get('/products/with-3d-model');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      print('Erreur lors de la récupération des modèles: $e');
      throw Exception('Erreur lors de la récupération des modèles: $e');
    }
  }

  /// Récupérer les détails d'un modèle 3D spécifique
  static Future<Map<String, dynamic>> getModelDetails(String productId) async {
    try {
      final response = await _dio.get('/products/model3d/$productId');
      return Map<String, dynamic>.from(response.data);
    } catch (e) {
      print('Erreur lors de la récupération des détails du modèle: $e');
      throw Exception('Erreur lors de la récupération des détails du modèle: $e');
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