import 'package:flutter/material.dart';
import '../models/translation.dart';

class PoseRecognitionPage extends StatefulWidget {
  const PoseRecognitionPage({super.key});

  @override
  State<PoseRecognitionPage> createState() => _PoseRecognitionPageState();
}

class _PoseRecognitionPageState extends State<PoseRecognitionPage>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  String? _currentPose;
  TranslationMeaning? _currentEmotion;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startAnalysis() {
    setState(() {
      _isAnalyzing = true;
    });
    _pulseController.repeat();

    // 模擬分析過程
    Future.delayed(const Duration(seconds: 2), () {
      _simulateResult();
    });
  }

  void _simulateResult() {
    // 模擬姿勢分析結果
    final results = [
      ('尾巴豎直向上', TranslationMeaning.love, '🐱 開心問候！你的貓看到你很高興'),
      ('耳朵向前', TranslationMeaning.play, '🎾 好奇興奮！你的貓想要玩耍'),
      ('瞳孔放大', TranslationMeaning.fear, '😿 有些害怕！環境可能有威脅'),
      ('揉麵包', TranslationMeaning.love, '💕 滿足幸福！你的貓很放鬆'),
      ('飛機耳', TranslationMeaning.angry, '😾 緊張警戒！不要突然靠近'),
    ];

    final result = results[DateTime.now().second % results.length];
    setState(() {
      _currentPose = result.$1;
      _currentEmotion = result.$2;
      _isAnalyzing = false;
    });
    _pulseController.stop();

    _showResultDialog(result.$1, result.$2, result.$3);
  }

  void _showResultDialog(String pose, TranslationMeaning emotion, String advice) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              emotion.emoji,
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              pose,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              advice,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('完成', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('姿勢辨識'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 說明
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.orange),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '姿勢辨識',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '對準你的貓，AI 會分析姿勢和情緒',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 相機預覽區
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isAnalyzing) ...[
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 120 + (_pulseController.value * 20),
                            height: 120 + (_pulseController.value * 20),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(
                                alpha: 0.3 * (1 - _pulseController.value),
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '🔍 分析中...',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '請將貓咪保持在畫面中',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.pets,
                          size: 64,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '對準你的貓',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '按下按鈕開始姿勢分析',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 按鈕
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
                onPressed: _isAnalyzing ? null : _startAnalysis,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isAnalyzing ? Icons.hourglass_top : Icons.camera_alt),
                    const SizedBox(width: 8),
                    Text(
                      _isAnalyzing ? '分析中...' : '開始姿勢分析',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
