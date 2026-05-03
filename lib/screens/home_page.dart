import 'dart:async';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../debug/debug_entry_detector.dart';
import '../debug/debug_verification_screen.dart';
import '../models/cat.dart';
import '../models/translation.dart';
import '../models/translation_result.dart';
import '../models/daily_task.dart';
import '../models/daily_cat_report.dart';
import '../models/bond.dart';
import '../models/achievement.dart';
import '../services/meow_translation_service.dart';
import '../services/translation_history_service.dart';
import '../services/cat_learning_service.dart';
import '../services/daily_task_service.dart';
import '../services/daily_report_service.dart';
import '../services/streak_service.dart';
import '../services/audio_recorder_service.dart';
import '../services/achievement_service.dart';
import '../services/cat_service.dart';
import '../services/bond_service.dart';
import '../services/emotional_headline_service.dart';
import '../services/push_notification_service.dart';
import '../services/review_service.dart';
import '../services/cat_birthday_service.dart';
import '../widgets/birthday_gift_dialog.dart';
import 'pose_recognition_page.dart';
import 'daily_report_page.dart';
import 'add_cat_page.dart';
import 'edit_cat_page.dart';
import 'home_interaction_page.dart';
import 'cat_world_page.dart';
import 'love_meter_page.dart';
import '../widgets/emotion_card.dart';
import '../widgets/onboarding_overlay.dart';
import '../widgets/achievement_celebration.dart';
import '../widgets/review_prompt_dialog.dart';
import '../widgets/daily_task_card.dart';
import '../theme/kawaii_theme.dart';
import '../screens/cat_pose_camera_page.dart';

