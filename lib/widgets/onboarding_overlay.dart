import 'package:flutter/material.dart';

/// 新手引導 Overlay
/// 3 步驟介紹 App 功能（暖色系改版）
class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingOverlay({super.key, required this.onComplete});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int _currentStep = 0;

  final List<_OnboardingStep> _steps = [
    _OnboardingStep(
      emoji: '🐱',
      title: '歡迎使用喵心語',
      description: '牠不會說人話，但每一聲喵、每一個動作，\n都可能藏著想告訴你的事。',
    ),
    _OnboardingStep(
      emoji: '🐾',
      title: '陪牠慢慢長大',
      description: '把牠的聲音、互動和小日常記錄下來，\n變成只屬於你們的回憶。',
    ),
    _OnboardingStep(
      emoji: '🌿',
      title: '更懂牠的每一天',
      description: '每天整理牠的心情線索，讓你更快發現\n牠開心、撒嬌或需要你陪的時候。',
    ),
  ];

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  void _skip() {
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFFBF5), // 奶油白
            Color(0xFFFFF0E6), // 米白
            Color(0xFFFFE4CC), // 淡蜜桃
            Color(0xFFEDD9C0), // 奶茶色
          ],
          stops: [0.0, 0.35, 0.65, 1.0],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // 裝飾 - 左上角愛心
            const Positioned(
              top: 60,
              left: 30,
              child: Text('♡', style: TextStyle(fontSize: 28, color: Color(0xFFFFB07C),),),
            ),
            // 裝飾 - 右上角星星
            const Positioned(
              top: 80,
              right: 40,
              child: Text('✦', style: TextStyle(fontSize: 22, color: Color(0xFFFF9E6B),),),
            ),
            // 裝飾 - 左下角圓點
            const Positioned(
              bottom: 140,
              left: 25,
              child: Text('●', style: TextStyle(fontSize: 16, color: Color(0xFFFFCFA0),),),
            ),
            // 裝飾 - 右下角肉球
            Positioned(
              bottom: 100,
              right: 35,
              child: Text('🐾', style: TextStyle(fontSize: 24, color: const Color(0xFFFFB07C).withOpacity(0.6),),),
            ),
            // 裝飾 - 中間小愛心
            const Positioned(
              top: 180,
              right: 60,
              child: Text('♡', style: TextStyle(fontSize: 18, color: Color(0xFFFFCFA0),),),
            ),
            // 裝飾 - 左側小圓
            const Positioned(
              top: 130,
              left: 55,
              child: Text('●', style: TextStyle(fontSize: 12, color: Color(0xFFFFE4CC),),),
            ),
            // 裝飾 - 右側小小星
            const Positioned(
              bottom: 200,
              right: 80,
              child: Text('✦', style: TextStyle(fontSize: 14, color: Color(0xFFFFCFA0),),),
            ),

            // 主內容
            Column(
              children: [
                // 跳過按鈕
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 8),
                    child: TextButton(
                      onPressed: _skip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCFA0).withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '跳過',
                          style: TextStyle(
                            color: Color(0xFF7B4A2D),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Emoji 主視覺區塊
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.55),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFCFA0).withOpacity(0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      step.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // 標題
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF5C2B0C),
                      letterSpacing: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                // 內文
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    step.description,
                    style: const TextStyle(
                      fontSize: 17,
                      color: Color(0xFF8B5A3C),
                      height: 1.7,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                // 進度點
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_steps.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: index == _currentStep ? 28 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: index == _currentStep
                            ? const Color(0xFFFF9E6B) // 暖橘 active
                            : const Color(0xFFFFE4CC).withOpacity(0.5), // 淡米 inactive
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: index == _currentStep
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF9E6B).withOpacity(0.4),
                                  blurRadius: 6,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 44),

                // 按鈕
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF9E6B), Color(0xFFFF7B54)],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF9E6B).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _nextStep,
                        child: Text(
                          _currentStep == _steps.length - 1
                              ? '開始使用 🌟'
                              : '下一步',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String emoji;
  final String title;
  final String description;

  _OnboardingStep({
    required this.emoji,
    required this.title,
    required this.description,
  });
}
