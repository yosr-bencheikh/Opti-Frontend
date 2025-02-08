class Validators {
  // Validation pour le nom
  static String? isValidName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom ne peut pas être vide';
    }
    return null;
  }

  // Validation pour le prénom
  static String? isValidPrenom(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le prénom ne peut pas être vide';
    }
    return null;
  }

  // Validation pour l'email
  static String? isValidEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email ne peut pas être vide';
    }
    // Validation regex de l'email
    String emailPattern =
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$";
    RegExp regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(value)) {
      return 'L\'email n\'est pas valide';
    }
    return null;
  }

  // Validation pour la date
  static String? isValidDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'La date ne peut pas être vide';
    }
    // Vérifiez si la date correspond au format "YYYY-MM-DD"
    String datePattern = r"^\d{4}-\d{2}-\d{2}$";
    RegExp regExp = RegExp(datePattern);
    if (!regExp.hasMatch(value)) {
      return 'Le format de la date doit être "YYYY-MM-DD"';
    }
    return null;
  }

static String? isValidPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe ne peut pas être vide';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }
    
    // Version corrigée du pattern avec échappement correct des caractères spéciaux
    String passwordPattern = 
      r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()+=\-\[\]{};\:\"",.<>?/\\|]).{8,}$';
    
    RegExp regExp = RegExp(passwordPattern);
    if (!regExp.hasMatch(value)) {
      return 'Le mot de passe doit contenir une majuscule, un chiffre et un caractère spécial';
    }
    return null;
  }

  // Validation pour la confirmation du mot de passe
  static String? isValidConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }

  // Validation pour la région
  static String? isValidRegion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La région ne peut pas être vide';
    }
    return null;
  }

  // Validation pour le genre
  static String? isValidGenre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le genre ne peut pas être vide';
    }
    return null;
  }

  // Validation pour le numéro de téléphone (8 chiffres)
  static String? isValidPhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le numéro de téléphone ne peut pas être vide';
    }
    // Vérification que le numéro de téléphone contient exactement 8 chiffres
    String phonePattern = r"^\d{8}$";
    RegExp regExp = RegExp(phonePattern);
    if (!regExp.hasMatch(value)) {
      return 'Le numéro de téléphone doit contenir exactement 8 chiffres';
    }
    return null;
  }
}
