import 'dart:math';
import 'package:flutter/material.dart';

/// 成就解鎖慶祝動畫
/// 顯示彩帶飄落 + 彈出提示
class AchievementCelebration extends StatefulWidget {
  final String emoji;
  final String name;
  final String message;
  final VoidCallback? onComplete;

  const AchievementCelebration({
    super.key,
    required this.emoji,
    required this.name,
    this.message = '你越來越懂牠了！',
    this.onComplete,
  });

  @override
  State<AchievementCelebration> createState() => _AchievementCelebrationState();
}

class _AchievementCelebrationState extends State<AchievementCelebration>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _cardController;
  late Animation<double> _cardScale;
  late Animation<double> _cardOpacity;
  final List<ConfettiPiece> _confetti = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // 初始化彩帶
    for (int i = 0; i < 50; i++) {
      _confetti.add(ConfettiPiece(
        x: _random.nextDouble(),
        y: -_random.nextDouble() * 0.5,
        color: _getRandomColor(),
        size: 8 + _random.nextDouble() * 8,
        speed: 0.5 + _random.nextDouble() * 1.5,
        rotation: _random.nextDouble() * 2 * pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.2,
      ));
    }

    // 卡片動畫控制器
    _cardController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _cardScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: Curves.elasticOut,
      ),
    );

    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _cardController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // 彩帶動畫控制器
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        setState(() {
          for (var piece in _confetti) {
            piece.y += piece.speed * 0.02;
            piece.rotation += piece.rotationSpeed;
            if (piece.y > 1.2) {
              piece.y = -0.1;
              piece.x = _random.nextDouble();
            }
          }
        });
      });

    // 啟動動畫
    _cardController.forward();
    _confettiController.forward();

    // 3秒後自動消失
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _cardController.reverse().then((_) {
          widget.onComplete?.call();
        });
      }
    });
  }

  Color _getRandomColor() {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.purple,
      Colors.pink,
      Colors.amber,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Stack(
        children: [
          // 彩帶層
          ..._confetti.map((piece) => Positioned(
                left: piece.x * MediaQuery.of(context).size.width,
                top: piece.y * MediaQuery.of(context).size.height,
                child: Transform.rotate(
                  angle: piece.rotation,
                  child: Container(
                    width: piece.size,
                    height: piece.size * 0.6,
                    decoration: BoxDecoration(
                      color: piece.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              )),

          // 卡片層
          Center(
            child: AnimatedBuilder(
              animation: _cardController,
              builder: (context, child) {
                return Opacity(
                  opacity: _cardOpacity.value,
                  child: Transform.scale(
                    scale: _cardScale.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 標題
                    const Text(
                      '🎉 成就解鎖！',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 成就 emoji
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          widget.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 成就名稱
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 鼓勵文案
                    Text(
                      widget.message,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 點擊關閉提示
                    Text(
                      '點擊任意處關閉',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 點擊關閉
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _cardController.reverse().then((_) {
                  widget.onComplete?.call();
                });
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class ConfettiPiece {
  double x;
  double y;
  final Color color;
  final double size;
  final double speed;
  double rotation;
  final double rotationSpeed;

  ConfettiPiece({
    required this.x,
    required this.y,
    required this.color,
    required this.size,
    required this.speed,
    required this.rotation,
    required this.rotationSpeed,
  });
}
