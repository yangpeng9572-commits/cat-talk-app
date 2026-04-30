import 'package:flutter/material.dart';
import '../theme/kawaii_theme.dart';

/// 她喜歡你嗎 💗 - 迷你遊戲頁面
class LoveMeterPage extends StatefulWidget {
  const LoveMeterPage({super.key});

  @override
  State<LoveMeterPage> createState() => _LoveMeterPageState();
}

class _LoveMeterPageState extends State<LoveMeterPage> {
  bool _isTesting = false;
  bool _showResult = false;
  int _loveScore = 0;
  String _loveMessage = '';

  final List<String> _messages = [
    '她其實很黏你，只是裝酷 💕',
    '她喜歡你的機率很高喔！😻',
    '你們的默契需要再培养一下 🐾',
    '她今天心情不錯，對你特別友善 💗',
    '她在偷偷觀察你的一舉一動 👀',
  ];

  void _startTest() async {
    setState(() {
      _isTesting = true;
      _showResult = false;
    });

    // 模擬測試過程
    await Future.delayed(const Duration(seconds: 2));

    // 產生隨機結果
    final score = 65 + (DateTime.now().millisecond % 30);
    final messageIndex = DateTime.now().second % _messages.length;

    setState(() {
      _loveScore = score;
      _loveMessage = _messages[messageIndex];
      _isTesting = false;
      _showResult = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        title: const Text('她喜歡你嗎 💗'),
        backgroundColor: Colors.white,
        foregroundColor: KawaiiTheme.textPrimary,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              KawaiiTheme.softPink.withOpacity(0.3),
              KawaiiTheme.peach.withOpacity(0.2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // 愛心圖示
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Text('💗', style: TextStyle(fontSize: 80)),
                ),

                const SizedBox(height: 32),

                // 標題
                const Text(
                  '她喜歡你嗎 💗',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: KawaiiTheme.textPrimary,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  '看看你們今天的親密度',
                  style: TextStyle(
                    fontSize: 16,
                    color: KawaiiTheme.textSecondary,
                  ),
                ),

                const SizedBox(height: 48),

                // 測試區域
                if (_isTesting) ...[
                  const CircularProgressIndicator(color: KawaiiTheme.primaryPink),
                  const SizedBox(height: 24),
                  const Text(
                    '🐱 正在分析你們的默契...',
                    style: TextStyle(fontSize: 16, color: KawaiiTheme.textSecondary),
                  ),
                ] else if (_showResult) ...[
                  // 顯示結果
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.pink.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_loveScore%',
                          style: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: KawaiiTheme.primaryPink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '她喜歡你！',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: KawaiiTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _loveMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: KawaiiTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // 再測一次按鈕
                  ElevatedButton.icon(
                    onPressed: _startTest,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再測一次'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ] else ...[
                  // 開始測試按鈕
                  ElevatedButton.icon(
                    onPressed: _startTest,
                    icon: const Icon(Icons.favorite, size: 28),
                    label: const Text('開始測試', style: TextStyle(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 8,
                      shadowColor: KawaiiTheme.primaryPink.withOpacity(0.4),
                    ),
                  ),
                ],

                const Spacer(),

                // 溫馨提示
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('💡', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '這個測試僅供娛樂參考，貓咪的心情會因為很多因素改變喔！',
                          style: TextStyle(
                            fontSize: 12,
                            color: KawaiiTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
