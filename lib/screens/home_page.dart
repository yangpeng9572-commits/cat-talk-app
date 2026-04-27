import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../models/translation.dart';
import '../models/translation_result.dart';
import '../services/meow_translation_service.dart';
import '../services/translation_history_service.dart';
import '../services/cat_learning_service.dart';
import 'pose_recognition_page.dart';
import 'daily_report_page.dart';
import '../widgets/emotion_card.dart';

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

  // 翻譯服務
  final MeowTranslationService _translationService = MeowTranslationService();
  final TranslationHistoryService _historyService = TranslationHistoryService();
  final CatLearningService _learningService = CatLearningService();

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
    // 檢查是否有選擇貓咪
    if (selectedCat == null) {
      _showNoCatSelectedDialog();
      return;
    }

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

  void _showNoCatSelectedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🐱 ', style: TextStyle(fontSize: 28)),
            Text('請先選擇貓咪'),
          ],
        ),
        content: const Text(
          '翻譯功能需要知道是哪一隻貓在叫，這樣才能參考過去的回饋紀錄喔！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              _showCatSwitcher();
            },
            child: const Text('選擇貓咪'),
          ),
        ],
      ),
    );
  }

  void _simulateTranslation() async {
    if (selectedCat == null) return;

    // 顯示錄音中提示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 12),
            const Text('分析中...'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 使用 Rule-based 翻譯服務（傳入貓咪 ID）
    final audioPath = '/mock/cat_meow_${DateTime.now().millisecondsSinceEpoch}';
    final result = await _translationService.analyzeAudio(
      audioPath,
      catId: selectedCat!.id,
    );

    // 加入貓咪學習調整
    final adjustedResult = _learningService.adjustResultWithLearning(
      result,
      result.audioFeatures!,
    );

    // 保存到歷史記錄
    _historyService.add(adjustedResult);

    // 顯示情緒卡片
    _showEmotionCard(adjustedResult);
  }

  void _showEmotionCard(TranslationResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmotionCard(
        result: result,
        onFeedback: (feedback) {
          // 處理回饋
          Navigator.pop(context);
          _handleFeedback(result, feedback);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _handleFeedback(TranslationResult result, UserFeedback feedback) {
    // 保存回饋到歷史記錄
    _historyService.updateWithFeedback(result, feedback);

    // 學習：如果是修正，更新貓咪學習資料
    if (!feedback.isCorrect && feedback.correctedEmotion != null) {
      final correctedEmotion = EmotionType.values.firstWhere(
        (e) => e.name == feedback.correctedEmotion,
        orElse: () => EmotionType.other,
      );
      _learningService.learnFromCorrection(result.catId, correctedEmotion);
    } else if (feedback.isCorrect) {
      // 確認也是一種學習
      _learningService.learnFromConfirmation(result.catId, result.emotionType);
    }

    // 根據回饋類型顯示不同的感謝訊息
    String thanksMessage;
    if (feedback.isCorrect) {
      thanksMessage = '謝謝你的回饋！🐱\n我越來越懂牠了～';
    } else if (feedback.correctedEmotion != null) {
      final correctedEmotion = EmotionType.values.firstWhere(
        (e) => e.name == feedback.correctedEmotion,
        orElse: () => EmotionType.other,
      );
      thanksMessage = '好的，我記住了！\n${correctedEmotion.emoji} ${correctedEmotion.label}';
    } else if (feedback.comment != null && feedback.comment!.isNotEmpty) {
      thanksMessage = '📝 已記錄你的備註\n"${feedback.comment!}"';
    } else {
      thanksMessage = '謝謝修正，之後會更懂牠 🐱';
    }

    // 顯示感謝彈窗
    showFeedbackThanksDialog(context, thanksMessage);

    // TODO: 未來可以把回饋存入本地端，用於個別貓咪學習
    // _saveFeedbackForLearning(result.catId, feedback);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildCatSelector(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMainButton(),
                    _buildDailyReportCard(),
                    if (translations.isNotEmpty) _buildRecentTranslations(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 每日報告卡片
  Widget _buildDailyReportCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DailyReportPage(
              preselectedCatId: selectedCat?.id,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade400, Colors.orange.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('📊', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日貓咪報告',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '看看${selectedCat?.name ?? "你的貓"}今天的情緒',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
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
                // TODO: 導航到添加貓咪頁面
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
          // 新手提示（第一次使用時）
          if (selectedCat != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '長按橘色按鈕錄下貓叫聲，我會推測${selectedCat!.name}可能想表達什麼',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
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