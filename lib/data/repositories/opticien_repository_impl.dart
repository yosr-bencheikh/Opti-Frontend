import 'package:opti_app/data/data_sources/opticien_remote_datasource.dart';
import 'package:opti_app/domain/entities/Opticien.dart';
import 'package:opti_app/domain/repositories/opticien_repository.dart';

class OpticienRepositoryImpl implements OpticienRepository {
  final OpticienRemoteDataSource dataSource;

  OpticienRepositoryImpl(this.dataSource);

  @override
  Future<List<Opticien>> getOpticiens() async {
    try {
      return await dataSource.getOpticiens();
    } catch (e) {
      throw Exception('Failed to fetch opticians: $e');
    }
  }
  
  @override
  Future<void> addOpticien(Opticien opticien) async {
    try {
      await dataSource.addOpticien(opticien);
    } catch (e) {
      throw Exception('Failed to add optician: $e');
    }
  }
  
  @override
  Future<void> updateOpticien(String id, Opticien opticien) async {
    try {
      await dataSource.updateOpticien(id, opticien);
    } catch (e) {
      throw Exception('Failed to update optician: $e');
    }
  }
  
  @override
  Future<void> deleteOpticien(String id) async {
    try {
      await dataSource.deleteOpticien(id);
    } catch (e) {
      throw Exception('Failed to delete optician: $e');
    }
  }
}