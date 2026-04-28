import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_result.dart';
import 'translation_history_service.dart';
import 'daily_report_service.dart';
import 'bond_service.dart';
import 'cat_learning_service.dart';

/// 個性分析資料
class PersonalityAnalysis {
  final String catId;
  final String catName;
  final int totalTranslations;
  final Map<EmotionType, int> emotionCounts;
  final List<EmotionType> topEmotions;
  final String personalityType;
  final String personalityDescription;
  final int bondGrowth;
  final double averageConfidence;
  final String ownerSuggestion;
  final bool hasEnoughData;

  const PersonalityAnalysis({
    required this.catId,
    required this.catName,
    required this.totalTranslations,
    required this.emotionCounts,
    required this.topEmotions,
    required this.personalityType,
    required this.personalityDescription,
    required this.bondGrowth,
    required this.averageConfidence,
    required this.ownerSuggestion,
    required this.hasEnoughData,
  });

  /// 空資料分析（資料不足時使用）
  factory PersonalityAnalysis.empty(String catId, String catName) {
    return PersonalityAnalysis(
      catId: catId,
      catName: catName,
      totalTranslations: 0,
      emotionCounts: {},
      topEmotions: [],
      personalityType: '',
      personalityDescription: '',
      bondGrowth: 0,
      averageConfidence: 0,
      ownerSuggestion: '再記錄幾天，我就能更了解她 🐾',
      hasEnoughData: false,
    );
  }

  /// 分享卡用的情緒描述
  String get topEmotionDescription {
    if (topEmotions.isEmpty) return '';
    final top = topEmotions.first;
    switch (top) {
      case EmotionType.affectionate:
        return '🥰';
      case EmotionType.hungry:
        return '🍽️';
      case EmotionType.playful:
        return '🎾';
      case EmotionType.attention:
        return '👀';
      case EmotionType.anxious:
        return '😰';
      case EmotionType.angry:
        return '😾';
      case EmotionType.greeting:
        return '🐱';
      case EmotionType.uncomfortable:
        return '🤒';
      case EmotionType.other:
        return '🐾';
    }
  }

  Map<String, dynamic> toJson() => {
    'catId': catId,
    'catName': catName,
    'totalTranslations': totalTranslations,
    'emotionCounts': emotionCounts.map((k, v) => MapEntry(k.name, v)),
    'topEmotions': topEmotions.map((e) => e.name).toList(),
    'personalityType': personalityType,
    'personalityDescription': personalityDescription,
    'bondGrowth': bondGrowth,
    'averageConfidence': averageConfidence,
    'ownerSuggestion': ownerSuggestion,
    'hasEnoughData': hasEnoughData,
  };
}

/// 個性分析服務
class PersonalityAnalysisService {
  final TranslationHistoryService _historyService;
  final DailyReportService _reportService;
  final BondService _bondService;
  final CatLearningService _learningService;

  /// 最小翻譯筆數才顯示分析
  static const int minTranslationsForAnalysis = 3;

  PersonalityAnalysisService({
    required TranslationHistoryService historyService,
    required DailyReportService reportService,
    required BondService bondService,
    required CatLearningService learningService,
  })  : _historyService = historyService,
        _reportService = reportService,
        _bondService = bondService,
        _learningService = learningService;

  /// 取得 7 天分析
  PersonalityAnalysis getAnalysis(String catId, String catName) {
    // 取得 7 天翻譯紀錄
    final translations = _historyService.getByCatIdWithinDays(catId, 7);

    // 資料不足
    if (translations.length < minTranslationsForAnalysis) {
      return PersonalityAnalysis.empty(catId, catName);
    }

    // 計算情緒統計
    final emotionCounts = <EmotionType, int>{};
    double totalConfidence = 0;

    for (final t in translations) {
      emotionCounts[t.emotionType] = (emotionCounts[t.emotionType] ?? 0) + 1;
      totalConfidence += t.confidence;
    }

    // 排序取得 TOP 3
    final sortedEmotions = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topEmotions = sortedEmotions.take(3).map((e) => e.key).toList();

    // 計算平均信心值
    final avgConfidence = translations.isNotEmpty
        ? totalConfidence / translations.length
        : 0.0;

    // 計算默契值成長（7天內的總成長）
    final bondHistory = _bondService.getHistory(catId);
    int bondGrowth = 0;
    for (final gain in bondHistory.values) {
      bondGrowth += gain;
    }

    // 判斷個性類型
    final mostCommonEmotion = topEmotions.isNotEmpty ? topEmotions.first : null;
    final personalityResult = _getPersonalityType(mostCommonEmotion, topEmotions);

    // 取得學習權重
    final boosts = _learningService.getEmotionBoosts(catId);

    // 產生主人建議
    final suggestion = _getOwnerSuggestion(
      catId: catId,
      topEmotions: topEmotions,
      bondGrowth: bondGrowth,
      totalTranslations: translations.length,
      boosts: boosts,
    );

    return PersonalityAnalysis(
      catId: catId,
      catName: catName,
      totalTranslations: translations.length,
      emotionCounts: emotionCounts,
      topEmotions: topEmotions,
      personalityType: personalityResult['type']!,
      personalityDescription: personalityResult['description']!,
      bondGrowth: bondGrowth,
      averageConfidence: avgConfidence,
      ownerSuggestion: suggestion,
      hasEnoughData: true,
    );
  }

