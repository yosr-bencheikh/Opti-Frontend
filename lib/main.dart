import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:opti_app/AuthBinding.dart';
import 'package:opti_app/Presentation/UI/screens/Admin/admin_panel.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Commande.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/LoginScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/OpticienDashboardApp.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/Product_Screen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/UserScreen.dart';
import 'package:opti_app/Presentation/UI/screens/Opticien/gestion_boutique.dart';
import 'package:opti_app/Presentation/UI/screens/User/CheckoutScreen.dart';
import 'package:opti_app/Presentation/UI/screens/User/SignUpScreen.dart';
import 'package:opti_app/Presentation/UI/screens/User/WelcomePage.dart';
import 'package:opti_app/Presentation/UI/screens/User/cart_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/favourite_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/forgot_password.dart';
import 'package:opti_app/Presentation/UI/screens/User/home_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/login_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/profile_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/splash_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/stores_screen.dart';
import 'package:opti_app/Presentation/UI/screens/User/wishlist_page.dart';
import 'package:opti_app/Presentation/controllers/OpticianController.dart';
import 'package:opti_app/Presentation/controllers/OrderController.dart';
import 'package:opti_app/Presentation/controllers/auth_controller.dart';
import 'package:opti_app/Presentation/controllers/boutique_controller.dart';
import 'package:opti_app/Presentation/controllers/cart_item_controller.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/Presentation/controllers/user_controller.dart';
import 'package:opti_app/Presentation/controllers/wishlist_controller.dart';
import 'package:opti_app/data/data_sources/OpticianDataSource.dart';
import 'package:opti_app/data/data_sources/OrderDataSource.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/data/data_sources/boutique_remote_datasource.dart';
import 'package:opti_app/data/data_sources/cart_item_remote_datasource.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/data_sources/user_datasource.dart';
import 'package:opti_app/data/data_sources/wishlist_remote_datasource.dart';
import 'package:opti_app/data/repositories/OpticianRepositoryImpl.dart';
import 'package:opti_app/data/repositories/OrderRepositoryImpl.dart';
import 'package:opti_app/data/repositories/auth_repository_impl.dart';
import 'package:opti_app/data/repositories/boutique_repository_impl.dart';
import 'package:opti_app/data/repositories/cart_item_repository_impl.dart';
import 'package:opti_app/data/repositories/product_repository_impl.dart';
import 'package:opti_app/domain/repositories/OpticianRepository.dart';
import 'package:opti_app/domain/repositories/OrderRepository.dart';
import 'package:opti_app/domain/repositories/auth_repository.dart';
import 'package:opti_app/domain/repositories/boutique_repository.dart';
import 'package:opti_app/domain/repositories/product_repository.dart';
import 'package:opti_app/domain/usecases/send_code_to_email.dart';
import 'package:opti_app/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/Presentation/UI/screens/User/ordersList_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);

  // Register dependencies
  final client = http.Client();
  Get.put<http.Client>(client);

  // Register UserDataSource and UserController
  final userDataSource = UserDataSourceImpl(
      client: client); // Assurez-vous que cette classe existe
  Get.put<UserDataSource>(userDataSource);

  final userController =
      UserController(userDataSource); // Initialisez UserController
  Get.put<UserController>(userController); // Enregistrez-le dans GetX

  // Register other dependencies
  final productRemoteDataSource = ProductDatasource();
  Get.put<ProductDatasource>(productRemoteDataSource);
  final productRepository =
      ProductRepositoryImpl(dataSource: productRemoteDataSource);
  Get.put<ProductRepository>(productRepository);
  Get.put<ProductRepositoryImpl>(productRepository);
  Get.put<ProductController>(
      ProductController(productRepository, productRemoteDataSource));

  final authRemoteDataSource = AuthRemoteDataSourceImpl(client: client);
  Get.put<AuthRemoteDataSource>(authRemoteDataSource);
  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  Get.put<AuthRepository>(authRepository);
  Get.put<AuthController>(
      AuthController(authRepository: authRepository, prefs: prefs));

 // Initialisation des dépendances pour Optician
  final opticianDataSource = OpticianDataSourceImpl();
  Get.put<OpticianDataSource>(opticianDataSource);
  
  final opticianRepository = OpticianRepositoryImpl(opticianDataSource);
  Get.put<OpticianRepository>(opticianRepository);
  
  final opticianController = OpticianController();
  Get.put<OpticianController>(opticianController, permanent: true);

  // Initialisation des dépendances pour Boutique
  final boutiqueRemoteDataSource = BoutiqueRemoteDataSourceImpl(client: client);
  Get.put<BoutiqueRemoteDataSource>(boutiqueRemoteDataSource);
  
  final boutiqueRepository = BoutiqueRepositoryImpl(boutiqueRemoteDataSource);
  Get.put<BoutiqueRepository>(boutiqueRepository);
  
  final boutiqueController = BoutiqueController(
    opticianController, 
    boutiqueRepository: boutiqueRepository
  );
  Get.put<BoutiqueController>(boutiqueController, permanent: true);


  final cartItemRemoteDataSource = CartItemDataSourceImpl(client: client);
  Get.put<CartItemDataSource>(cartItemRemoteDataSource);
  final cartItemRepository =
      CartItemRepositoryImpl(dataSource: cartItemRemoteDataSource);
  Get.put<CartItemRepository>(cartItemRepository);
  Get.put<CartItemController>(CartItemController(
    repository: cartItemRepository,
    productRepository: productRepository,
  ));

  final dio = Dio();
  final wishlistRemoteDataSource = WishlistRemoteDataSourceImpl(dio);
  Get.put<WishlistRemoteDataSource>(wishlistRemoteDataSource);
  Get.put<WishlistController>(WishlistController(wishlistRemoteDataSource));

  final orderDataSource = OrderDataSourceImpl(client: client);
  Get.put<OrderDataSource>(orderDataSource);
  final orderRepository = OrderRepositoryImpl(dataSource: orderDataSource);
  Get.put<OrderRepository>(orderRepository);

  // Pass the boutiqueRepository to OrderController
  Get.put<OrderController>(OrderController(
    orderRepository: orderRepository,
    boutiqueRepository: boutiqueRepository,
  ));

  final sendCodeToEmail = SendCodeToEmail(Get.find());
  Get.put(sendCodeToEmail);
  Get.put(NavigationController(), permanent: true);
  NotificationService().initialize();

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
      initialRoute: '/Admin_pannel',
      getPages: [
        GetPage(
          name: '/splash',
          page: () => SplashScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/Admin_pannel',
          page: () => AdminMainScreen(),
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
            final userEmail = Get.arguments as String;
            return WishlistPage(userEmail: userEmail);
          },
        ),
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
        GetPage(
          name: '/orderList',
          page: () => OrdersListPage(),
          binding: AuthBinding(),
        ),
        GetPage(
            name: '/OpticienDashboard',
            page: () => OpticianDashboardScreen(),
            binding: AuthBinding()),
        GetPage(
          name: '/products',
          page: () => ProductsScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/users',
          page: () => UsersScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/Commande',
          page: () => OpticienOrdersPage(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/Boutiques',
          page: () => GestionBoutique(),
          binding: AuthBinding(),
        ),
        if (kIsWeb)
          GetPage(
            name: '/LoginOpticien',
            page: () => LoginScreenOpticien(),
            binding: AuthBinding(),
          ),
      ],
    );
  }
}