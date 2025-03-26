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
      // Create FormData for upload
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
        'productId': productId,
      });

      // Add debug logs
      print('Uploading model: $fileName, productId: $productId');
      print('FormData contents: ${formData.fields}');

      // Send request to the correct endpoint
      final response = await _dio.post('/upload-model', data: formData);

      print('Upload response: ${response.data}');

      if (response.statusCode == 200) {
        // Return either the model ID or the file path, depending on what your API returns
        // This will be set as the model3D field in your Product
        if (response.data['modelId'] != null) {
          return response.data['modelId'];
        } else {
          return response.data['filePath'];
        }
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('DioException during 3D model upload:');
      print('  - Status code: ${e.response?.statusCode}');
      print('  - Response data: ${e.response?.data}');
      print('  - Request: ${e.requestOptions.uri}');
      
      if (e.response?.statusCode == 404) {
        throw Exception('Upload route not found. Verify server configuration.');
      }
      
      throw Exception('Upload error: ${e.message}');
    } catch (e) {
      print('Error during 3D model upload: $e');
      throw Exception('Upload error: $e');
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