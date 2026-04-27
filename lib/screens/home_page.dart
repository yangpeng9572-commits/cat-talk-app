import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/translation.dart';
import 'pose_recognition_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Cat? selectedCat;
  List<Translation> translations = [];
  bool isRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    selectedCat = Cat.getDemoCats().first;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() => isRecording = true);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
  }

  void _stopRecording() {
    setState(() => isRecording = false);
    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();
    _waveController.reset();
    _simulateTranslation();
  }

  void _simulateTranslation() {
    final meanings = [
      TranslationMeaning.hungry,
      TranslationMeaning.callOwner,
      TranslationMeaning.love,
      TranslationMeaning.play,
    ];
    final meaning = meanings[DateTime.now().second % meanings.length];

    final translation = Translation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      catId: selectedCat?.id ?? '1',
      originalSound: '喵～',
      translation: meaning.label,
      meaning: meaning,
      timestamp: DateTime.now(),
    );

    setState(() {
      translations.insert(0, translation);
    });

    _showTranslationResult(translation);
  }

  void _showTranslationResult(Translation translation) {
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              translation.meaning.emoji,
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 16),
            Text(
              translation.translation,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _getMeaningDescription(translation.meaning),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.edit),
                    label: const Text('修正'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.check),
                    label: const Text('正確'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _getMeaningDescription(TranslationMeaning meaning) {
    switch (meaning) {
      case TranslationMeaning.hungry:
        return '你的貓咪肚子餓了！\n快去準備食物吧～';
      case TranslationMeaning.callOwner:
        return '你的貓咪在呼喚你！\n可能想要你的注意';
      case TranslationMeaning.love:
        return '你的貓咪在表達愛意！\n這是最溫馨的時刻';
      case TranslationMeaning.play:
        return '你的貓咪想玩遊戲！\n拿出逗貓棒吧';
      default:
        return '你的貓咪有話想說～';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCatSelector(),
            Expanded(child: _buildMainButton()),
            if (translations.isNotEmpty) _buildRecentTranslations(),
          ],
        ),
      ),
    );
  }

  Widget _buildCatSelector() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showCatSwitcher,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.pets, size: 28, color: Colors.orange),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedCat?.name ?? '選擇貓咪',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  selectedCat?.breed.isNotEmpty == true ? selectedCat!.breed : '英國短毛貓',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
        ],
      ),
    );
  }

  void _showCatSwitcher() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text('選擇貓咪', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...Cat.getDemoCats().map((cat) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.pets, color: Colors.orange),
                  ),
                  title: Text(cat.name),
                  subtitle: Text(cat.breed),
                  onTap: () {
                    setState(() => selectedCat = cat);
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade200,
                child: const Icon(Icons.add, color: Colors.grey),
              ),
              title: const Text('添加新貓咪'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 波紋效果
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  if (isRecording)
                    ...List.generate(3, (index) {
                      final delay = index * 0.3;
                      final value = (_waveController.value - delay).clamp(0.0, 1.0);
                      final size = 200 + (value * 80);
                      final opacity = (1 - value) * 0.3;
                      return Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: opacity),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                  GestureDetector(
                    onTapDown: (_) => _startRecording(),
                    onTapUp: (_) => _stopRecording(),
                    onTapCancel: _stopRecording,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isRecording ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 180,
                            height: 180,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withValues(alpha: 0.4),
                                  blurRadius: isRecording ? 40 : 20,
                                  spreadRadius: isRecording ? 10 : 0,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isRecording ? Icons.mic : Icons.pets,
                                  size: 56,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isRecording ? '錄音中' : '長按翻譯',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
          Text(
            '長按開始自動翻譯',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          // 姿勢辨識按鈕（我們的差異化功能！）
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              side: const BorderSide(color: Colors.orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PoseRecognitionPage()),
              );
            },
            icon: const Icon(Icons.camera_alt, color: Colors.orange),
            label: const Text(
              '或試試姿勢辨識',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTranslations() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近翻譯',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...translations.take(3).map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(t.meaning.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.translation, style: const TextStyle(fontWeight: FontWeight.w500)),
                          Text(_formatTime(t.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.day == now.day) {
      return '今天 ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}
