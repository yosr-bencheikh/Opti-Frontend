import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opti_app/core/styles/colors.dart';

class AppTextStyles {
  static const TextStyle titleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: 4,
    color: AppColors.accentColor,
  );

  static const TextStyle subtitleStyle = TextStyle(
    fontSize: 14,
    letterSpacing: 2,
    color: AppColors.accentColor,
  );

  static const TextStyle loginTitleStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.primaryColor,
    letterSpacing: 1,
  );

  static const TextStyle loginSubtitleStyle = TextStyle(
    color: AppColors.greyTextColor,
    fontSize: 16,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 2,
    color: AppColors.whiteColor,
  );

  static const TextStyle forgotPasswordStyle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle socialButtonTextStyle = TextStyle(
    color: AppColors.primaryColor,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle signUpTextStyle = TextStyle(
    color: AppColors.greyTextColor,
  );

  static const TextStyle signUpLinkStyle = TextStyle(
    color: AppColors.primaryColor,
    fontWeight: FontWeight.bold,
  );

  static TextStyle welcomeTitleStyle = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.whiteColor,
    shadows: [
      Shadow(
        color: Colors.black.withOpacity(0.3),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
    ],
  );

  static TextStyle welcomeSubtitleStyle = GoogleFonts.poppins(
    fontSize: 18,
    color: AppColors.whiteColor.withOpacity(0.9),
    height: 1.4,
  );

  static TextStyle welcomeDescriptionStyle = GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.whiteColor.withOpacity(0.7),
    fontStyle: FontStyle.italic,
  );


}

class AppDecorations {
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.4),
    borderRadius: BorderRadius.circular(24.0),
    boxShadow: [
      BoxShadow(
        color: Colors.black38,
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration inputDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration buttonDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      colors: [
        AppColors.primaryColor,
        AppColors.secondaryColor,
      ],
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.primaryColor.withOpacity(0.3),
        blurRadius: 12,
        offset: Offset(0, 6),
      ),
    ],
  );





    static BoxDecoration welcomeGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.welcomeGradientStart,
        AppColors.welcomeGradientMiddle,
        AppColors.welcomeGradientEnd,
      ],
      stops: [0.1, 0.5, 0.9],
      transform: GradientRotation(0.2), // Légère rotation pour plus de dynamisme
    ),
  );

  static BoxDecoration welcomeImageDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: AppColors.welcomeGradientStart.withOpacity(0.4),
        blurRadius: 20,
        offset: Offset(0, 10),
  )],
    border: Border.all(
      color: AppColors.softWhite.withOpacity(0.3),
      width: 1,
    ),
  );

  static BoxDecoration welcomeLogoDecoration = BoxDecoration(
    gradient: RadialGradient(
      colors: [
        AppColors.softWhite.withOpacity(0.2),
        AppColors.welcomeGradientMiddle.withOpacity(0.4),
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: AppColors.welcomeGradientStart.withOpacity(0.2),
        blurRadius: 15,
        spreadRadius: 2,
      ),
    ],
  );

  static ButtonStyle welcomeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppColors.softWhite,
    foregroundColor: AppColors.welcomeGradientStart,
    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 8,
    shadowColor: AppColors.welcomeGradientStart.withOpacity(0.4),
  );

}
