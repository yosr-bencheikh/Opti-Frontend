import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/AuthBinding.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/cart_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/favourite_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/home_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/splash_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/stores_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/update_profile_screen.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/wishList.dart';
import 'package:opti_app/Presentation/UI/screens/auth/WelcomePage.dart';
import 'package:opti_app/Presentation/controllers/navigation_controller.dart';
import 'package:opti_app/Presentation/controllers/opticien_controller.dart';
import 'package:opti_app/Presentation/controllers/product_controller.dart';
import 'package:opti_app/data/data_sources/opticien_remote_datasource.dart';
import 'package:opti_app/data/data_sources/product_datasource.dart';
import 'package:opti_app/data/repositories/opticien_repository_impl.dart';
import 'package:opti_app/domain/repositories/opticien_repository.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  Get.put<SharedPreferences>(prefs);

  // Register dependencies
  final client = http.Client();
  Get.put<http.Client>(client);

  final authRemoteDataSource = AuthRemoteDataSourceImpl(client: client);
  Get.put<AuthRemoteDataSource>(authRemoteDataSource);

  final authRepository = AuthRepositoryImpl(authRemoteDataSource);
  Get.put<AuthRepository>(authRepository);

  final opticienRemoteDataSource = OpticienRemoteDataSourceImpl(client: client);
  Get.put<OpticienRemoteDataSource>(opticienRemoteDataSource);

  final opticienRepository = OpticienRepositoryImpl(opticienRemoteDataSource);
  Get.put<OpticienRepository>(opticienRepository);

  // Register the OpticienController
  Get.put<OpticienController>(
      OpticienController(opticienRepository: opticienRepository));

  final sendCodeToEmail = SendCodeToEmail(Get.find());
  Get.put(sendCodeToEmail);
  Get.put(NavigationController(), permanent: true);
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
<<<<<<< HEAD
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
            binding: AuthBinding()),
        GetPage(
            name: '/favourites',
            page: () => FavouriteScreen(),
            binding: AuthBinding()),
        GetPage(
            name: '/wishlist', page: () => Wishlist(), binding: AuthBinding()),
        GetPage(
            name: '/cart', page: () => CartScreen(), binding: AuthBinding()),
      ],
=======
      home: const LoginScreen(), // Profile screen is the first screen
      routes: {
        '/profileScreen': (context) => const ProfileScreen(),
        '/updateProfile': (context) => const UpdateProfileScreen(
              userId: '67a0cb53c575bdaa95c3421f',
            ),
        '/signup': (context) => const SignUpScreen(),
      }, // Set ProfileScreen as the first screen
      debugShowCheckedModeBanner: false, // Removes the debug banner
>>>>>>> cc11e4c (signUp and update)
    );
  }
}