// DEBUG mode - set to true to show debug info
const bool kIsDebugMode = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // ===== 圖片顯示 Helper =====
  Widget _buildCatAvatar(
    String? avatarPath, {
    double radius = 24,
    double iconSize = 24,
    Color backgroundColor = const Color(0xFFFFE0B2),
    Color iconColor = const Color(0xFFFF8A65),
  }) {
    final path = avatarPath;
    final hasValidPath = path != null &&
        path.isNotEmpty &&
        !path.startsWith('content://') &&
        File(path).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasValidPath ? FileImage(File(path)) : null,
      child: hasValidPath
          ? null
          : Icon(
              Icons.pets,
              color: iconColor,
              size: iconSize,
            ),
    );
  }

  Cat? selectedCat;
  List<Translation> translations = [];
  bool isRecording = false;
  bool _showOnboarding = false;
  bool _isAnalyzing = false;
  bool _isLoading = true;
  bool _showCelebration = false;
  Achievement? _pendingAchievement;
  bool _isPermissionDenied = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _waveController;

  // 翻譯服務
  final MeowTranslationService _translationService = MeowTranslationService();
  final TranslationHistoryService _historyService = TranslationHistoryService();
  final CatLearningService _learningService = CatLearningService();
  
  // 每日報告服務
  late DailyReportService _reportService;
  DailyCatReport? _todayReport;
  
  // 情感文案服務
  final EmotionalHeadlineService _headlineService = EmotionalHeadlineService();
  final FeedbackMessageService _feedbackMessageService = FeedbackMessageService();
  
  // 今日文案
  String _todayHeadline = '';
  String _todaySubtitle = '';
  int _todayInteractionCount = 0;
  
  // 默契值
  Bond? _currentBond;
  
  // 推播點擊提示
  bool _showNotificationHint = false;
  String _notificationHintText = '';

  // 任務服務
  late DailyTaskService _taskService;
  late StreakService _streakService;
  List<DailyTask> _todayTasks = [];
  int _currentStreak = 0;

  // 錄音服務
  final AudioRecorderService _recorderService = AudioRecorderService();
  
  // 成就服務
  AchievementService? _achievementService;
  
  // 貓咪服務
  CatService? _catService;
  List<Cat> _cats = [];

  // 生日服務
  final CatBirthdayService _birthdayService = CatBirthdayService();

  // Debug 入口偵測器（長按 5 次）
  late final DebugEntryDetector _debugEntryDetector;

  // Timer for max recording duration
  Timer? _maxDurationTimer;

  @override
  void initState() {
    super.initState();
    // 不再自動選擇示範貓咪
    // selectedCat = Cat.getDemoCats().first;
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

    // 初始化 Debug 入口偵測器（只有在 debug mode + ENABLE_DEBUG_TOOLS 時才會運作）
    _debugEntryDetector = DebugEntryDetector(
      onTriggered: () {
        debugPrint('[Debug] Debug 驗收工具已觸發');
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const DebugVerificationScreen(),
          ),
        );
      },
    );
  }

  Future<void> _initServices() async {
    final prefs = await SharedPreferences.getInstance();
    _taskService = DailyTaskService(prefs);
    _streakService = StreakService(prefs);
    _achievementService = AchievementService(prefs);
    _catService = CatService(prefs);
    
    // 初始化默契值服務
    await BondService().init(prefs);
    
    // 初始化翻譯歷史服務（單例，需要手動 init）
    await TranslationHistoryService().init(prefs);
    
    // 初始化每日報告服務
    _reportService = DailyReportService(
      historyService: TranslationHistoryService(),
      learningService: _learningService,
    );
    await _reportService.init(prefs);
    
    _loadCatData();
    _loadTaskData();
    _refreshEmotionalData();
    _checkNotificationPayload();
  }

  /// 檢查推播點擊payload，顯示提示
  void _checkNotificationPayload() async {
    // 從 SharedPreferences 讀取推播點擊標記
    final prefs = await SharedPreferences.getInstance();
    final clicked = prefs.getBool('notification_clicked');
    
    if (clicked == true) {
      // 清除標記
      await prefs.setBool('notification_clicked', false);
      
      // 根據點擊的推播類型顯示對應提示
      final notificationType = prefs.getString('last_notification_type') ?? 'cat_call';
      
      String hintText;
      switch (notificationType) {
        case 'cat_call':
          hintText = '剛剛她好像在找你 🐾';
          break;
        case 'affectionate':
          hintText = '她今天好像有點黏人 💕';
          break;
        case 'companion':
          hintText = '她在等你陪她喔 🐱';
          break;
        case 'daily_diary':
          hintText = '今天的小日記寫好了 📖';
          break;
        default:
          hintText = '她好像在找你 🐾';
      }
      
      setState(() {
        _showNotificationHint = true;
        _notificationHintText = hintText;
      });
      
      // 2秒後自動隱藏
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _showNotificationHint = false;
          });
        }
      });
    }
  }

  Future<void> _loadCatData() async {
    _cats = _catService!.getAllCats();
    // 自動選擇第一隻貓
    if (_cats.isNotEmpty && selectedCat == null) {
      selectedCat = _cats.first;
    }
  }

  void _loadTaskData() {
    setState(() {
      _todayTasks = _taskService.getTodayTasks();
      _currentStreak = _streakService.getCurrentStreak();
      _isLoading = false;
    });
  }
  
  /// 更新今日情感資料
  void _refreshEmotionalData() {
    if (selectedCat == null) {
      setState(() {
        _todayHeadline = '';
        _todaySubtitle = '';
        _todayInteractionCount = 0;
        _currentBond = null;
        _todayReport = null;
      });
      return;
    }
    
    // 取得今日報告
    _todayReport = _reportService.getTodayReport(selectedCat!.id);
    
    // 取得今日互動次數（從翻譯歷史）
    final todayTranslations = _historyService.getByCatId(selectedCat!.id).where((t) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return t.createdAt.isAfter(today);
    }).toList();
    _todayInteractionCount = todayTranslations.length;
    
    // 取得 dominant emotion
    final dominantEmotion = _todayReport?.dominantEmotion;
    
    // 生成 headline 和 subtitle
    _todayHeadline = _headlineService.getHeadline(
      selectedCat!.name,
      dominantEmotion,
    );
    _todaySubtitle = _headlineService.getSubtitle(
      selectedCat!.name,
      dominantEmotion,
    );
    
    // 取得默契值
    _currentBond = BondService().getBond(selectedCat!.id);
    
    setState(() {});
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
    
    // 如果有新解鎖的成就，顯示慶祝動畫
    for (final achievement in newUnlocked) {
      if (mounted) {
        _pendingAchievement = achievement;
        setState(() => _showCelebration = true);
      }
    }
  }
  
  void _dismissCelebration() {
    setState(() {
      _showCelebration = false;
      _pendingAchievement = null;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    setState(() => _showOnboarding = false);
  }


  /// 公開方法：供 MainScreen 呼叫重新播放新手教程
  void replayOnboarding() {
    setState(() => _showOnboarding = true);
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
      await _historyService.add(adjustedResult);

      // 更新默契值 +2
      await _addBondScore(BondService.eventTranslation, adjustedResult.id, adjustedResult.confidence);

      // 更新任務進度
      await _updateTaskProgress(TaskType.translate_meow);
      
      // 更新成就進度
      await _checkAndUnlockAchievements();
      
      // 檢查是否顯示評價提示
      await showReviewPromptIfNeeded(context);

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
    await _historyService.add(adjustedResult);

    // 更新默契值 +2
    await _addBondScore(BondService.eventTranslation, adjustedResult.id, adjustedResult.confidence);

    // 更新任務進度
    await _updateTaskProgress(TaskType.translate_meow);
    
    // 檢查是否顯示評價提示
    await showReviewPromptIfNeeded(context);

    setState(() => _isAnalyzing = false);

    // 顯示情緒卡片
    _showEmotionCard(adjustedResult);
  }

  /// 新增默契值並顯示提示
  /// [confidence] 翻譯結果信心度，僅當 >= 70 或 null 時才記錄成功互動
  Future<void> _addBondScore(String eventType, [String? translationId, double? confidence]) async {
    if (selectedCat == null) return;
    
    final gain = await BondService().addBond(
      selectedCat!.id,
      eventType,
      translationId: translationId,
    );
    
    if (gain > 0) {
      // 顯示加分提示
      _showBondGainMessage(eventType, gain);
      // 刷新情感資料
      _refreshEmotionalData();
      // 記錄成功互動（翻譯需 confidence >= 70，其他事件直接記錄）
      final shouldRecord = confidence == null || confidence >= 70;
      if (shouldRecord) {
        await ReviewService().recordSuccessfulInteraction();
      }
    }
  }
  
  /// 顯示默契值增加提示
  void _showBondGainMessage(String eventType, int gain) {
    String message;
    switch (eventType) {
      case BondService.eventTranslation:
        message = '你又更懂她一點了 🐾';
        break;
      case BondService.eventFeedback:
        message = '她的習慣被你記住了 💕';
        break;
      case BondService.eventTaskComplete:
        message = '今天的陪伴完成了！';
        break;
      case BondService.eventStreakBonus:
        message = '連續陪伴讓你們更有默契了 ✨';
        break;
      case BondService.eventActionTap:
        message = '她感受到你的回應了 🐾';
        break;
      case BondService.eventViewReport:
        message = '今天更了解她一點了 💕';
        break;
      default:
        message = '+${gain}';
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: KawaiiTheme.primaryPink, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        ),
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.all(16),
      ),
    );
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
          '喵心語需要麥克風權限才能錄下貓咪的叫聲。\n\n請到設定中開啟麥克風權限，這樣才能使用翻譯功能喔！',
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
      // 任務完成，記錄連續（使用默契值，不再用 exp）
      await _streakService.recordActivity(expReward: updatedTask.rewardExp);
      // 更新默契值 +5
      await _addBondScore(BondService.eventTaskComplete);
      // 顯示陪伴型完成提示
      _showBriefToast(_taskService.getTaskCompletionMessage(type));
      // 檢查是否顯示評價提示
      await showReviewPromptIfNeeded(context);
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
        onClose: () {
          Navigator.pop(context);
          // 刷新情感資料
          _refreshEmotionalData();
          // 顯示完成提示
          _showBriefToast(_feedbackMessageService.getTranslationCompletedMessage());
        },
        onActionTap: () {
          // 更新默契值 +1（每筆翻譯最多一次）
          _addBondScore(BondService.eventActionTap, result.id);
        },
        catName: selectedCat?.name ?? '你的貓',
      ),
    );
  }
  
  /// 顯示短暫提示（約 1.5 秒）
  void _showBriefToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: KawaiiTheme.primaryPink),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        ),
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.all(16),
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

    // 更新默契值 +3
    await _addBondScore(BondService.eventFeedback, result.id);

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
    // 更新默契值 +1
    _addBondScore(BondService.eventViewReport);
    // 刷新情感資料
    _refreshEmotionalData();
    // 顯示了解提示
    _showBriefToast(_feedbackMessageService.getReportViewedMessage());
    // 檢查是否顯示評價提示
    showReviewPromptIfNeeded(context);
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

    // 成就慶祝動畫（覆蓋層）
    if (_showCelebration && _pendingAchievement != null) {
      return Material(
        color: Colors.transparent,
        child: AchievementCelebration(
          emoji: _pendingAchievement!.emoji,
          name: _pendingAchievement!.name,
          message: '你越來越懂牠了！',
          onComplete: _dismissCelebration,
        ),
      );
    }

    // 沒有貓咪的引導頁面
    if (_cats.isEmpty || selectedCat == null) {
      return Scaffold(
        backgroundColor: KawaiiTheme.background,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: KawaiiTheme.softPink.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets,
                      size: 64,
                      color: KawaiiTheme.primaryPink,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    '先讓我認識你的貓咪吧 🐱',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: KawaiiTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '新增貓咪後，我會幫你記錄牠的叫聲、情緒和每日狀態。',
                    style: TextStyle(
                      fontSize: 16,
                      color: KawaiiTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final newCatId = await Navigator.push<String?>(
                        context,
                        MaterialPageRoute(builder: (context) => const AddCatPage()),
                      );
                      if (newCatId != null) {
                        await _loadCatData();
                        if (!mounted) return;
                        setState(() {});
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('新增我的貓咪'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.primaryPink,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // DEBUG BANNER - 永遠顯示在最上方
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.red,
              child: const Text(
                '🐛 DEBUG BUILD: 2026-04-29-FINAL-VERIFY-001',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Debug 入口：長按 / 點擊貓咪選擇器區域 5 次
            if (kDebugMode)
              GestureDetector(
                onTap: () => _debugEntryDetector.recordTap(),
                child: _buildCatSelector(),
              )
            else
              _buildCatSelector(),
            // 推播點擊提示（2秒後消失）
            if (_showNotificationHint)
              _buildNotificationHintBanner(),
            // 今日情感狀態區塊（新增）
            _buildEmotionalStatusBlock(),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildMainButton(),
                    _buildDailyReportCard(),
                    _buildInteractionCard(),
                    _buildBirthdayCard(),
                    _buildCatWorldCard(),
                    _buildPoseCameraCard(),
                    if (selectedCat != null) _buildLoveMeterCard(),
                    // 今日任務卡片
                    DailyTaskCard(
                      tasks: _todayTasks,
                      currentStreak: _currentStreak,
                    ),
                    // DEBUG 資訊
                    if (kIsDebugMode) _buildDebugInfo(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// DEBUG 資訊區塊
  Widget _buildDebugInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🐛 DEBUG BUILD: 2026-04-29-REAL-FIX',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _debugRow('app_version', '2026-04-29-REAL-FIX'),
          _debugRow('cats_count', _cats.length.toString()),
          _debugRow('selectedCat_id', selectedCat?.id ?? 'null'),
          _debugRow('selectedCat_name', selectedCat?.name ?? 'null'),
          _debugRow('bondScore', _currentBond?.bondScore.toString() ?? 'null'),
          _debugRow('todayReport_isEmpty', _todayReport?.isEmpty.toString() ?? 'null'),
          _debugRow('catWorld_accessible', selectedCat != null ? 'true' : 'false'),
          _debugRow('onboarding_done', _showOnboarding ? 'false (showing)' : 'true (skipped)'),
          _debugRow('todayTasks', _todayTasks.length.toString()),
          _debugRow('currentStreak', _currentStreak.toString()),
          const SizedBox(height: 8),
          // 重置新手教學按鈕
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenOnboarding', false);
              await prefs.setBool('hasSeenCatWorld', false);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已重置新手教學，請重啟App')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('🔄 重置新手教學', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _debugRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label + ': ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// 推播點擊提示橫幅（2秒後自動消失）
  Widget _buildNotificationHintBanner() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  KawaiiTheme.primaryPink.withValues(alpha: 0.8),
                  KawaiiTheme.coral.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Row(
              children: [
                const Text('🐱', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _notificationHintText,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                  backgroundImage: selectedCat?.avatarPath != null &&
                      !selectedCat!.avatarPath!.startsWith('content://') &&
                      File(selectedCat!.avatarPath!).existsSync()
                      ? FileImage(File(selectedCat!.avatarPath!))
                      : null,
                  child: selectedCat?.avatarPath != null &&
                          !selectedCat!.avatarPath!.startsWith('content://') &&
                          File(selectedCat!.avatarPath!).existsSync()
                      ? null
                      : const Icon(Icons.pets, size: 24, color: Colors.orange),
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
        ],
      ),
    );
  }

  /// 今日情感狀態區塊
  Widget _buildEmotionalStatusBlock() {
    final emotion = _todayReport?.dominantEmotion;
    final emotionTag = _headlineService.getEmotionTag(emotion);
    final emotionEmoji = _headlineService.getEmotionEmoji(emotion);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KawaiiTheme.softPink.withValues(alpha: 0.6),
            KawaiiTheme.peach.withValues(alpha: 0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: KawaiiTheme.primaryPink.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Text(
            _todayHeadline.isNotEmpty ? _todayHeadline : '今天也來聽聽她的聲音吧 🐾',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: KawaiiTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            _todaySubtitle.isNotEmpty ? _todaySubtitle : '長按錄音，記錄今天第一聲喵',
            style: TextStyle(
              fontSize: 12,
              color: KawaiiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          // Tags row
          Row(
            children: [
              // 情緒 tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emotionEmoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      '今日心情：$emotionTag',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 互動次數
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 12, color: KawaiiTheme.primaryPink),
                    const SizedBox(width: 4),
                    Text(
                      '今日互動：$_todayInteractionCount 次',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 默契值 progress bar
          _buildBondProgressBar(),
        ],
      ),
    );
  }

  /// 默契值進度條
  Widget _buildBondProgressBar() {
    final bond = _currentBond;
    
    if (bond == null) {
      // 沒有默契值資料
      return Row(
        children: [
          const Icon(Icons.favorite, size: 16, color: KawaiiTheme.primaryPink),
          const SizedBox(width: 8),
          Text(
            '默契值：剛開始建立中',
            style: TextStyle(
              fontSize: 13,
              color: KawaiiTheme.textSecondary,
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.favorite, size: 16, color: KawaiiTheme.coral),
            const SizedBox(width: 8),
            Text(
              '默契值',
              style: TextStyle(
                fontSize: 13,
                color: KawaiiTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              bond.levelEmoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              bond.levelName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: KawaiiTheme.coral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: bond.bondScore / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          KawaiiTheme.primaryPink,
                          KawaiiTheme.coral,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 36,
              child: Text(
                '${bond.bondScore}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: KawaiiTheme.coral,
                ),
              ),
            ),
          ],
        ),
      ],
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

            // 雙主按鈕設計
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // 錄音翻譯按鈕
                  Expanded(
                    child: _buildRecordButton(),
                  ),
                  const SizedBox(width: 16),
                  // 貓咪動作庫按鈕
                  Expanded(
                    child: _buildPoseButton(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 錄音翻譯按鈕（已停用功能入口，保留方法以避免破壞相依）
  Widget _buildRecordButton() {
    return const SizedBox.shrink();
  }
  /// 貓咪動作庫按鈕
  Widget _buildPoseButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PoseRecognitionPage()),
        );
      },
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF9B8DC7), Color(0xFF6B5B95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5B95).withValues(alpha: 0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '🐱 貓咪動作庫',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              '🐱 貓咪動作庫',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
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
            colors: [
              KawaiiTheme.primaryPink.withValues(alpha: 0.9),
              KawaiiTheme.coral,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: KawaiiTheme.primaryPink.withValues(alpha: 0.3),
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
              child: const Text('💕', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日報告',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '看看${selectedCat?.name ?? "你的貓"}今天過得怎麼樣',
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

  /// 貓咪小日常互動卡片
  Widget _buildInteractionCard() {
    return GestureDetector(
      onTap: () {
        if (selectedCat != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomeInteractionPage(cat: selectedCat!),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB6C1), Color(0xFFFFE4E1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C1).withValues(alpha: 0.3),
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
              child: const Text('🐱', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🐱 貓咪小日常',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '陪她玩一下 💗',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9B8B8B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFF9B8B8B), size: 18),
          ],
        ),
      ),
    );
  }

  /// 她的小世界入口卡片
  Widget _buildCatWorldCard() {
    if (selectedCat == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CatWorldPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFF8F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFB6C1).withValues(alpha: 77/255)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C1).withValues(alpha: 51/255),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('🏡', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '她的小世界 🏡',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentBond != null
                        ? '目前默契：${_currentBond!.bondScore}%'
                        : '從今天開始慢慢佈置她的小世界',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9B8B8B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Color(0xFFB0A0A0), size: 16),
          ],
        ),
      ),
    );
  }


  /// 貓咪姿勢拍照入口卡片
  Widget _buildPoseCameraCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CatPoseCameraPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8B7FBF), Color(0xFF6B5B95)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6B5B95).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('📷', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '🐱 貓咪姿勢拍照',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '拍下主子的姿勢，之後可以用來分析狀態',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
          ],
        ),
      ),
    );
  }

  /// 她喜歡你嗎 💗 入口卡片
  Widget _buildLoveMeterCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoveMeterPage()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF69B4), Color(0xFFFFB6C1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Text('💗', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '她喜歡你嗎 💗',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '看看你們今天的親密度',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }

  /// 生日卡片
  Widget _buildBirthdayCard() {
    // 找出最近有生日的貓（0-7天內）
    if (_cats.isEmpty) return const SizedBox.shrink();

    Cat? upcomingBirthdayCat;
    int? daysUntil;

    for (final cat in _cats) {
      if (cat.birthdayType == 'unknown') continue;
      final days = _birthdayService.getDaysUntilBirthday(cat);
      if (days != null && days >= 0 && days <= 7) {
        // 選擇最近的
        if (upcomingBirthdayCat == null || days < daysUntil!) {
          upcomingBirthdayCat = cat;
          daysUntil = days;
        }
      }
    }

    if (upcomingBirthdayCat == null) return const SizedBox.shrink();

    String message;
    if (daysUntil == 0) {
      message = '今天是 ${upcomingBirthdayCat.name} 的生日！🎉';
    } else if (daysUntil == 1) {
      message = '明天是 ${upcomingBirthdayCat.name} 的生日 🎂';
    } else {
      message = '${upcomingBirthdayCat.name} 生日還有 $daysUntil 天 🎂';
    }

    return GestureDetector(
      onTap: () => showBirthdayGiftDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFF8F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFFFB6C1).withValues(alpha: 77/255),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFB6C1).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('🎂', style: TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '點擊看看生日小驚喜 🎁',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9B8B8B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF9B8B8B),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showCatSwitcher() {
    // Navigation safety rule:
    // BottomSheet actions must close and push with rootContext.
    // Do not use sheet context for push after closing the sheet.
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
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
            // 無貓咪提示
            if (_cats.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.pets,
                      size: 64,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '還沒有新增貓咪',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '點擊下方新增你的第一隻貓咪',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        // 先關閉 bottom sheet
                        Navigator.of(rootContext).pop();
                        // 用 root context 開啟 AddCatPage
                        final newCatId = await Navigator.of(rootContext).push<String?>(
                          MaterialPageRoute(builder: (_) => const AddCatPage()),
                        );
                        // AddCatPage 回傳新貓咪 id 才 reload
                        if (newCatId != null) {
                          await _loadCatData();
                          if (!mounted) return;
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('新增貓咪'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._cats.map((cat) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange.shade100,
                      backgroundImage: cat.avatarPath != null &&
                          !cat.avatarPath!.startsWith('content://') &&
                          File(cat.avatarPath!).existsSync()
                          ? FileImage(File(cat.avatarPath!))
                          : null,
                      child: cat.avatarPath != null &&
                              !cat.avatarPath!.startsWith('content://') &&
                              File(cat.avatarPath!).existsSync()
                          ? null
                          : const Icon(Icons.pets, color: Colors.orange),
                    ),
                    title: Text(cat.name),
                    subtitle: Text(cat.breed.isNotEmpty ? cat.breed : '尚未設定'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                          onPressed: () async {
                            Navigator.of(rootContext).pop(); // close bottom sheet first
                            final result = await Navigator.of(rootContext).push<Cat?>(
                              MaterialPageRoute(builder: (_) => EditCatPage(cat: cat)),
                            );
                            if (result != null) {
                              await _loadCatData();
                              if (!mounted) return;
                              setState(() {});
                            }
                          },
                        ),
                        if (selectedCat?.id == cat.id)
                          const Icon(Icons.check, color: Colors.orange),
                      ],
                    ),
                    onTap: () {
                      setState(() => selectedCat = cat);
                      Navigator.pop(context);
                    },
                  )),
            if (_cats.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  // 先關閉 bottom sheet
                  Navigator.of(rootContext).pop();
                  // 用 root context 開啟 AddCatPage
                  final newCatId = await Navigator.of(rootContext).push<String?>(
                    MaterialPageRoute(builder: (_) => const AddCatPage()),
                  );
                  // AddCatPage 回傳新貓咪 id 才 reload
                  if (newCatId != null) {
                    await _loadCatData();
                    if (!mounted) return;
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.add),
                label: const Text('新增貓咪'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
