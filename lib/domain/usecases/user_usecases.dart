import 'package:opti_app/domain/entities/user.dart';
import 'package:opti_app/domain/repositories/user_repository.dart';

class GetUsersUseCase {
  final UserRepository repository;

  GetUsersUseCase(this.repository);

  Future<List<User>> execute() async {
    return await repository.getUsers();
  }
}

class GetUserByEmailUseCase {
  final UserRepository repository;

  GetUserByEmailUseCase(this.repository);

  Future<User> execute(String email) async {
    return await repository.getUserByEmail(email);
  }
}

class UpdateUserUseCase {
  final UserRepository repository;

  UpdateUserUseCase(this.repository);

  Future<void> execute(User user) async {
    await repository.updateUser(user);
  }
}

class DeleteUserUseCase {
  final UserRepository repository;

  DeleteUserUseCase(this.repository);

  Future<void> execute(String email) async {
    await repository.deleteUser(email);
  }
}