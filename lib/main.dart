import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:opti_app/AuthBinding.dart';
import 'package:opti_app/Presentation/UI/Screens/Auth/splash_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/WelcomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:opti_app/Presentation/UI/screens/auth/SignUpScreen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/admin_panel.dart';
import 'package:opti_app/Presentation/UI/screens/auth/login_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/profile_screen.dart';
import 'package:opti_app/Presentation/UI/screens/auth/forgot_password.dart';
import 'package:opti_app/data/data_sources/auth_remote_datasource.dart';
import 'package:opti_app/domain/repositories/auth_repository_impl.dart';
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

  final sendCodeToEmail = SendCodeToEmail(Get.find());
  Get.put(sendCodeToEmail);

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
          page: () => const SplashScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/login',
          page: () => LoginScreen(),
          binding: AuthBinding(),
        ),
        GetPage(
          name: '/profileScreen',
          page: () => ProfileScreen(),
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
      ],
    );
  }
}
