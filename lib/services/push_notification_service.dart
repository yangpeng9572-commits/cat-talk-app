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
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // 根據 payload 導向不同頁面
    // payload 格式: "type:page"
    // 例如: "cat_call:home", "daily_diary:report", "companion:translate"
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

    // 檢查今天是否已有互動（若是，則跳過陪伴提醒）
    final hadInteraction = await _hadInteractionToday();

    // 取消舊的推播
    await cancelAll();

    // 加入隨機 ±15 分鐘
    final random = Random();

    // 中午 12:30 ± 15min
    final noonHour = 12;
    final noonMinute = 30 + random.nextInt(31) - 15; // -15 ~ +15

    // 晚上 20:30 ± 15min
    final eveningHour = 20;
    final eveningMinute = 30 + random.nextInt(31) - 15;

    // 取得貓咪資料（用於默契值）
    final bond = BondService().getBond(catName);

    // 取得今日互動次數
    final todayCount = await _getTodayInteractionCount();

    // 如果沒有互動，優先推「貓咪找你」
    if (!hadInteraction) {
      await _scheduleNotification(
        id: _catCallId,
        title: '🐱',
        body: _getCatCallMessageWithCount(catName, todayEmotion, todayCount),
        scheduledTime: _nextInstanceOfTime(hour: noonHour, minute: noonMinute),
        payload: 'cat_call:home',
      );
    } else if (hasDiary) {
      // 如果有日記，推「今日小日記」
      await _scheduleNotification(
        id: _dailyDiaryId,
        title: '📖',
        body: _getDailyDiaryMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: noonHour, minute: noonMinute),
        payload: 'daily_diary:report',
      );
    }

    // 晚上的推播：撒嬌或陪伴或輕提醒
    final eveningType = random.nextInt(10);
    if (eveningType < 4) {
      // 40%: 撒嬌提醒
      await _scheduleNotification(
        id: _affectionateId,
        title: '💕',
        body: _getAffectionateMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'affectionate:home',
      );
    } else if (eveningType < 7 && !hadInteraction) {
      // 30%: 陪伴提醒（如果沒有互動）
      await _scheduleNotification(
        id: _companionId,
        title: '🐾',
        body: _getCompanionMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'companion:translate',
      );
    } else {
      // 30%: 輕提醒
      await _scheduleNotification(
        id: _lightId,
        title: '🐱',
        body: _getLightMessage(catName),
        scheduledTime: _nextInstanceOfTime(hour: eveningHour, minute: eveningMinute),
        payload: 'light:home',
      );
    }
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
}

/// 推播類型枚舉
enum NotificationType {
  catCall,      // 貓咪找你
  dailyDiary,   // 今日小日記
  affectionate, // 撒嬌提醒
  companion,    // 陪伴提醒
  light,        // 輕提醒
}