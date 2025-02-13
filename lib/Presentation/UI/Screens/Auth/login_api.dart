import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class LoginApi {
  static final _googleSignIn = GoogleSignIn();

  static Future<GoogleSignInAccount?> login() async {
  try {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      // Envoyez le jeton ID et le jeton d'accès à votre backend pour vérification
      final response = await http.post(
        Uri.parse('https://abc123.ngrok.io/auth/google/callback'),
        body: {
          'idToken': idToken,
          'accessToken': accessToken,
        },
      );
  print("ID Token: ${googleAuth.idToken}");
    print("Access Token: ${googleAuth.accessToken}");
      if (response.statusCode == 200) {
        print('Connexion réussie');
      } else {
        print('Échec de la connexion');
      }
    }
  } catch (error) {
    print('Erreur lors de la connexion Google: $error');
  }
}
  static Future<void> signOut() => _googleSignIn.signOut();

  static Future<Map<String, dynamic>?> loginWithFacebook() async {
  try {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status == LoginStatus.success) {
      final AccessToken accessToken = result.accessToken!;
      final userData = await FacebookAuth.instance.getUserData();

      print("Facebook Token: ${accessToken.tokenString}");
      print("User Email: ${userData['email']}");
      print("User Name: ${userData['name']}");

      // Envoyer le token au backend
      final response = await http.post(
        Uri.parse('http://192.168.1.189:3000/auth/facebook/callback'),
        body: {'token': accessToken.tokenString},
      );

      if (response.statusCode == 200) {
        print('Connexion Facebook réussie');
        await Future.delayed(Duration(seconds: 1));
        Get.offAllNamed('/signup');
      } else {
        print('Échec de la connexion Facebook');
      }

      return userData;
    } else {
      print("Connexion annulée par l'utilisateur");
      return null;
    }
  } catch (e) {
    print("Erreur lors de la connexion Facebook: $e");
    return null;
  }
}

  static Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
    print("Déconnexion Facebook réussie");
  }

}
