// data/data_sources/OpticianDataSource.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:opti_app/domain/entities/Optician.dart';

abstract class OpticianDataSource {
  Future<List<Optician>> getOpticians();
  Future<Optician> addOptician(Optician optician);
  Future<Optician> updateOptician(Optician optician);
  Future<bool> deleteOptician(String id);
}

class OpticianDataSourceImpl implements OpticianDataSource {
  // You may want to make this configurable via environment variables
  final String baseUrl = 'http://localhost:3000/api';

  @override
  Future<List<Optician>> getOpticians() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/opticians'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Optician.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load opticians: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch opticians: $e');
    }
  }

  @override
  Future<Optician> addOptician(Optician optician) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/opticians'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(optician.toJson()),
      );
      
      if (response.statusCode == 201) {
        return Optician.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to add optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to add optician: $e');
    }
  }

  @override
  Future<Optician> updateOptician(Optician optician) async {
    if (optician.id == null) {
      throw Exception('Cannot update optician without ID');
    }
    
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/opticians/${optician.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(optician.toJson()),
      );
      
      if (response.statusCode == 200) {
        return Optician.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to update optician: $e');
    }
  }

  @override
  Future<bool> deleteOptician(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/opticians/$id'),
      );
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete optician: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete optician: $e');
    }
  }
}