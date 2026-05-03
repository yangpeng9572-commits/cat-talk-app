import 'dart:async';
import 'package:flutter/material.dart';

/// Top-positioned toast notification utility.
/// Use this for success/completion/保存/刪除/新增提示，顯示在螢幕上方。
class TopToast {
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color backgroundColor = const Color(0xFFFF8FAB),
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 2),
    double height = 56,
  }) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _TopToastWidget(
        message: message,
        icon: icon ?? Icons.check_circle,
        backgroundColor: backgroundColor,
        textColor: textColor,
        duration: duration,
        height: height,
      ),
    );

    overlay.insert(overlayEntry);

    Timer(duration + const Duration(milliseconds: 300), () {
      overlayEntry.remove();
    });
  }

  /// Convenience: success toast (green accent)
  static void success(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const Color(0xFFFF8FAB),
      duration: duration,
    );
  }

  /// Convenience: error toast (red accent)
  static void error(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade400,
      duration: duration,
    );
  }

  /// Convenience: info toast (pink accent, same as success)
  static void info(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 2),
  }) {
    show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: const Color(0xFFFF8FAB),
      duration: duration,
    );
  }
}

class _TopToastWidget extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final Duration duration;
  final double height;

  const _TopToastWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.duration,
    required this.height,
  });

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 8,
      left: 16,
      right: 16,
      child: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              color: widget.backgroundColor,
              child: Container(
                height: widget.height,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(widget.icon, color: widget.textColor, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: widget.textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
