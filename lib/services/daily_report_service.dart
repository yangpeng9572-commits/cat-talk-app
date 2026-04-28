import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_cat_report.dart';
import '../models/translation_result.dart';
import 'translation_history_service.dart';
import 'cat_learning_service.dart';

/// 每日報告服務
/// 
/// 使用 SharedPreferences 持久化儲存每日報告
/// 負責生成每隻貓每天的「情緒與互動報告」
class DailyReportService {
  static const String _storageKeyPrefix = 'daily_report_';
  static const int _maxDaysToKeep = 30; // 保留最近 30 天

  final TranslationHistoryService _historyService;
  final CatLearningService _learningService;
  SharedPreferences? _prefs;
  
  // 記憶體緩存
  final Map<String, DailyCatReport> _memoryCache = {};

  DailyReportService({
    TranslationHistoryService? historyService,
    CatLearningService? learningService,
  })  : _historyService = historyService ?? TranslationHistoryService(),
        _learningService = learningService ?? CatLearningService();

  /// 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _loadRecentToMemory();
  }

  /// 將最近 7 天的報告載入記憶體
  Future<void> _loadRecentToMemory() async {
    if (_prefs == null) return;
    
    final now = DateTime.now();
    for (int i = 0; i <= 7; i++) {
      final date = now.subtract(Duration(days: i));
      final allKeys = _prefs!.getKeys().where((k) => k.startsWith(_storageKeyPrefix));
      
      for (final key in allKeys) {
        final jsonStr = _prefs!.getString(key);
        if (jsonStr != null) {
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            if (json['date'] != null) {
              final reportDate = DateTime.parse(json['date'] as String);
              if (_isSameDay(reportDate, date)) {
                _memoryCache[key] = DailyCatReport.fromJson(json);
              }
            }
          } catch (e) {
            // 忽略
          }
        }
      }
    }
  }

  /// 檢查兩個日期是否同一天
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 將日期轉換成儲存 key 的一部分（用於識別哪個 catId 和日期）
  String _dateToKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// 取得今天的報告
  DailyCatReport getTodayReport(String catId) {
    return generateDailyReport(catId, DateTime.now());
  }

  /// 取得指定日期的報告
  DailyCatReport generateDailyReport(String catId, DateTime date) {
    // 檢查記憶體緩存
    final cacheKey = '${catId}_${_dateToKey(date)}';
    if (_memoryCache.containsKey(cacheKey) && _isSameDay(date, DateTime.now())) {
      return _memoryCache[cacheKey]!;
    }

    // 取得該貓、該日期的所有翻譯記錄
    final allHistory = _historyService.getByCatId(catId);
    
    // 過濾出指定日期的記錄
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final dayHistory = allHistory.where((r) {
      return r.createdAt.isAfter(startOfDay) && 
             r.createdAt.isBefore(endOfDay);
    }).toList();

    // 如果沒有記錄，回傳空狀態報告
    if (dayHistory.isEmpty) {
      final emptyReport = DailyCatReport.empty(catId: catId, date: date);
      // 仍然保存（如果日期是今天）
      if (_isSameDay(date, DateTime.now())) {
        _memoryCache[cacheKey] = emptyReport;
        _saveReportToDisk(catId, emptyReport);
      }
      return emptyReport;
    }

    // 計算各項數據
    final emotionCounts = calculateEmotionCounts(dayHistory);
    final dominantEmotion = calculateDominantEmotion(emotionCounts, catId);
    final averageConfidence = calculateAverageConfidence(dayHistory);
    final headlineText = generateHeadlineText(dominantEmotion, dayHistory.length);
    final summaryText = generateSummaryText(
      catId: catId,
      dominantEmotion: dominantEmotion,
      totalTranslations: dayHistory.length,
      averageConfidence: averageConfidence,
      emotionCounts: emotionCounts,
    );
    final suggestedAction = generateSuggestedAction(
      catId: catId,
      dominantEmotion: dominantEmotion,
      emotionCounts: emotionCounts,
    );
    final warningLevel = calculateWarningLevel(emotionCounts);

    final report = DailyCatReport(
      id: '${catId}_${_dateToKey(date)}',
      catId: catId,
      date: date,
      totalTranslations: dayHistory.length,
      dominantEmotion: dominantEmotion,
      averageConfidence: averageConfidence,
      emotionCounts: emotionCounts,
      summaryText: summaryText,
      suggestedAction: suggestedAction,
      warningLevel: warningLevel,
      createdAt: DateTime.now(),
      headlineText: headlineText,
    );

    // 保存報告
    _memoryCache[cacheKey] = report;
    _saveReportToDisk(catId, report);

    return report;
  }

  /// 儲存報告到磁碟
  Future<void> _saveReportToDisk(String catId, DailyCatReport report) async {
    if (_prefs == null) return;
    
    final key = '$_storageKeyPrefix${catId}_${_dateToKey(report.date)}';
    await _prefs!.setString(key, jsonEncode(report.toJson()));
    
    // 清理過期報告
    await _cleanupOldReports(catId);
  }

  /// 清理過期報告（超過 30 天）
  Future<void> _cleanupOldReports(String catId) async {
    if (_prefs == null) return;
    
    final cutoff = DateTime.now().subtract(const Duration(days: _maxDaysToKeep));
    final allKeys = _prefs!.getKeys().where((k) => k.startsWith('$_storageKeyPrefix${catId}_'));
    
    for (final key in allKeys) {
      final jsonStr = _prefs!.getString(key);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reportDate = DateTime.parse(json['date'] as String);
          if (reportDate.isBefore(cutoff)) {
            await _prefs!.remove(key);
            _memoryCache.remove(key);
          }
        } catch (e) {
          // 忽略
        }
      }
    }
  }

  /// 取得最近 N 天的報告
  List<DailyCatReport> getReportsByCatIdWithinDays(String catId, int days) {
    if (_prefs == null) return [];
    
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final reports = <DailyCatReport>[];
    final allKeys = _prefs!.getKeys().where((k) => k.startsWith('$_storageKeyPrefix${catId}_'));
    
    for (final key in allKeys) {
      final jsonStr = _prefs!.getString(key);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final reportDate = DateTime.parse(json['date'] as String);
          if (reportDate.isAfter(cutoff)) {
            reports.add(DailyCatReport.fromJson(json));
          }
        } catch (e) {
          // 忽略解析錯誤，回傳空列表
        }
      }
    }
    
    // 按日期排序（由新到舊）
    reports.sort((a, b) => b.date.compareTo(a.date));
    return reports;
  }

  /// 計算情緒次數統計
  Map<EmotionType, int> calculateEmotionCounts(List<TranslationResult> history) {
    final counts = <EmotionType, int>{};
    for (final result in history) {
      counts[result.emotionType] = (counts[result.emotionType] ?? 0) + 1;
    }
    return counts;
  }

  /// 計算主要情緒（會參考個人化學習）
  EmotionType? calculateDominantEmotion(
    Map<EmotionType, int> emotionCounts,
    String catId,
  ) {
    if (emotionCounts.isEmpty) return null;

    // 取得該貓的學習權重
    final learningWeights = _learningService.getEmotionWeights(catId);

    // 找出最多次的情緒
    EmotionType dominant = EmotionType.other;
    int maxCount = 0;

    for (final entry in emotionCounts.entries) {
      int adjustedCount = entry.value;
      
      // 如果這個情緒在學習權重中，增加其權重
      if (learningWeights.containsKey(entry.key)) {
        // 學習權重最高 +0.5，所以乘以 1.5 來加成
        adjustedCount = (entry.value * (1 + learningWeights[entry.key]!)).round();
      }
      
      if (adjustedCount > maxCount) {
        maxCount = adjustedCount;
        dominant = entry.key;
      }
    }

    return dominant;
  }

  /// 計算平均信心值
  double calculateAverageConfidence(List<TranslationResult> history) {
    if (history.isEmpty) return 0.0;
    
    final total = history.fold<double>(
      0.0,
      (sum, result) => sum + result.confidence,
    );
    return total / history.length;
  }

  /// 生成摘要文字
  String generateSummaryText({
    required String catId,
    required EmotionType? dominantEmotion,
    required int totalTranslations,
    required double averageConfidence,
    required Map<EmotionType, int> emotionCounts,
  }) {
    // 如果沒有主要情緒，回傳預設
    if (dominantEmotion == null) {
      return '今天還沒有記錄，試著錄下第一聲喵吧！';
    }

    // 根據主要情緒生成敘述
    String baseText;
    switch (dominantEmotion) {
      case EmotionType.hungry:
        baseText = '今天牠多次表現出想吃或期待食物的訊號，可以檢查餵食時間是否穩定。';
        break;
      case EmotionType.affectionate:
        baseText = '今天牠比較想親近你，適合安排一些摸摸或陪伴時間。';
        break;
      case EmotionType.playful:
        baseText = '今天牠精神不錯，可以陪牠玩 10 分鐘消耗體力。';
        break;
      case EmotionType.attention:
        baseText = '今天牠多次想引起你的注意，可能需要更多互動。';
        break;
      case EmotionType.anxious:
        baseText = '今天牠可能有點緊張，建議觀察環境是否有噪音或壓力來源。';
        break;
      case EmotionType.angry:
        baseText = '今天有幾次不太開心的反應，建議給牠一些空間。';
        break;
      case EmotionType.uncomfortable:
        baseText = '今天出現幾次可能不舒服的訊號，建議觀察食慾、精神與排便狀況。';
        break;
      case EmotionType.greeting:
        baseText = '今天牠的情緒穩定，偶爾和你互動打招呼。';
        break;
      case EmotionType.other:
        baseText = '今天牠表現多元，還在觀察了解中。';
        break;
    }

    // 如果翻譯次數多，追加提醒
    String extraText = '';
    if (totalTranslations > 10) {
      extraText = '\n\n今天牠比較常表達需求，可能需要多給予關注。';
    }

    // 如果平均信心低，追加說明
    String confidenceNote = '';
    if (averageConfidence < 0.5) {
      confidenceNote = '\n\n💡 今天的判斷有些不確定，可以多幫我修正，我會更懂牠。';
    }

    // 加入個人化學習參考（如果該貓有修正紀錄）
    final learningStats = _learningService.getStats(catId);
    String personalizedNote = '';
    if (learningStats.totalCorrections > 0) {
      // 找出最常被修正的情緒
      final topEmotion = _learningService.getMostCorrectedEmotion(catId);
      if (topEmotion != null && topEmotion != dominantEmotion) {
        personalizedNote = '\n\n📝 根據過往修正紀錄，這隻貓可能也想要${topEmotion.label}。';
      }
    }

    return baseText + extraText + confidenceNote + personalizedNote;
  }

  /// 生成一句話摘要（最多20字）
  String generateHeadlineText(EmotionType? dominantEmotion, int totalTranslations) {
    if (dominantEmotion == null) {
      return '今天還沒有紀錄';
    }

    // 隨機種子（用於在同一 dominantEmotion 下選擇不同文案）
    final seed = DateTime.now().day + totalTranslations;
    final variant = seed % 3;

    switch (dominantEmotion) {
      case EmotionType.hungry:
        if (totalTranslations > 10) return '今天牠超級餓的！';
        if (totalTranslations > 5) return '今天牠有點嘴饞 🐱';
        final hungryMsgs = ['今天牠好像想吃东西', '今天牠對食物很感興趣', '今天牠肚子在叫'];
        return hungryMsgs[variant];
      case EmotionType.affectionate:
        if (totalTranslations > 10) return '今天牠超級撒嬌！';
        if (totalTranslations > 5) return '今天牠很需要抱抱 💕';
        final affMsgs = ['今天牠想靠近你', '今天牠看起來很親人', '今天牠需要一些溫暖'];
        return affMsgs[variant];
      case EmotionType.playful:
        if (totalTranslations > 10) return '今天牠精力超級旺盛！';
        if (totalTranslations > 5) return '今天牠很想玩耍 🎾';
        final playMsgs = ['今天牠想玩耍', '今天牠對玩具很有興趣', '今天牠有點活潑'];
        return playMsgs[variant];
      case EmotionType.attention:
        if (totalTranslations > 10) return '今天牠一直刷存在感！';
        if (totalTranslations > 5) return '今天牠有點黏人 👀';
        final attMsgs = ['今天牠想引起注意', '今天牠在找你', '今天牠需要互動'];
        return attMsgs[variant];
      case EmotionType.anxious:
        if (totalTranslations > 10) return '今天牠很焦躁不安 😿';
        if (totalTranslations > 5) return '今天牠有點緊張';
        final anxMsgs = ['今天牠有點不安', '今天牠看起來謹慎', '今天牠在觀察環境'];
        return anxMsgs[variant];
      case EmotionType.angry:
        if (totalTranslations > 10) return '今天牠脾氣不太好 😾';
        if (totalTranslations > 5) return '今天牠有點不高興';
        final angryMsgs = ['今天牠不太高興', '今天牠有點不爽', '今天牠需要空間'];
        return angryMsgs[variant];
      case EmotionType.uncomfortable:
        if (totalTranslations > 10) return '今天牠不太舒服 😿';
        if (totalTranslations > 5) return '今天牠有點不適';
        final uncMsgs = ['今天牠感覺怪怪的', '今天牠不太對勁', '今天牠需要關注'];
        return uncMsgs[variant];
      case EmotionType.greeting:
        if (totalTranslations > 5) return '今天牠頻頻打招呼 👋';
        final greetMsgs = ['今天牠跟你打招呼', '今天牠在說嗨', '今天牠態度友善'];
        return greetMsgs[variant];
      case EmotionType.other:
        return '今天牠很難捉摸 🤔';
    }
  }

  /// 生成建議行動
  String generateSuggestedAction({
    required String catId,
    required EmotionType? dominantEmotion,
    required Map<EmotionType, int> emotionCounts,
  }) {
    if (dominantEmotion == null) {
      return '開始記錄今天的翻譯，了解你的貓咪！';
    }

    switch (dominantEmotion) {
      case EmotionType.hungry:
        return '去看看貓碗是不是空了，或者給他一點小點心吧！';
      case EmotionType.affectionate:
        return '停下手中的事，花幾分鐘摸摸他或陪他玩一下。';
      case EmotionType.playful:
        return '拿出逗貓棒或小玩具，和他互動一下吧！';
      case EmotionType.attention:
        return '抬頭看看他，也許他只是想確認你還在。';
      case EmotionType.anxious:
        return '檢查一下環境中是否有讓他緊張的東西，提供一些安撫。';
      case EmotionType.angry:
        return '給他一點空間，不要強迫互動，等他自己冷靜下來。';
      case EmotionType.uncomfortable:
        return '觀察一下有沒有其他異常症狀，若持續就帶去看獸醫。';
      case EmotionType.greeting:
        return '跟他打個招呼吧，他會很開心的！';
      case EmotionType.other:
        return '持續觀察他的行為，慢慢了解他的習慣。';
    }
  }

  /// 計算警示等級
  WarningLevel calculateWarningLevel(Map<EmotionType, int> emotionCounts) {
    // uncomfortable 超過 2 次 → attention
    if ((emotionCounts[EmotionType.uncomfortable] ?? 0) > 2) {
      return WarningLevel.attention;
    }

    // anxious 超過 3 次 → notice
    if ((emotionCounts[EmotionType.anxious] ?? 0) > 3) {
      return WarningLevel.notice;
    }

    return WarningLevel.normal;
  }

  /// 取得警示提醒文字
  String getWarningNote(WarningLevel level) {
    if (level == WarningLevel.normal) return '';

    return '這只是行為與聲音推測，若牠持續異常，建議諮詢獸醫。';
  }
}
