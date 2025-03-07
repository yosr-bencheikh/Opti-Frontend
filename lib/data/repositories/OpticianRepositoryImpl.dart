import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';

class OpticianRepositoryImpl implements OpticianRepository {
  final OpticianDataSource _dataSource;

  OpticianRepositoryImpl(this._dataSource);

  @override
  Future<List<Optician>> getOpticians() async {
    return await _dataSource.getOpticians();
  }

  @override
  Future<void> addOptician(Optician optician) async {
    await _dataSource.addOptician(optician);
  }

  @override
  Future<void> updateOptician(Optician optician) async {
    await _dataSource.updateOptician(optician);
  }

  @override
  Future<void> deleteOptician(String email) async {
    await _dataSource.deleteOptician(email);
  }
}