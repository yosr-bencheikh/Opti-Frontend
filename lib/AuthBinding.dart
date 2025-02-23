import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Ensure SharedPreferences and http.Client are registered first
    _registerCoreDependencies();

    // AuthRemoteDataSource
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: Get.find<http.Client>()),
    );

    // AuthRepository
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find<AuthRemoteDataSource>()),
    );

    // AuthController
    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        prefs: Get.find<SharedPreferences>(),
      ),
      fenix: true, // Re-instantiate if needed after logout
    );

    // First register the datasource
    Get.put<ProductDatasource>(ProductDatasource());

    // Then register the controller that depends on it
    Get.put<ProductController>(ProductController(Get.find()));
  }
}

void _registerCoreDependencies() {
  // Register SharedPreferences if not already registered
  if (!Get.isRegistered<SharedPreferences>()) {
    Get.putAsync<SharedPreferences>(
        () async => await SharedPreferences.getInstance());
  }

  // Register http.Client if not already registered
  if (!Get.isRegistered<http.Client>()) {
    Get.put<http.Client>(http.Client());
  }
}
