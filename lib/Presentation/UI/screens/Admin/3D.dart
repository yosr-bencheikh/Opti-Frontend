import 'package:dio/dio.dart';
import 'dart:typed_data';

class GlassesManagerService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  ));

  /// Upload a 3D model file to the server
// Dans GlassesManagerService.dart
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
        headers: {
          'Accept': 'application/json',
        },
      ),
    );

    if (response.statusCode == 200) {
      return response.data['url']; // Le serveur doit retourner l'URL complète
    } else {
      throw Exception('Upload failed: ${response.statusMessage}');
    }
  } catch (e) {
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