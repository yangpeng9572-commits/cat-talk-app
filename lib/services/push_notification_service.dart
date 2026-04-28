import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_result.dart';
import 'bond_service.dart';

/// 推播服務
/// 情感型推播：讓使用者感覺是「貓咪在找主人」
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // 通知 ID
  static const int _catCallId = 1;         // 貓咪找你
  static const int _dailyDiaryId = 2;       // 今日小日記
  static const int _affectionateId = 3;    // 撒嬌提醒
  static const int _companionId = 4;        // 陪伴提醒
  static const int _lightId = 5;           // 輕提醒

  // Storage keys
  static const String _lastNotificationDateKey = 'last_notification_date';
  static const String _notificationEnabledKey = 'notification_enabled';
  static const String _lastInteractionDateKey = 'last_interaction_date';
  static const String _todayInteractionCountKey = 'today_interaction_count';
  static const String _lastClickedDateKey = 'last_notification_clicked_date';
  static const String _consecutiveMissDaysKey = 'consecutive_miss_days';
  static const String _appOpenTimesKey = 'app_open_times';
  static const String _abVariantKey = 'ab_variant_';
  static const String _abSentKey = 'ab_sent_';
  static const String _abClickedKey = 'ab_clicked_';

  /// 初始化推播服務
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // 初始化 timezone
      tz_data.initializeTimeZones();

      // Android 設定
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 設定
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 處理通知點擊
  void _onNotificationTapped(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;

    // 解析 payload（例如: "cat_call:home|A"）
    final parts = payload.split(':');
    final type = parts.isNotEmpty ? parts[0] : '';
    final variant = parts.length > 1 ? parts[1].split('|').last : null;
    
    // 記錄點擊狀態（供首頁讀取顯示提示）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_clicked', true);
    await prefs.setString('last_notification_type', type);
    
    // 更新連續點擊天數（重置冷卻）
    await recordNotificationClicked();
    
    // 記錄 A/B 點擊
    if (variant != null) {
      await _recordAbClick(type, variant);
    }
  }

  /// 記錄 A/B 點擊（區分 variant）
  Future<void> _recordAbClick(String type, String variant) async {
    final prefs = await SharedPreferences.getInstance();
    final clickedKey = '${_abClickedKey}${type}_$variant';
    final count = prefs.getInt(clickedKey) ?? 0;
    await prefs.setInt(clickedKey, count + 1);
  }

  /// 記錄 App 開啟時間（用於個人化推播時間）
  Future<void> recordAppOpenTime() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    
    // 取得最近 3 天的記錄
    final appOpenTimesJson = prefs.getString(_appOpenTimesKey);
    List<String> appOpenTimes = [];
    if (appOpenTimesJson != null) {
      appOpenTimes = appOpenTimesJson.split(',');
    }
    
    // 加入今天的時間（只取小時，如 "10:30"）
    final todayTime = '${now.hour}:${now.minute}';
    
    // 如果今天還沒記錄過，才加入
    final todayExists = appOpenTimes.any((t) => t.startsWith(today));
    if (!todayExists) {
      appOpenTimes.add('$today|$todayTime');
    }
    
    // 只保留最近 3 天的記錄
    final threeDaysAgo = now.subtract(const Duration(days: 3));
    appOpenTimes = appOpenTimes.where((t) {
      final parts = t.split('|');
      if (parts.length != 2) return false;
      final date = DateTime.tryParse(parts[0]);
      return date != null && date.isAfter(threeDaysAgo);
    }).toList();
    
    await prefs.setString(_appOpenTimesKey, appOpenTimes.join(','));
  }

  /// 取得個人化推播時間（最近 3 天 App 開啟時間 ±15 分鐘）
  Future<({int hour, int minute})?> _getPersonalizedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final appOpenTimesJson = prefs.getString(_appOpenTimesKey);
    if (appOpenTimesJson == null || appOpenTimesJson.isEmpty) return null;
    
    final appOpenTimes = appOpenTimesJson.split(',');
    if (appOpenTimes.isEmpty) return null;
    
    // 取最近一次記錄的時間
    final lastRecord = appOpenTimes.last;
    final parts = lastRecord.split('|');
    if (parts.length != 2) return null;
    
    final timeParts = parts[1].split(':');
    if (timeParts.length != 2) return null;
    
    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);
    if (hour == null || minute == null) return null;
    
    // 加入 ±15 分鐘隨機偏移
    final random = Random();
    final offset = random.nextInt(31) - 15; // -15 ~ +15
    final newMinute = (minute + offset).clamp(0, 59);
    
    return (hour: hour, minute: newMinute);
  }

  /// 記錄 App 開啟時間（公開方法，供外部呼叫）
  Future<void> recordUserActive() async {
    await recordAppOpenTime();
  }

  /// 請求通知權限
  Future<bool> requestPermission() async {
    try {
      final android = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false;
      }

      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// 檢查通知是否已啟用
  Future<bool> isNotificationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationEnabledKey) ?? false;
  }

  /// 啟用通知
  Future<void> enableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, true);
  }

  /// 停用通知
  Future<void> disableNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationEnabledKey, false);
    await cancelAll();
  }

  // ==================== 推播文案生成（帶連續感） ====================

  /// 產生帶連續感的貓咪找你文案
  String _getCatCallMessageWithCount(String catName, EmotionType? emotion, int todayCount) {
    final now = DateTime.now();
    final random = Random(now.millisecond);

    // 根據今日互動次數產生連續感文案
    if (todayCount >= 3) {
      final messages = [
        '$catName今天已經找你 ${todayCount} 次了 🐱',
        '她又叫了，好像有什麼想跟你說 💕',
        '$catName好像一直在等你回應 🐾',
      ];
      return messages[random.nextInt(messages.length)];
    } else if (todayCount == 2) {
      final messages = [
        '$catName剛剛又叫了一聲，好像在找你 🐱',
        '她今天找你 2 次了，應該有什麼事 💕',
        '$catName又叫了，你在就回應一下她吧 🐾',
      ];
      return messages[random.nextInt(messages.length)];
    } else if (todayCount == 1) {
      final messages = [
        '她剛剛叫了一聲，好像在找你 🐱',
        '$catName好像想跟你說什麼 💕',
        '她剛才叫你，好像在等你回應 🐾',
      ];
      return messages[random.nextInt(messages.length)];
    } else {
      // todayCount == 0
      if (emotion == EmotionType.affectionate) {
        final messages = [
          '$catName好像在找你 🐱',
          '她今天很想黏著你 💕',
          '$catName好像在等你回應',
          '她今天特別想撒嬌 🐾',
        ];
        return messages[random.nextInt(messages.length)];
      } else if (emotion == EmotionType.attention) {
        final messages = [
          '她剛剛好像叫了一聲',
          '$catName在看你嗎？👀',
          '她想讓你注意一下',
          '好像有什麼想跟你說 👀',
        ];
        return messages[random.nextInt(messages.length)];
      } else if (emotion == EmotionType.hungry) {
        final messages = [
          '$catName好像在提醒你什麼 🍽️',
          '她好像有點餓了',
          '$catName好像在等你準備食物',
        ];
        return messages[random.nextInt(messages.length)];
      } else {
        final messages = [
          '$catName好像在找你 🐱',
          '她好像想跟你說什麼',
          '$catName好像在等你 🐾',
        ];
        return messages[random.nextInt(messages.length)];
      }
    }
  }

  /// 1️⃣ 貓咪找你（最高點擊）- 向下相容版
  String _getCatCallMessage(String catName, EmotionType? emotion) {
    return _getCatCallMessageWithCount(catName, emotion, 0);
  }

  /// 2️⃣ 今日小日記
  String _getDailyDiaryMessage(String catName) {
    final now = DateTime.now();
    final random = Random(now.millisecond);

    final messages = [
      '$catName今天的小日記寫好了 🐾',
      '想看看她今天的小心情嗎？',
      '她今天的狀態，好像有點不一樣',
      '$catName的一天結束了，要看看嗎？',
    ];
    return messages[random.nextInt(messages.length)];
  }

  /// 3️⃣ 撒嬌提醒
  String _getAffectionateMessage(String catName) {
    final now = DateTime.now();
    final random = Random(now.millisecond);

    final messages = [
      '她今天有點黏人 💕',
      '現在是摸摸她的好時機',
      '$catName好像想被抱一下',
      '她看起來想要一些關注 🐱',
      '今天她特別需要你 💕',
    ];
    return messages[random.nextInt(messages.length)];
  }

  /// 4️⃣ 陪伴提醒
  String _getCompanionMessage(String catName) {
    final now = DateTime.now();
    final random = Random(now.millisecond);

    final messages = [
      '今天還沒聽她說話喔 🐱',
      '也許她在等你',
      '今天要不要陪她一下？',
      '$catName好像有點無聊 🐾',
    ];
    return messages[random.nextInt(messages.length)];
  }

  /// 5️⃣ 輕提醒（低干擾）
  String _getLightMessage(String catName) {
    final now = DateTime.now();
    final random = Random(now.millisecond);

    final messages = [
      '她今天也在你身邊 🐾',
      '記錄一聲喵，也是一種陪伴',
      '你們的默契還在慢慢累積中',
      '$catName今天也陪著你 🐱',
    ];
    return messages[random.nextInt(messages.length)];
  }

  // ==================== 排程推播 ====================

  /// 排程每日推播（中午 + 晚上）
  Future<void> scheduleDailyNotifications({
    required String catName,
    EmotionType? todayEmotion,
    bool hasDiary = false,
  }) async {
    // 檢查通知是否啟用
    final enabled = await isNotificationEnabled();
    if (!enabled) return;

    // 1️⃣ 當天互動檢查：如果今天有任何互動（翻譯、查看日記、任務），不發推播
    final hadAnyInteraction = await _hadAnyInteractionToday();
    if (hadAnyInteraction) return;

    // 檢查冷卻機制：當天是否已發送過
    final alreadySentToday = await _wasNotificationSentToday();
    if (alreadySentToday) return;
    
    // 更新連續未點擊天數
    await _updateConsecutiveMissDays();
    
    // 取得連續未互動天數
    final consecutiveMissDays = await _getConsecutiveMissDays();
    
    // 冷卻機制：連續 2 天未點擊 → 第 3 天只發輕提醒
    if (consecutiveMissDays >= 2) {
      await _scheduleLightOnly(catName);
      return;
    }

    // 2️⃣ 避免重複文案：檢查昨天發送的推播類型
    final yesterdayType = await _getLastNotificationType();
    
    // 取消舊的推播
    await cancelAll();

    final random = Random();

    // 取得個人化時間（根據最近 App 開啟時間，預設 12:30）
    final personalizedTime = await _getPersonalizedTime();
    late int noonHour;
    late int noonMinute;
    if (personalizedTime != null) {
      noonHour = personalizedTime.hour;
      noonMinute = personalizedTime.minute;
    } else {
      noonHour = 12;
      noonMinute = 30 + random.nextInt(31) - 15;
    }
    // 晚上：個人化時間往後挪 8 小時
    late int eveningHour;
    late int eveningMinute;
    if (personalizedTime != null) {
      eveningHour = (personalizedTime.hour + 8) % 24;
      eveningMinute = personalizedTime.minute;
    } else {
      eveningHour = 20;
      eveningMinute = 30 + random.nextInt(31) - 15;
    }

    // A/B 測試 variants
    final catCallVariant = random.nextBool() ? 'A' : 'B';
    final affectionateVariant = random.nextBool() ? 'A' : 'B';


    // 取得貓咪資料（用於默契值）
    final bond = BondService().getBond(catName);


    // 取得今日互動次數
    final todayCount = await _getTodayInteractionCount();

    // 如果沒有互動，優先推「貓咪找你」（但避免和昨天重複）
    if (!hadAnyInteraction && yesterdayType != 'cat_call') {
      await _scheduleNotification(
        id: _catCallId,
        title: '🐱',
        body: _getCatCallMessageAb(catName, todayEmotion, todayCount, catCallVariant),
        scheduledTime: _nextInstanceOfTime(hour: noonHour, minute: noonMinute),
        payload: 'cat_call:home|$catCallVariant',
      );
      await _markLastNotificationType('cat_call');
      await _recordAbSent('cat_call', catCallVariant);
    } else if (hasDiary && yesterdayType != 'daily_diary') {
      // 如果有日記，推「今日小日記」（避免和昨天重複）
      await _scheduleNotification(
        id: _dailyDiaryId,
        title: '📖',
        body: _getDailyDiaryMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: noonHour, minute: noonMinute),
        payload: 'daily_diary:report',
      );
      await _markLastNotificationType('daily_diary');
    }

    // 晚上的推播：撒嬌或陪伴或輕提醒（避免和昨天重複）
    final eveningType = random.nextInt(10);
    if (eveningType < 4 && yesterdayType != 'affectionate') {
      // 40%: 撒嬌提醒（帶 A/B）
      await _scheduleNotification(
        id: _affectionateId,
        title: '💕',
        body: _getAffectionateMessageAb(catName, affectionateVariant),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'affectionate:home|$affectionateVariant',
      );
      await _markLastNotificationType('affectionate');
      await _recordAbSent('affectionate', affectionateVariant);
    } else if (eveningType < 7 && !hadAnyInteraction && yesterdayType != 'companion') {
      // 30%: 陪伴提醒（如果沒有互動，避免和昨天重複）
      await _scheduleNotification(
        id: _companionId,
        title: '🐾',
        body: _getCompanionMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'companion:translate',
      );
      await _markLastNotificationType('companion');
    } else if (yesterdayType != 'light') {
      // 30%: 輕提醒（避免和昨天重複）
      await _scheduleNotification(
        id: _lightId,
        title: '🐱',
        body: _getLightMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'light:home',
      );
      await _markLastNotificationType('light');
    }
    
    // 記錄今日已發送（避免當天重複推播）
    await _markNotificationSentToday();
    
    // 3️⃣ 低頻成就推播（3~5天一次）
    await _maybeScheduleAchievementNotification(catName, bond?.bondScore ?? 0);
  }

  /// 立即發送測試推播
  Future<void> sendTestNotification({
    required String catName,
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      99,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cat_talk_test',
          '測試通知',
          channelDescription: '貓語通測試推播',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// 發送「貓咪找你」推播
  Future<void> sendCatCallNotification({
    required String catName,
    EmotionType? emotion,
  }) async {
    final now = DateTime.now();
    final random = Random(now.millisecond);
    final hour = now.hour;
    
    // 根據時間調整問候
    String greeting = '';
    if (hour < 12) {
      greeting = '早上';
    } else if (hour < 18) {
      greeting = '下午';
    } else {
      greeting = '晚上';
    }

    await _notifications.show(
      _catCallId,
      '🐱',
      _getCatCallMessage(catName, emotion),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cat_call',
          '貓咪找你',
          channelDescription: '你家貓咪在找你',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'cat_call:home',
    );
  }

  /// 取消所有排程推播
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// 取消特定 ID 的推播
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }

  // ==================== Helper Functions ====================

  /// 記錄今日互動（翻譯完成後呼叫）
  Future<void> recordInteraction() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    await prefs.setString(_lastInteractionDateKey, '${today.year}-${today.month}-${today.day}');
  }

  /// 檢查今天是否已有互動
  Future<bool> _hadInteractionToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString(_lastInteractionDateKey);
    if (lastDate == null) return false;

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    return lastDate == todayStr;
  }

  /// 取得今日互動次數
  Future<int> _getTodayInteractionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final storedDate = prefs.getString('interaction_count_date');
    
    // 如果不是今天，重置計數
    if (storedDate != todayStr) {
      await prefs.setInt(_todayInteractionCountKey, 0);
      await prefs.setString('interaction_count_date', todayStr);
      return 0;
    }
    
    return prefs.getInt(_todayInteractionCountKey) ?? 0;
  }

  /// 增加今日互動次數
  Future<void> incrementInteractionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final storedDate = prefs.getString('interaction_count_date');
    
    int currentCount = 0;
    if (storedDate == todayStr) {
      currentCount = prefs.getInt(_todayInteractionCountKey) ?? 0;
    } else {
      // 新的一天，重置
      await prefs.setString('interaction_count_date', todayStr);
    }
    
    await prefs.setInt(_todayInteractionCountKey, currentCount + 1);
    await recordInteraction(); // 同時更新最後互動時間
  }

  /// 檢查今天是否已發送過推播（當天不重複）
  Future<bool> _wasNotificationSentToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSentDate = prefs.getString('last_notification_sent_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    return lastSentDate == todayStr;
  }

  /// 記錄今日已發送推播（避免重複）
  Future<void> _markNotificationSentToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('last_notification_sent_date', todayStr);
  }

  /// 記錄推播點擊（更新連續未點擊天數）
  Future<void> _updateConsecutiveMissDays() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final lastClicked = prefs.getString(_lastClickedDateKey);
    
    // 如果昨天點擊過，重置計數
    if (lastClicked != null) {
      final yesterday = today.subtract(const Duration(days: 1));
      final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
      if (lastClicked == yesterdayStr) {
        await prefs.setInt(_consecutiveMissDaysKey, 0);
      }
    }
  }

  /// 取得連續未點擊推播天數
  Future<int> _getConsecutiveMissDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_consecutiveMissDaysKey) ?? 0;
  }

  /// 更新推播點擊天數（當用戶點擊推播時呼叫）
  Future<void> recordNotificationClicked() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString(_lastClickedDateKey, todayStr);
    // 重置連續未點擊天數
    await prefs.setInt(_consecutiveMissDaysKey, 0);
  }

  /// 排程只發輕提醒（冷卻模式）
  Future<void> _scheduleLightOnly(String catName) async {
    final random = Random();
    final hour = 20; // 只在晚上發
    final minute = 30 + random.nextInt(31) - 15;
    
    await _scheduleNotification(
      id: _lightId,
      title: '🐱',
      body: _getLightMessage(catName),
      scheduledTime: _nextInstanceOfTime(hour: hour, minute: minute),
      payload: 'light:home',
    );
    
    // 記錄已發送
    await _markNotificationSentToday();
  }

  /// 檢查今天是否有任何互動（翻譯、查看日記、任務）
  Future<bool> _hadAnyInteractionToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    // 檢查翻譯互動
    final lastInteraction = prefs.getString(_lastInteractionDateKey);
    if (lastInteraction == todayStr) return true;
    
    // 檢查任務完成
    final lastTaskComplete = prefs.getString('last_task_completed_date');
    if (lastTaskComplete == todayStr) return true;
    
    // 檢查日記查看
    final lastDiaryView = prefs.getString('last_diary_view_date');
    if (lastDiaryView == todayStr) return true;
    
    return false;
  }

  /// 記錄任務完成（當用戶完成任務時呼叫）
  Future<void> recordTaskCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('last_task_completed_date', todayStr);
  }

  /// 記錄日記查看（當用戶查看日記時呼叫）
  Future<void> recordDiaryViewed() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('last_diary_view_date', todayStr);
  }

  /// 取得昨天的推播類型（用於避免重複）
  Future<String?> _getLastNotificationType() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('last_notification_type_date');
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    
    // 如果不是昨天，重置
    if (lastDate != yesterdayStr) {
      return null;
    }
    
    return prefs.getString('last_notification_type');
  }

  /// 記錄今天的推播類型（用於避免明天重複）
  Future<void> _markLastNotificationType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('last_notification_type_date', todayStr);
    await prefs.setString('last_notification_type', type);
  }

  /// 低頻成就推播（3~5天一次）
  Future<void> _maybeScheduleAchievementNotification(String catName, int bondScore) async {
    final prefs = await SharedPreferences.getInstance();
    final lastAchievementDate = prefs.getString('last_achievement_notification_date');
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    
    // 檢查是否在 3-5 天內發送過
    if (lastAchievementDate != null) {
      final lastDate = DateTime.parse(lastAchievementDate);
      final daysDiff = today.difference(lastDate).inDays;
      if (daysDiff < 3 || daysDiff > 5) return; // 不在 3-5 天範圍內
    }
    
    // 隨機決定是否發送（50% 機率）
    final random = Random();
    if (random.nextBool()) return;
    
    // 根據默契值產生不同文案
    String message;
    if (bondScore >= 80) {
      message = '你們的默契好像又更好了 💕';
    } else if (bondScore >= 50) {
      message = '她今天好像更懂你了 🐾';
    } else {
      message = '你們的距離好像近了一點點 🐱';
    }
    
    await _scheduleNotification(
      id: 6, // 成就推播專用 ID
      title: '🎉',
      body: message,
      scheduledTime: _nextInstanceOfTime(hour: 18, minute: 0),
      payload: 'achievement:home',
    );
    
    await prefs.setString('last_achievement_notification_date', todayStr);
  }

  /// 計算下一個指定時間的 DateTime
  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// 排程通知
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String payload,
  }) async {
    await _notifications.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'cat_talk_daily',
          '每日提醒',
          channelDescription: '貓語通每日提醒',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  // ==================== 首次啟用引導 ====================

  /// 獲取首次啟用引導訊息
  String getFirstTimeMessage() {
    return '讓我在適當時候提醒你關心她 🐱';
  }

  /// 檢查是否為首次使用
  Future<bool> isFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    return !prefs.containsKey(_notificationEnabledKey);
  }

  /// 標記已處理首次引導
  Future<void> markFirstTimeDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_notification_shown', true);
  }

  /// A/B 文案：貓咪找你
  String _getCatCallMessageAb(String catName, EmotionType? emotion, int todayCount, String variant) {
    if (variant == 'A') {
      return _getCatCallMessageWithCount(catName, emotion, todayCount);
    }
    // Variant B: 另一組文案風格
    if (todayCount >= 3) {
      return '$catName 今天好活跃，好像一直在找你 🐱';
    } else if (todayCount == 2) {
      return '她又叫了～ $catName 在呼喚你喔 💕';
    } else if (todayCount == 1) {
      return '$catName 剛才叫了一聲，好像需要你 🐾';
    }
    return '$catName 好像有什麼想跟你说 🐱';
  }
  /// A/B 文案：撒嬌提醒
  String _getAffectionateMessageAb(String catName, String variant) {
    if (variant == 'A') {
      return _getAffectionateMessage(catName);
    }
    final messages = [
      '現在是個好時機，給她一個抱抱 🐱',
      '$catName 看起來有點寂寞，陪她一下吧',
      '她今天特別需要你 💕 不限時的摸摸最適合',
      '$catName 想被關注的訊號出現了 🐾',
    ];
    return messages[Random().nextInt(messages.length)];
  }
  /// 記錄 A/B 發送
  Future<void> _recordAbSent(String type, String variant) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${_abVariantKey}${type}', variant);
    final sentKey = '${_abSentKey}${type}_$variant';
    final count = prefs.getInt(sentKey) ?? 0;
    await prefs.setInt(sentKey, count + 1);
  }
  /// 取得 A/B 測試統計（除錯用）
  Future<Map<String, dynamic>> getAbStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'cat_call': {
        'sent_A': prefs.getInt('${_abSentKey}cat_call_A') ?? 0,
        'sent_B': prefs.getInt('${_abSentKey}cat_call_B') ?? 0,
        'clicked_A': prefs.getInt('${_abClickedKey}cat_call_A') ?? 0,
        'clicked_B': prefs.getInt('${_abClickedKey}cat_call_B') ?? 0,
      },
      'affectionate': {
        'sent_A': prefs.getInt('${_abSentKey}affectionate_A') ?? 0,
        'sent_B': prefs.getInt('${_abSentKey}affectionate_B') ?? 0,
        'clicked_A': prefs.getInt('${_abClickedKey}affectionate_A') ?? 0,
        'clicked_B': prefs.getInt('${_abClickedKey}affectionate_B') ?? 0,
      },
    };
  }
}

/// 推播類型枚舉
enum NotificationType {
  catCall,      // 貓咪找你
  dailyDiary,   // 今日小日記
  affectionate, // 撒嬌提醒
  companion,    // 陪伴提醒
  light,        // 輕提醒
}