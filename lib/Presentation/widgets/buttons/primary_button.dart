import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:opti_app/core/styles/colors.dart';
import 'package:opti_app/core/styles/text_styles.dart';  // Importez AppTextStyle si nécessaire

class PrimaryButton extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? borderColor;
  final TextStyle? textStyle;
  final bool? disabled;
  final void Function()? click;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.click,
    this.color,
    this.borderColor,
    this.textStyle,
    this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 50.h,
        minHeight: 50.h,
        minWidth: double.infinity,
        maxWidth: double.infinity,
      ),
      child: ElevatedButton(
  onPressed: disabled ?? false ? null : click,
  style: ButtonStyle(
    backgroundColor: MaterialStateProperty.all(disabled ?? false ? AppColors.grey : color ?? AppColors.primary),
    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
        side: BorderSide(color: disabled ?? false ? AppColors.grey : borderColor ?? AppColors.primary),
      ),
    ),
  ),
  child: Text(
    text,
  //  style: textStyle ?? AppTextStyle.buttonTextStyle,  // Utilisation de AppTextStyle
  ),
)

    );
  }
}
