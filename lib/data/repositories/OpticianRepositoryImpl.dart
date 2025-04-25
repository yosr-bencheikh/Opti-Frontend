import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/domain/entities/Optician.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';

class OpticianRepositoryImpl implements OpticianRepository {
  final OpticianDataSource _dataSource;

  OpticianRepositoryImpl(this._dataSource);

@override
Future<void> sendPasswordResetEmail(String email) async {
  await _dataSource.sendPasswordResetEmail(email);
}

@override
Future<bool> verifyResetCode(String email, String code) async {
  return await _dataSource.verifyResetCode(email, code);
}

@override
Future<bool> resetPassword(String email, String code, String newPassword) async {
  return await _dataSource.resetPassword(email, code, newPassword);
}
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

    @override
  Future<String> loginWithEmail(String email, String password) async {
    try {
      return await _dataSource.loginWithEmail(email, password);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }
}