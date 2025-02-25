import 'package:opti_app/data/models/user_model.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<UserModel>> execute() async {
    return await repository.getUsers();
  }

  
}