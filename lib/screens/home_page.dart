import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/cat.dart';
import '../models/translation.dart';
import '../models/translation_result.dart';
import '../models/daily_task.dart';
import '../models/achievement.dart';
import '../services/meow_translation_service.dart';
import '../services/translation_history_service.dart';
import '../services/cat_learning_service.dart';
import '../services/daily_task_service.dart';
import '../services/streak_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/achievement_service.dart';
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
  bool _isPermissionDenied = false;
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

  // 錄音服務
  final AudioRecorderService _recorderService = AudioRecorderService();
  
  // 成就服務
  AchievementService? _achievementService;

  // Timer for max recording duration
  Timer? _maxDurationTimer;

  @override
  void initState() {
    super.initState();
    selectedCat = Cat.getDemoCats().first;
    _initServices();
    _checkOnboarding();
    _checkPermission();

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
    _achievementService = AchievementService(prefs);
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

  Future<void> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isPermanentlyDenied) {
      setState(() => _isPermissionDenied = true);
    }
  }
  
  Future<void> _checkAndUnlockAchievements() async {
    if (_achievementService == null) return;
    
    final newUnlocked = await _achievementService!.recordAction('translation');
    
    // 如果有新解鎖的成就，顯示通知
    for (final achievement in newUnlocked) {
      if (mounted) {
        _showAchievementUnlockedSnackbar(achievement);
      }
    }
  }
  
  void _showAchievementUnlockedSnackbar(Achievement achievement) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Text(achievement.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '🎉 成就解鎖！',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(achievement.name),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
    _maxDurationTimer?.cancel();
    _recorderService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (selectedCat == null) {
      _showNoCatSelectedDialog();
      return;
    }

    // 檢查權限
    if (_isPermissionDenied) {
      _showPermissionDeniedDialog();
      return;
    }

    final hasPermission = await _recorderService.checkAndRequestPermission();
    if (!hasPermission) {
      // 檢查是否是永久拒絕
      final status = await Permission.microphone.status;
      if (status.isPermanentlyDenied) {
        setState(() => _isPermissionDenied = true);
        _showPermissionDeniedDialog();
      } else {
        _showSnackBar('需要麥克風權限才能錄音喔！', isError: true);
      }
      return;
    }

    // 開始錄音
    final success = await _recorderService.startRecording();
    if (!success) {
      // Fallback to mock
      debugPrint('錄音失敗，使用 Mock');
      _startMockRecording();
      return;
    }

    setState(() => isRecording = true);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // 設定 10 秒最大錄音計時器
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(
      const Duration(milliseconds: AudioRecorderService.maxDurationMs),
      () {
        if (isRecording) {
          debugPrint('達到最大錄音時長，自動停止');
          _stopRecording();
        }
      },
    );
  }

  void _startMockRecording() {
    // Mock 錄音（用於測試或沒有權限時）
    setState(() => isRecording = true);
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Mock 最多 3 秒
    _maxDurationTimer?.cancel();
    _maxDurationTimer = Timer(const Duration(seconds: 3), () {
      if (isRecording) {
        _stopRecording();
      }
    });
  }

  Future<void> _stopRecording() async {
    _maxDurationTimer?.cancel();

    setState(() => isRecording = false);
    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();
    _waveController.reset();

    // 嘗試真實錄音
    final realRecording = await _recorderService.stopRecording();

    if (realRecording == null) {
      // 錄音尚未開始（用戶按了按鈕但還沒開始就放開）
      debugPrint('錄音尚未開始');
      return;
    }

    if (realRecording.isSuccess) {
      // 真實錄音成功
      await _processTranslation(realRecording.path!);
    } else if (realRecording.isTooShort) {
      // 錄音太短
      _showSnackBar('錄音太短，再試一次 🐱', isError: true);
    } else {
      // 錄音失敗，使用 Mock
      await _processMockTranslation();
    }
  }

  Future<void> _processTranslation(String audioPath) async {
    if (selectedCat == null) return;

    setState(() => _isAnalyzing = true);

    try {
      // 使用翻譯服務分析音訊
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
      
      // 更新成就進度
      await _checkAndUnlockAchievements();

      setState(() => _isAnalyzing = false);

      // 顯示情緒卡片
      _showEmotionCard(adjustedResult);
    } catch (e) {
      debugPrint('翻譯失敗: $e');
      setState(() => _isAnalyzing = false);
      _showSnackBar('翻譯失敗了，再試一次吧 🐱', isError: true);
    }
  }

  Future<void> _processMockTranslation() async {
    if (selectedCat == null) return;

    setState(() => _isAnalyzing = true);

    // 使用 Mock 音訊路徑
    await Future.delayed(const Duration(milliseconds: 800));

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

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🎤 ', style: TextStyle(fontSize: 28)),
            Text('需要麥克風權限'),
          ],
        ),
        content: const Text(
          '貓語通需要麥克風權限才能錄下貓咪的叫聲。\n\n請到設定中開啟麥克風權限，這樣才能使用翻譯功能喔！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text('開啟設定'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
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
