import 'package:get/get.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/store_wishlist_controller.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/repositories/OpticianRepositoryImpl.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    _registerCoreDependencies();
    _registerAuthDependencies();
    _registerProductDependencies();
    _registerOpticianDependencies();
  }

  void _registerCoreDependencies() {
    if (!Get.isRegistered<SharedPreferences>()) {
      Get.putAsync<SharedPreferences>(
        () async => await SharedPreferences.getInstance());
    }

    if (!Get.isRegistered<http.Client>()) {
      Get.put<http.Client>(http.Client());
    }
  }

  void _registerAuthDependencies() {
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(client: Get.find<http.Client>()),
    );

    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Get.find<AuthRemoteDataSource>()),
    );

    Get.lazyPut<AuthController>(
      () => AuthController(
        authRepository: Get.find<AuthRepository>(),
        prefs: Get.find<SharedPreferences>(),
      ),
      fenix: true,
    );
  }

  void _registerProductDependencies() {
    Get.lazyPut<ProductDatasource>(() => ProductDatasource());

    Get.lazyPut<ProductRepositoryImpl>(
      () => ProductRepositoryImpl(dataSource: Get.find<ProductDatasource>()),
    );

    Get.lazyPut<ProductController>(
      () => ProductController(
        Get.find<ProductRepositoryImpl>(),
        Get.find<ProductDatasource>(),
      ),
    );
  }

  void _registerOpticianDependencies() {
    Get.lazyPut<OpticianDataSource>(() => OpticianDataSourceImpl());
    
    Get.lazyPut<OpticianRepository>(
      () => OpticianRepositoryImpl(Get.find<OpticianDataSource>()),
    );

    Get.lazyPut<OpticianController>(
      () => OpticianController(),
      fenix: true,
    );
     Get.lazyPut(() => StoreWishlistController());
  }
}