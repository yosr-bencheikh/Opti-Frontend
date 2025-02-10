class Validators {
  // Validation pour le nom
  static String? isValidName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le nom ne peut pas être vide';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le nom ne peut pas contenir de chiffres';
    }
    if (RegExp(r'[^a-zA-ZÀ-ÿ\- ]').hasMatch(value)) {
      return 'Le nom ne peut contenir que des lettres et des tirets';
    }
    if (value.trim().length < 2) {
      return 'Le nom doit contenir au moins 2 caractères';
    }
    return null;
  }

  // Validation pour le prénom
  static String? isValidPrenom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le prénom ne peut pas être vide';
    }
    if (RegExp(r'[0-9]').hasMatch(value)) {
      return 'Le prénom ne peut pas contenir de chiffres';
    }
    if (RegExp(r'[^a-zA-ZÀ-ÿ\- ]').hasMatch(value)) {
      return 'Le prénom ne peut contenir que des lettres et des tirets';
    }
    if (value.trim().length < 2) {
      return 'Le prénom doit contenir au moins 2 caractères';
    }
    return null;
  }

  // Validation pour l'email
  static String? isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'email ne peut pas être vide';
    }
    String emailPattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
    RegExp regExp = RegExp(emailPattern);
    if (!regExp.hasMatch(value.trim())) {
      return 'L\'email n\'est pas valide';
    }
    return null;
  }

  // Validation pour la date (Format YYYY-MM-DD)
  static String? isValidDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La date ne peut pas être vide';
    }

    String datePattern = r"^\d{4}-\d{2}-\d{2}$";
    RegExp regExp = RegExp(datePattern);
    if (!regExp.hasMatch(value)) {
      return 'Le format de la date doit être "YYYY-MM-DD"';
    }

    try {
      DateTime parsedDate = DateTime.parse(value);
      DateTime today = DateTime.now();

      // Vérification de l'année
      if (parsedDate.year < 1900 || parsedDate.year > today.year) {
        return 'L\'année doit être comprise entre 1900 et l\'année actuelle';
      }

      // Vérification de l'âge minimal (ex: 18 ans)
      int age = today.year - parsedDate.year;
      if (today.month < parsedDate.month ||
          (today.month == parsedDate.month && today.day < parsedDate.day)) {
        age--; // Ajuster l'âge si l'anniversaire n'est pas encore passé cette année
      }

      if (age < 18) {
        return 'Vous devez avoir au moins 18 ans';
      }
    } catch (e) {
      return 'Date invalide';
    }

    return null;
  }

  // Validation pour le mot de passe
  static String? isValidPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe ne peut pas être vide';
    }
    if (value.length < 8) {
      return 'Le mot de passe doit contenir au moins 8 caractères';
    }

    // Vérifier s'il contient au moins une majuscule
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins une majuscule';
    }

    // Vérifier s'il contient au moins un chiffre
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un chiffre';
    }

    // Vérifier s'il contient au moins un caractère spécial
    if (!RegExp(r"[!@#$%^&*()_+={}\[\]:;\'|<>,.?/~`-]").hasMatch(value)) {
      return 'Le mot de passe doit contenir au moins un caractère spécial';
    }

    return null;
  }

  // Validation pour la confirmation du mot de passe
  static String? isValidConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer votre mot de passe';
    }
    if (value != password) {
      return 'Les deux mots de passe ne sont pas identiques';
    }
    return null;
  }

  // Validation pour la région
  static String? isValidRegion(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La région ne peut pas être vide';
    }
    return null;
  }

  // Validation pour le genre
  static String? isValidGenre(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le genre ne peut pas être vide';
    }
    return null;
  }

  // Validation pour le numéro de téléphone
  static String? isValidPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Le numéro de téléphone ne peut pas être vide';
    }
    // Vérification que le numéro contient uniquement des chiffres
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'Le numéro de téléphone ne doit contenir que des chiffres';
    }
    // Vérification que le numéro a exactement 8 chiffres
    if (value.length != 8) {
      return 'Le numéro de téléphone doit contenir exactement 8 chiffres';
    }
    // Vérification que le numéro ne commence pas par 0
    if (value.startsWith('0')) {
      return 'Le numéro de téléphone ne peut pas commencer par 0';
    }
    return null;
  }
}
