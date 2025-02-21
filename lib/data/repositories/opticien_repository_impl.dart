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
}
