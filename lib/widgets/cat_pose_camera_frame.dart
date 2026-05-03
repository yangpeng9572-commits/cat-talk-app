import 'package:flutter/material.dart';

/// 貓咪姿勢拍照框 widget
/// 顯示半透明圓角矩形引導框，提示使用者將貓咪置於框內
class CatPoseCameraFrame extends StatelessWidget {
  const CatPoseCameraFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 自適應框大小，根據螢幕寬度
        final frameWidth = constraints.maxWidth * 0.75;
        final frameHeight = frameWidth * 1.2; // 直立橢圓形

        return Center(
          child: Container(
            width: frameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                // 四角裝飾
                ..._buildCornerDecorations(frameWidth, frameHeight),
                // 中心文字
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '請讓貓咪全身進入框內',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildCornerDecorations(double frameWidth, double frameHeight) {
    const cornerSize = 20.0;
    const cornerThickness = 3.0;
    final cornerColor = Colors.white.withValues(alpha: 0.8);

    return [
      // 左上角
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner('topLeft', cornerColor, cornerSize, cornerThickness),
      ),
      // 右上角
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner('topRight', cornerColor, cornerSize, cornerThickness),
      ),
      // 左下角
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner('bottomLeft', cornerColor, cornerSize, cornerThickness),
      ),
      // 右下角
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner('bottomRight', cornerColor, cornerSize, cornerThickness),
      ),
    ];
  }

  Widget _buildCorner(
    String position,
    Color color,
    double size,
    double thickness,
  ) {
    final isLeft = position.contains('Left');
    final isTop = position.contains('Top');

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          isLeft: isLeft,
          isTop: isTop,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool isLeft;
  final bool isTop;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.isLeft,
    required this.isTop,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isLeft && isTop) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isLeft && !isTop) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (!isLeft && isTop) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