  /// 根據主要情緒判斷個性類型
  Map<String, String> _getPersonalityType(
    EmotionType? dominant,
    List<EmotionType> topEmotions,
  ) {
    final type = dominant ?? EmotionType.other;

    // 檢查是否有 uncomfortable（這個類型要單獨處理）
    final hasUncomfortable = topEmotions.contains(EmotionType.uncomfortable);
    if (hasUncomfortable) {
      return {
        'type': '需要觀察型',
        'description': '這週有些訊號需要多留意，請觀察精神、食慾與日常狀態。',
      };
    }

    // 根據主要情緒判斷
    switch (type) {
      case EmotionType.affectionate:
        return {
          'type': '黏人撒嬌型',
          'description': '她很喜歡靠近你，也常用自己的方式確認你在不在身邊。',
        };
      case EmotionType.playful:
        return {
          'type': '活力小淘氣型',
          'description': '她精神很好，喜歡互動，也很適合用遊戲累積默契。',
        };
      case EmotionType.hungry:
        return {
          'type': '飯飯提醒型',
          'description': '她很會提醒你生活節奏，特別是食物和水的小細節。',
        };
      case EmotionType.attention:
        return {
          'type': '需要回應型',
          'description': '她很在意你的反應，常常想確認你有沒有注意到她。',
        };
      case EmotionType.anxious:
        return {
          'type': '敏感依賴型',
          'description': '她可能比較敏感，需要熟悉、安全且穩定的陪伴。',
        };
      case EmotionType.greeting:
        return {
          'type': '溫柔打招呼型',
          'description': '她用小小互動維持你們的日常連結。',
        };
      default:
        return {
          'type': '神秘小貓型',
          'description': '她的情緒多變又多樣，每天都有新發現！',
        };
    }
  }

  /// 產生主人建議
  String _getOwnerSuggestion({
    required String catId,
    required List<EmotionType> topEmotions,
    required int bondGrowth,
    required int totalTranslations,
    required Map<EmotionType, double> boosts,
  }) {
    // 如果有 uncomfortable，給予特別建議
    if (topEmotions.contains(EmotionType.uncomfortable)) {
      return '這週有出現身體不太舒服的訊號，建議持續觀察食慾和活動力，有疑慮可以諮詢獸醫。';
    }

    // 根據個性類型給建議
    if (topEmotions.contains(EmotionType.affectionate)) {
      return '她很喜歡撒嬌，多給她一些回應會讓她更安心喔 💕';
    }
    if (topEmotions.contains(EmotionType.playful)) {
      return '活力滿滿的她很適合每天花點時間互動遊戲 🎾';
    }
    if (topEmotions.contains(EmotionType.hungry)) {
      return '定時定量的用餐習慣對她很重要，維持規律能讓她更健康 🍽️';
    }
    if (topEmotions.contains(EmotionType.anxious)) {
      return '她比較敏感，環境變化時請多給她一些適應的時間 🐾';
    }

    // 根據默契成長給建議
    if (bondGrowth >= 15) {
      return '你們的默契越來越好了，繼續保持這個節奏 💕';
    }
    if (bondGrowth >= 5) {
      return '小小的陪伴都在累積你們的連結，多和她說說話吧 🌱';
    }

    return '持續記錄能讓我更了解她的獨特之處，一起加油 🐾';
  }

  /// 檢查是否有足夠資料顯示分析
  bool hasEnoughData(String catId) {
    final translations = _historyService.getByCatIdWithinDays(catId, 7);
    return translations.length >= minTranslationsForAnalysis;
  }
}