import 'package:flutter/material.dart';
import '../widgets/top_toast.dart';

/// 全 App TopToast 統一入口 service。
///
/// 使用方式：
///   TopToastService.success(context, message: '儲存成功 🐾');
///   TopToastService.error(context, message: '失敗了');
///   TopToastService.info(context, message: '即將推出 🐾');
///   TopToastService.show(context, message: '...');
///
/// 不再需要每個 screen 都 import '../widgets/top_toast.dart'。
class TopToastService {
  /// 顯示自定義 toast，可指定樣式。
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color backgroundColor = const Color(0xFFFF8FAB),
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
    double height = 56,
  }) {
    TopToast.show(
      context,
      message: message,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration,
      height: height,
    );
  }

  /// 成功提示（粉色）。
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    TopToast.success(context, message: message, duration: duration);
  }

  /// 錯誤提示（紅色，預設 3 秒）。
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    TopToast.error(context, message: message, duration: duration);
  }

  /// 資訊提示（粉色）。
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    TopToast.info(context, message: message, duration: duration);
  }

  /// 警告提示（橙色）。
  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    TopToast.warning(context, message: message, duration: duration);
  }
}
