import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart'; // Assurez-vous d'importer Dio ici
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:opti_app/domain/entities/Boutique.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductDatasource {
  final String baseUrl = 'http://localhost:3000/api/products';

  final Dio _dio = Dio(); // Créez une instance de Dio

  Future<List<Product>> getProductsByBoutiqueId(String boutiqueId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/by-boutique/$boutiqueId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  Future<List<Product>> getProductsByBoutiques(List<String> boutiqueIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/by-boutiques'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'boutiqueIds': boutiqueIds}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products for boutiques');
      }
    } catch (e) {
      throw Exception('Error fetching products: $e');
    }
  }

  Future<Product> createProduct(Product product) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add'), // Ensure this matches the server route
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 201) {
        return Product.fromJson(json.decode(response.body));
      } else {
        print('Erreur de création: ${response.body}');
        throw Exception(
            'Échec de la création du produit: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception lors de la création: $e');
      throw Exception('Erreur lors de la création du produit: $e');
    }
  }

  Future<List<Product>> getProductsByOptician(String opticianId) async {
    try {
      final response =
          await http.get(Uri.parse('$baseUrl?opticianId=$opticianId'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des produits pour cet opticien');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des produits');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des produits: $e');
    }
  }

  Future<String> uploadImage(File imageFile) async {
    try {
      print("Début de l'upload de l'image...");

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:3000/upload'),
      );

      var multipartFile = await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: MediaType('image', 'webp'),
      );

      request.files.add(multipartFile);

      print("Envoi de la requête...");
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("Statut de la réponse : ${response.statusCode}");
      print("Corps de la réponse : ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['imageUrl'];
      } else {
        throw Exception(
            'Échec du téléchargement de l\'image (${response.statusCode})');
      }
    } catch (e) {
      print("Erreur lors du téléchargement de l'image: $e");
      throw Exception('Erreur lors du téléchargement de l\'image: $e');
    }
  }

  Future<Product> updateProduct(String id, Product product) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(product.toJson()),
      );

      if (response.statusCode == 200) {
        return Product.fromJson(json.decode(response.body));
      } else {
        throw Exception('Échec de la mise à jour du produit');
      }
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du produit: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Échec de la suppression du produit');
      }
    } catch (e) {
      throw Exception('Erreur lors de la suppression du produit: $e');
    }
  }

  Future<Product> getProductById(String productId) async {
    final response = await http.get(Uri.parse('$baseUrl/products/$productId'));
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Échec du chargement du produit');
    }
  }

  Future<String> uploadImageWeb(
      Uint8List imageBytes, String fileName, String productId) async {
    try {
      // Vérification des paramètres
      if (imageBytes.isEmpty) {
        throw Exception('Image bytes cannot be empty');
      }

      // Debug logs
      print(
          'Uploading image: fileName=$fileName, productId=$productId, bytesLength=${imageBytes.length}');

      // IMPORTANT: Modifiez l'URL pour correspondre à la route définie sur le serveur
      final uploadUrl = '$baseUrl/upload';
      print('Upload URL: $uploadUrl');

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: fileName,
          contentType: MediaType.parse('image/jpeg'),
        ),
        'productId': productId,
      });

      final response = await Dio().post(
        uploadUrl,
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
          },
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          validateStatus: (status) {
            print('Upload response status: $status');
            return status != null && status < 500;
          },
        ),
      );

      print('Upload response: ${response.data}');

      if (response.statusCode == 200) {
        final imageUrl = response.data['imageUrl'];
        print('Parsed imageUrl: $imageUrl');
        return imageUrl ?? '';
      } else {
        throw Exception(
            'Failed to upload image: ${response.statusCode} - ${response.data}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<Boutique>> getOpticiens() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.19:3000/opticiens'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Boutique.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des opticiens');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des opticiens: $e');
    }
  }

  Future<Map<String, dynamic>> getProductRatings(String productId) async {
    try {
      print('[ProductDatasource] Fetching ratings for $productId');
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/$productId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('[ProductDatasource] Response status: ${response.statusCode}');
      print('[ProductDatasource] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'averageRating': data['averageRating']?.toDouble() ?? 0.0,
          'totalReviews': data['totalReviews'] ?? 0
        };
      } else {
        throw Exception('Failed to load product ratings');
      }
    } catch (e) {
      print('[ProductDatasource] Error: $e');
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }

// Method to add a review
  Future<void> addProductReview(
      {required String productId,
      required String userId,
      required int rating,
      String? comment}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reviews/add'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': productId,
          'userId': userId,
          'rating': rating,
          'comment': comment
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add review');
      }
    } catch (e) {
      print('Error adding product review: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchRecommendations(String faceShape) async {
    try {
      // Convert face shape to format expected by API
      final String apiFormatFaceShape = faceShape.replaceAll('Visage ', '');
      // Fetch recommendations from your API
      final response = await http.get(Uri.parse(
          'http://localhost:3000/api/recommendations/$apiFormatFaceShape'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load recommendations: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching recommendations: $e');
    }
  }

  Future<Object> fetchProductRatings(String productId) async {
    try {
      final response =
          await http.get(Uri.parse('/products/ratings/$productId'));

      if (response.statusCode == 200) {
        return response;
      } else {
        throw Exception(
            'Failed to fetch product ratings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching product ratings: $e');
      // Return default values in case of error
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }

  List<String> getHardcodedStyleRecommendations(String faceShape) {
    // Implement your hardcoded recommendations logic here
    switch (faceShape) {
      case 'Visage rond':
        return ['Carré', 'Pixie avec volume sur le dessus', 'Bob asymétrique'];
      case 'Visage ovale':
        return [
          'Toutes les coupes conviennent',
          'Long avec couches',
          'Bob classique'
        ];
      // Add more cases for other face shapes
      default:
        return [
          'Bob classique',
          'Coupe moyenne avec couches',
          'Pixie versatile'
        ];
    }
  }
}
