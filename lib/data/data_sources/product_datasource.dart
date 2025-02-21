import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:opti_app/domain/entities/product_entity.dart';

class ProductDatasource {
  final String baseUrl = 'http://192.168.1.22:3000/api/products';

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
        Uri.parse('$baseUrl'), // Ensure this matches the server route
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
}
