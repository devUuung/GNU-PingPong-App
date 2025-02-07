import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const TextStyle title = TextStyle(
    color: AppColors.textDark,
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.27,
    fontFamily: 'Roboto',
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textDark,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.50,
    letterSpacing: 0.15,
    fontFamily: 'Roboto',
  );

  static const TextStyle hint = TextStyle(
    color: AppColors.textGray,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.50,
    letterSpacing: 0.15,
    fontFamily: 'Roboto',
  );

  // 필요에 따라 추가
}
