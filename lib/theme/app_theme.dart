import 'package:flutter/material.dart';

class AppTheme {
  // Background
  static const Color bgPrimary = Color(0xFF14121B);
  static const Color bgGradientTop = Color(0xFF2D293A);

  // Accent
  static const Color accent = Color(0xFFF62C55);
  static const Color accentHover = Color(0xFFFF4069);
  static const Color accentPurple = Color(0xFFC934E1);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);
  static const Color textQuaternary = Color(0x59FFFFFF);

  // Border
  static const Color borderDefault = Color(0x1AFFFFFF);
  static const Color borderHover = Color(0x33FFFFFF);

  // Glass panel
  static const Color glassBg = Color(0x8C14121B);
  static const Color glassBorder = Color(0x14FFFFFF);

  // Priority colors
  static const Color priorityHigh = Color(0xFFFF4D4F);
  static const Color priorityMedium = Color(0xFFFAAD14);
  static const Color priorityLow = Color(0xFF6BAB45);

  // Stats
  static const Color statActive = Color(0xFFF62C55);
  static const Color statDone = Color(0xFF6BAB45);
  static const Color statTotal = Color(0xFF4A88FF);

  // Categories
  static const Color catWork = Color(0xFF4A88FF);
  static const Color catPersonal = Color(0xFFC934E1);
  static const Color catShopping = Color(0xFFFAAD14);
  static const Color catOther = Color(0xFF6BAB45);

  // Shader colors
  static const Color shaderCore = Color(0xFFFFFFFF);
  static const Color shaderFringe = Color(0xFF4A88FF);

  // Todo item
  static const Color itemBg = Color(0x08FFFFFF);
  static const Color itemBgHover = Color(0x0FFFFFFF);
  static const Color itemBorder = Color(0x0FFFFFFF);

  // Input
  static const Color inputBg = Color(0x0DFFFFFF);
  static const Color inputBorder = Color(0x14FFFFFF);

  // Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Animation durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animSlower = Duration(milliseconds: 800);

  static String priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '高';
      case 'medium':
        return '中';
      case 'low':
        return '低';
      default:
        return '中';
    }
  }

  static Color priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return priorityHigh;
      case 'medium':
        return priorityMedium;
      case 'low':
        return priorityLow;
      default:
        return priorityMedium;
    }
  }

  static String categoryLabel(String category) {
    switch (category) {
      case 'work':
        return '工作';
      case 'personal':
        return '个人';
      case 'shopping':
        return '购物';
      default:
        return '其他';
    }
  }

  static Color categoryColor(String category) {
    switch (category) {
      case 'work':
        return catWork;
      case 'personal':
        return catPersonal;
      case 'shopping':
        return catShopping;
      default:
        return catOther;
    }
  }

  static IconData categoryIcon(String category) {
    switch (category) {
      case 'work':
        return Icons.work_outline_rounded;
      case 'personal':
        return Icons.person_outline_rounded;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
