import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as client;
import 'package:http_parser/http_parser.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductDatasource {
  final String baseUrl = 'http://192.168.1.22:3000/api/products';
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

  @override
  Future<Product> getProductById(String productId) async {
    final response =
        await client.get(Uri.parse('$baseUrl/products/$productId'));
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load product');
    }
  }

  Future<List<Opticien>> getOpticiens() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.22:3000/opticiens'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Opticien.fromJson(json)).toList();
      } else {
        throw Exception('Échec du chargement des opticiens');
      }
    } catch (e) {
      throw Exception('Erreur lors de la récupération des opticiens: $e');
    }
  }
  Future<Map<String, dynamic>> getProductRatings(String productId) async {
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/ratings/$productId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'averageRating': data['averageRating'] ?? 0.0,
        'totalReviews': data['totalReviews'] ?? 0
      };
    } else {
      throw Exception('Failed to load product ratings');
    }
  } catch (e) {
    print('Error fetching product ratings: $e');
    return {
      'averageRating': 0.0,
      'totalReviews': 0
    };
  }
}

// Method to add a review
Future<void> addProductReview({
  required String productId, 
  required String userId, 
  required int rating, 
  String? comment
}) async {
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
}

