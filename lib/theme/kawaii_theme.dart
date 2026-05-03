import 'package:flutter/material.dart';

/// 喵心語 Cat Talk Kawaii 風格主題
/// 柔和 pastel 色調，圓角設計，可愛裝飾
class KawaiiTheme {
  // ===== 主色系 =====
  static const Color primaryPink = Color(0xFFFF8FAB);      // 腮紅粉
  static const Color softPink = Color(0xFFFFB6C1);          // 淺粉
  static const Color creamWhite = Color(0xFFFFF8F0);        // 奶油白
  static const Color peach = Color(0xFFFFE4D6);             // 蜜桃色
  static const Color lavender = Color(0xFFE8D5F5);         // 柔紫
  static const Color mintGreen = Color(0xFFB8E8D4);         // 薄荷綠
  
  // ===== 輔助色 =====
  static const Color coral = Color(0xFFFF7F7F);             // 珊瑚紅（主要 CTA）
  static const Color warmYellow = Color(0xFFFFD700);        // 暖黃（星星/成就）
  static const Color softBlue = Color(0xFFB5D4F5);          // 柔藍
  static const Color softPurple = Color(0xFFD4B5F5);         // 柔紫
  
  // ===== 文字色 =====
  static const Color textPrimary = Color(0xFF4A3728);       // 深棕（主要文字）
  static const Color textSecondary = Color(0xFF8B7355);     // 中棕（次要文字）
  static const Color textLight = Color(0xFFBBA89A);         // 淺棕（輔助文字）
  
  // ===== 背景色 =====
  static const Color background = Color(0xFFFFF5F5);          // 極淡粉
  static const Color cardBackground = Colors.white;           // 卡片白
  static const Color divider = Color(0xFFFFE4E4);            // 分隔線
  
  // ===== 陰影 =====
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: primaryPink.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryPink.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // ===== 圓角 =====
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusCircle = 100.0;
  
  // ===== 按鈕樣式 =====
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: coral,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusCircle),
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
  
  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: softPink.withValues(alpha: 0.3),
    foregroundColor: primaryPink,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusLarge),
    ),
  );
  
  // ===== 卡片樣式 =====
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackground,
    borderRadius: BorderRadius.circular(radiusLarge),
    boxShadow: cardShadow,
  );
  
  // ===== 漸層 =====
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryPink, coral],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient get softPinkGradient => LinearGradient(
    colors: [softPink.withValues(alpha: 0.5), peach.withValues(alpha: 0.5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  // ===== 主題資料 =====
  static ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // 配色
    primaryColor: primaryPink,
    scaffoldBackgroundColor: background,
    colorScheme: ColorScheme.light(
      primary: primaryPink,
      secondary: peach,
      tertiary: lavender,
      surface: cardBackground,
      onPrimary: Colors.white,
      onSecondary: textPrimary,
      onSurface: textPrimary,
    ),
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: textPrimary),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // 卡片
    cardTheme: CardThemeData(
      color: cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    
    // 按鈕
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: primaryButtonStyle,
    ),
    
    // 文字按鈕
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryPink,
      ),
    ),
    
    // 輸入框
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: creamWhite,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    
    // 底部導航
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: cardBackground,
      selectedItemColor: primaryPink,
      unselectedItemColor: textLight,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 12,
      ),
    ),
    
    // 文字主題
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: TextStyle(
        color: textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(
        color: textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: TextStyle(
        color: textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        color: textPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: textSecondary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        color: textLight,
        fontSize: 12,
      ),
    ),
    
    // 進度條
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primaryPink,
      linearTrackColor: softPink,
    ),
    
    // 滑塊
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryPink,
      inactiveTrackColor: softPink,
      thumbColor: coral,
      overlayColor: primaryPink.withValues(alpha: 0.2),
      trackHeight: 8,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
    ),
  );
}
