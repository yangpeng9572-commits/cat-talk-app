import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';
import '../models/translation.dart';
import '../models/translation_result.dart';
import '../models/daily_task.dart';
import '../services/meow_translation_service.dart';
import '../services/translation_history_service.dart';
import '../services/cat_learning_service.dart';
import '../services/daily_task_service.dart';
import '../services/streak_service.dart';
import 'pose_recognition_page.dart';
import 'daily_report_page.dart';
import '../widgets/emotion_card.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/daily_task_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  Cat? selectedCat;
  List<Translation> translations = [];
  bool isRecording = false;
  bool _showOnboarding = false;
  bool _isAnalyzing = false;
  bool _isLoading = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // 翻譯服務
  final MeowTranslationService _translationService = MeowTranslationService();
  final TranslationHistoryService _historyService = TranslationHistoryService();
  final CatLearningService _learningService = CatLearningService();

  // 任務服務
  late DailyTaskService _taskService;
  late StreakService _streakService;
  List<DailyTask> _todayTasks = [];
  int _currentStreak = 0;

  @override
  void initState() {
    super.initState();
    selectedCat = Cat.getDemoCats().first;
    _initServices();
    _checkOnboarding();

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

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _taskService = DailyTaskService(prefs);
    _streakService = StreakService(prefs);
    _loadTaskData();
  }

  void _loadTaskData() {
    setState(() {
      _todayTasks = _taskService.getTodayTasks();
      _currentStreak = _streakService.getCurrentStreak();
      _isLoading = false;
    });
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
    if (!hasSeenOnboarding) {
      setState(() => _showOnboarding = true);
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    setState(() => _showOnboarding = false);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _startRecording() {
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

  Future<void> _simulateTranslation() async {
    if (selectedCat == null) return;

    setState(() => _isAnalyzing = true);

    // 模擬錄音延遲（至少 1 秒）
    await Future.delayed(const Duration(milliseconds: 1200));

    // 使用 Rule-based 翻譯服務
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

    // 更新任務進度
    await _updateTaskProgress(TaskType.translate_meow);

    setState(() => _isAnalyzing = false);

    // 顯示情緒卡片
    _showEmotionCard(adjustedResult);
  }

  Future<void> _updateTaskProgress(TaskType type, {int delta = 1}) async {
    final updatedTask = await _taskService.updateTaskProgress(type, delta: delta);
    
    if (updatedTask != null && updatedTask.isCompleted) {
      // 任務完成，獎勵 exp 並記錄連續
      await _streakService.recordActivity(expReward: updatedTask.rewardExp);
    }

    _loadTaskData();
  }

  void _showEmotionCard(TranslationResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => EmotionCard(
        result: result,
        onFeedback: (feedback) {
          Navigator.pop(context);
          _handleFeedback(result, feedback);
        },
        onClose: () => Navigator.pop(context),
        catName: selectedCat?.name ?? '你的貓',
      ),
    );
  }

  Future<void> _handleFeedback(TranslationResult result, UserFeedback feedback) async {
    // 保存回饋到歷史記錄
    _historyService.updateWithFeedback(result, feedback);

    // 學習
    if (!feedback.isCorrect && feedback.correctedEmotion != null) {
      final correctedEmotion = EmotionType.values.firstWhere(
        (e) => e.name == feedback.correctedEmotion,
        orElse: () => EmotionType.other,
      );
      _learningService.learnFromCorrection(result.catId, correctedEmotion);
    } else if (feedback.isCorrect) {
      _learningService.learnFromConfirmation(result.catId, result.emotionType);
    }

    // 更新回饋任務進度
    await _updateTaskProgress(TaskType.give_feedback);

    // 顯示感謝 + 已加入報告提示
    _showThanksAndReportSnackbar(feedback);
  }

  void _showThanksAndReportSnackbar(UserFeedback feedback) {
    String message;
    if (feedback.isCorrect) {
      message = '✅ 我記住了，下次會更準！';
    } else if (feedback.correctedEmotion != null) {
      message = '✅ 好的，我記住了！';
    } else {
      message = '✅ 已記錄你的回饋';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '查看報告',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DailyReportPage(
                  preselectedCatId: selectedCat?.id,
                ),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _onDailyReportViewed() {
    _updateTaskProgress(TaskType.view_daily_report);
  }

  @override
  Widget build(BuildContext context) {
    if (_showOnboarding) {
      return OnboardingOverlay(onComplete: _completeOnboarding);
    }

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
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
                    // 今日任務卡片
                    DailyTaskCard(
                      tasks: _todayTasks,
                      currentStreak: _currentStreak,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatSelector() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showCatSwitcher,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.orange.shade100,
                  child: const Icon(Icons.pets, size: 24, color: Colors.orange),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_vert, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showCatSwitcher,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedCat?.name ?? '選擇貓咪',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    selectedCat?.breed.isNotEmpty == true
                        ? selectedCat!.breed
                        : '英國短毛貓',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PoseRecognitionPage()),
              );
            },
            icon: Icon(Icons.camera_alt, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Column(
          children: [
            const SizedBox(height: 20),

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

                    // 主按鈕
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
                                    isRecording
                                        ? Icons.hearing
                                        : (_isAnalyzing ? Icons.psychology : Icons.pets),
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _isAnalyzing
                                        ? '正在聽...'
                                        : (isRecording ? '正在聽牠說話' : '長按翻譯'),
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

            const SizedBox(height: 24),

            // 錄音提示
            if (isRecording)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🎤 放開就翻譯',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (!_isAnalyzing)
              Text(
                '長按開始翻譯',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReportCard() {
    return GestureDetector(
      onTap: () {
        // 更新任務進度
        _onDailyReportViewed();
        
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
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
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 18,
            ),
          ],
        ),
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
            const Text(
              '選擇貓咪',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...Cat.getDemoCats().map((cat) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.pets, color: Colors.orange),
                  ),
                  title: Text(cat.name),
                  subtitle: Text(cat.breed),
                  trailing: selectedCat?.id == cat.id
                      ? const Icon(Icons.check, color: Colors.orange)
                      : null,
                  onTap: () {
                    setState(() => selectedCat = cat);
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
