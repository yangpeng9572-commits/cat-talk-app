import 'package:flutter/material.dart';

/// 新手引導 Overlay
/// 3 步驟介紹 App 功能
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
      title: '歡迎使用貓語通',
      description: '透過 AI 翻譯你家貓咪的叫聲，了解牠在想什麼',
      highlight: null,
    ),
    _OnboardingStep(
      emoji: '🎤',
      title: '長按錄音',
      description: '長按橘色按鈕，錄下貓叫聲，我會即時翻譯',
      highlight: 'button',
    ),
    _OnboardingStep(
      emoji: '📊',
      title: '每日情緒報告',
      description: '每天看看你家貓咪的情緒報告，更懂牠的需求',
      highlight: 'report',
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
      color: Colors.black.withValues(alpha: 0.85),
      child: SafeArea(
        child: Column(
          children: [
            // 略過按鈕
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  '跳過',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // 內容
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Column(
                key: ValueKey(_currentStep),
                children: [
                  Text(
                    step.emoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    step.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      step.description,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // 進度點
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: index == _currentStep ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == _currentStep
                        ? Colors.orange
                        : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            const SizedBox(height: 40),

            // 按鈕
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _currentStep == _steps.length - 1 ? '開始使用' : '下一步',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
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
  final String? highlight; // 'button' | 'report' | null

  _OnboardingStep({
    required this.emoji,
    required this.title,
    required this.description,
    this.highlight,
  });
}
