/// 默契值資料模型
class Bond {
  final String catId;
  final int bondScore; // 0-100
  final String levelName;
  final DateTime lastUpdated;
  final int todayGain;
  final int totalGain;
  final bool streakBonusApplied;
  final Map<String, bool> eventTracking; // 追蹤各事件是否已加分

  Bond({
    required this.catId,
    required this.bondScore,
    required this.levelName,
    required this.lastUpdated,
    required this.todayGain,
    required this.totalGain,
    required this.streakBonusApplied,
    required this.eventTracking,
  });

  /// 取得默契值等級名稱
  static String getLevelName(int score) {
    if (score >= 95) return '命定貓奴';
    if (score >= 80) return '靈魂夥伴';
    if (score >= 60) return '心有靈犀';
    if (score >= 40) return '越來越懂';
    if (score >= 25) return '小小默契';
    if (score >= 10) return '開始熟悉';
    return '剛認識';
  }

  /// 取得等級 emoji
  String get levelEmoji {
    if (bondScore >= 95) return '💖';
    if (bondScore >= 80) return '💕';
    if (bondScore >= 60) return '💗';
    if (bondScore >= 40) return '💓';
    if (bondScore >= 25) return '💞';
    if (bondScore >= 10) return '💘';
    return '🐱';
  }

  /// 創建空的 Bond
  factory Bond.empty(String catId) {
    return Bond(
      catId: catId,
      bondScore: 0,
      levelName: getLevelName(0),
      lastUpdated: DateTime.now(),
      todayGain: 0,
      totalGain: 0,
      streakBonusApplied: false,
      eventTracking: {},
    );
  }

  /// 從 JSON
  factory Bond.fromJson(Map<String, dynamic> json) {
    return Bond(
      catId: json['catId'] as String,
      bondScore: json['bondScore'] as int,
      levelName: json['levelName'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      todayGain: json['todayGain'] as int,
      totalGain: json['totalGain'] as int,
      streakBonusApplied: json['streakBonusApplied'] as bool,
      eventTracking: Map<String, bool>.from(json['eventTracking'] as Map),
    );
  }

  /// 轉換成 JSON
  Map<String, dynamic> toJson() {
    return {
      'catId': catId,
      'bondScore': bondScore,
      'levelName': levelName,
      'lastUpdated': lastUpdated.toIso8601String(),
      'todayGain': todayGain,
      'totalGain': totalGain,
      'streakBonusApplied': streakBonusApplied,
      'eventTracking': eventTracking,
    };
  }

  /// copyWith
  Bond copyWith({
    String? catId,
    int? bondScore,
    String? levelName,
    DateTime? lastUpdated,
    int? todayGain,
    int? totalGain,
    bool? streakBonusApplied,
    Map<String, bool>? eventTracking,
  }) {
    return Bond(
      catId: catId ?? this.catId,
      bondScore: bondScore ?? this.bondScore,
      levelName: levelName ?? this.levelName,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      todayGain: todayGain ?? this.todayGain,
      totalGain: totalGain ?? this.totalGain,
      streakBonusApplied: streakBonusApplied ?? this.streakBonusApplied,
      eventTracking: eventTracking ?? this.eventTracking,
    );
  }
}
