import 'translation_result.dart';

/// 每日貓咪報告 Model
/// 
/// 記錄每隻貓每天的翻譯統計與分析
class DailyCatReport {
  final String id;
  final String catId;
  final DateTime date;
  final int totalTranslations;
  final EmotionType? dominantEmotion;
  final double averageConfidence;
  final Map<EmotionType, int> emotionCounts;
  final String summaryText;
  final String suggestedAction;
  final WarningLevel warningLevel;
  final DateTime createdAt;
  final String headlineText; // 一句話摘要（最多20字）

  DailyCatReport({
    required this.id,
    required this.catId,
    required this.date,
    required this.totalTranslations,
    this.dominantEmotion,
    required this.averageConfidence,
    required this.emotionCounts,
    required this.summaryText,
    required this.suggestedAction,
    required this.warningLevel,
    required this.createdAt,
    required this.headlineText,
  });

  /// 是否為空狀態（今天沒有任何紀錄）
  bool get isEmpty => totalTranslations == 0;

  /// 轉換成 Map（用於儲存）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'date': date.toIso8601String(),
      'totalTranslations': totalTranslations,
      'dominantEmotion': dominantEmotion?.name,
      'averageConfidence': averageConfidence,
      'emotionCounts': emotionCounts.map(
        (key, value) => MapEntry(key.name, value),
      ),
      'summaryText': summaryText,
      'suggestedAction': suggestedAction,
      'warningLevel': warningLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'headlineText': headlineText,
    };
  }

  /// 從 Map 建立（用於讀取）
  factory DailyCatReport.fromJson(Map<String, dynamic> json) {
    return DailyCatReport(
      id: json['id'] as String,
      catId: json['catId'] as String,
      date: DateTime.parse(json['date'] as String),
      totalTranslations: json['totalTranslations'] as int,
      dominantEmotion: json['dominantEmotion'] != null
          ? EmotionType.values.firstWhere(
              (e) => e.name == json['dominantEmotion'],
              orElse: () => EmotionType.other,
            )
          : null,
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      emotionCounts: (json['emotionCounts'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          EmotionType.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
      summaryText: json['summaryText'] as String,
      suggestedAction: json['suggestedAction'] as String,
      warningLevel: WarningLevel.values.firstWhere(
        (e) => e.name == json['warningLevel'],
        orElse: () => WarningLevel.normal,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      headlineText: json['headlineText'] as String? ?? '今天還沒有紀錄',
    );
  }

  /// 建立空狀態報告
  factory DailyCatReport.empty({
    required String catId,
    required DateTime date,
  }) {
    return DailyCatReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      catId: catId,
      date: date,
      totalTranslations: 0,
      dominantEmotion: null,
      averageConfidence: 0.0,
      emotionCounts: {},
      summaryText: '今天還沒有貓咪紀錄，試著錄下第一聲喵，看看牠想表達什麼吧！',
      suggestedAction: '點擊首頁的翻譯按鈕，錄下貓叫聲開始翻譯！',
      warningLevel: WarningLevel.normal,
      headlineText: '今天還沒有紀錄',
      createdAt: DateTime.now(),
    );
  }

  /// 取得情緒分布敘述
  String get emotionDistributionText {
    if (emotionCounts.isEmpty) return '還沒有情緒紀錄';

    final sorted = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted
        .take(3)
        .map((e) => '${e.key.emoji} ${e.key.label}: ${e.value}次')
        .join(' | ');
  }
}

/// 警示等級
enum WarningLevel {
  normal,   // 正常，無需擔心
  notice,   // 需要留意
  attention, // 需要關注
}

extension WarningLevelExtension on WarningLevel {
  String get label {
    switch (this) {
      case WarningLevel.normal:
        return '正常';
      case WarningLevel.notice:
        return '留意';
      case WarningLevel.attention:
        return '關注';
    }
  }

  String get emoji {
    switch (this) {
      case WarningLevel.normal:
        return '✅';
      case WarningLevel.notice:
        return '👀';
      case WarningLevel.attention:
        return '⚠️';
    }
  }

  String get colorHex {
    switch (this) {
      case WarningLevel.normal:
        return '#4CAF50';
      case WarningLevel.notice:
        return '#FF9800';
      case WarningLevel.attention:
        return '#F44336';
    }
  }
}
