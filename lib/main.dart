import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/AuthBinding.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/cart_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/favourite_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/home_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/splash_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/stores_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/CheckoutScreen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/WelcomePage.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/UI/screens/auth/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/data/repositories/OrderRepositoryImpl.dart';
import 'package:opti_app/data/repositories/cart_item_repository_impl.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/opticien_controller.dart';
import 'package:opti_app/data/data_sources/cart_item_remote_datasource.dart';
import 'package:opti_app/data/data_sources/opticien_remote_datasource.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/repositories/opticien_repository_impl.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';

import 'package:opti_app/domain/repositories/opticien_repository.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';
import 'package:opti_app/domain/usecases/OrderUseCase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/Presentation/UI/screens/auth/SignUpScreen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/admin_panel.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/profile_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/forgot_password.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/usecases/send_code_to_email.dart';
import 'package:dio/dio.dart'; // Importez Dio
import 'package:opti_app/data/data_sources/wishlist_remote_datasource.dart'; // Importez WishlistRemoteDataSource
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart'; // Importez WishlistController

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);

  // Register HTTP Client
  final client = http.Client();
  Get.put<http.Client>(client);

  // Initialize Dio for Wishlist
  final dio = Dio();
  Get.put<Dio>(dio);

  // ✅ Register NavigationController before running the app
  Get.put<NavigationController>(NavigationController());

  // Product Repository & Controller
  final productRemoteDataSource = ProductDatasource();
  Get.put<ProductDatasource>(productRemoteDataSource);

  final productRepository = ProductRepositoryImpl(dataSource: productRemoteDataSource);
  Get.put<ProductRepositoryImpl>(productRepository);
  Get.put<ProductRepository>(productRepository);

  Get.put<ProductController>(ProductController(productRepository));

  // Auth Repository & Controller
  final authRemoteDataSource = AuthRemoteDataSourceImpl(client: client);
  Get.put<AuthRemoteDataSource>(authRemoteDataSource);

  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  Get.put<AuthRepository>(authRepository);

  Get.put<AuthController>(AuthController(authRepository: authRepository, prefs: prefs));

  // Opticien Repository & Controller
  final opticienRemoteDataSource = OpticienRemoteDataSourceImpl(client: client);
  Get.put<OpticienRemoteDataSource>(opticienRemoteDataSource);

  final opticienRepository = OpticienRepositoryImpl(opticienRemoteDataSource);
  Get.put<OpticienRepository>(opticienRepository);

  Get.put<OpticienController>(OpticienController(opticienRepository: opticienRepository));

  // Cart Item Repository & Controller
  final cartItemRemoteDataSource = CartItemDataSourceImpl(client: client);
  Get.put<CartItemDataSource>(cartItemRemoteDataSource);

  final cartItemRepository = CartItemRepositoryImpl(dataSource: cartItemRemoteDataSource);
  Get.put<CartItemRepository>(cartItemRepository);

  Get.put<CartItemController>(CartItemController(repository: cartItemRepository, productRepository: productRepository));

  // Wishlist Repository & Controller
  final wishlistRemoteDataSource = WishlistRemoteDataSourceImpl(dio);
  Get.put<WishlistRemoteDataSource>(wishlistRemoteDataSource);

  Get.put<WishlistController>(WishlistController(wishlistRemoteDataSource));

  // Order Use Cases & Repository
  final orderDataSource = OrderDataSourceImpl(client: http.Client());
  Get.put<OrderDataSource>(orderDataSource);

  final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
  Get.put<OrderRepository>(orderRepository);

  Get.put<CreateOrderUseCase>(CreateOrderUseCase(orderRepository));
  Get.put<GetUserOrdersUseCase>(GetUserOrdersUseCase(orderRepository));
  Get.put<GetOrderByIdUseCase>(GetOrderByIdUseCase(orderRepository));
  Get.put<UpdateOrderStatusUseCase>(UpdateOrderStatusUseCase(orderRepository));
  Get.put<CancelOrderUseCase>(CancelOrderUseCase(orderRepository));

  // Register OrderController using lazyPut
Get.put<OrderController>(OrderController(
  createOrderUseCase: Get.find<CreateOrderUseCase>(),
  getUserOrdersUseCase: Get.find<GetUserOrdersUseCase>(),
  getOrderByIdUseCase: Get.find<GetOrderByIdUseCase>(),
  updateOrderStatusUseCase: Get.find<UpdateOrderStatusUseCase>(),
  cancelOrderUseCase: Get.find<CancelOrderUseCase>(),
));

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Opti App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => SplashScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/Admin_pannel',
          page: () => AdminPanelApp(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/welcomePage',
          page: () => WelcomePage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/profileScreen',
          page: () => ProfileScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/HomeScreen',
          page: () => HomeScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/dashboard',
          page: () => AdminPanelApp(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/ForgotPasswordScreen',
          page: () => EnterEmailScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/signup',
          page: () => SignUpScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/update',
          page: () => ProfileScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/stores',
          page: () => StoresScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/favourites',
          page: () => FavouriteScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
  name: '/wishlist',
  page: () {
    final userEmail = Get.arguments as String; // Récupérer l'email des arguments
    return WishlistPage(userEmail: userEmail);
  },),
        GetPage(
          name: '/cart',
          page: () => CartScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/order',
          page: () => CheckoutScreen(),
          binding: AuthBinding(),
        ),
                  
      ],
    );
  }
}