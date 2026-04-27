/// 連續使用天數 Model
class Streak {
  final int currentStreak;      // 目前連續天數
  final int longestStreak;      // 最長連續天數
  final DateTime? lastActiveDate; // 最後活躍日期
  final int totalActiveDays;   // 總活躍天數
  final int totalExp;         // 總獲得經驗值

  Streak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.totalActiveDays = 0,
    this.totalExp = 0,
  });

  /// 是否今天已活躍
  bool get isActiveToday {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastActive = DateTime(
      lastActiveDate!.year,
      lastActiveDate!.month,
      lastActiveDate!.day,
    );
    return today == lastActive;
  }

  /// 是否昨天有活躍（用於判斷連續是否中斷）
  bool get wasActiveYesterday {
    if (lastActiveDate == null) return false;
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final lastActive = DateTime(
      lastActiveDate!.year,
      lastActiveDate!.month,
      lastActiveDate!.day,
    );
    return yesterday == lastActive;
  }

  /// 等級（每 100 exp 一級）
  int get level => (totalExp / 100).floor() + 1;

  /// 距離下一級還需要多少 exp
  int get expToNextLevel => 100 - (totalExp % 100);

  /// 等級進度（0.0 - 1.0）
  double get levelProgress => (totalExp % 100) / 100;

  /// 等級標題
  String get levelTitle {
    if (currentStreak >= 30) return '傳說貓奴';
    if (currentStreak >= 14) return '資深貓奴';
    if (currentStreak >= 7) return '忠誠貓奴';
    if (currentStreak >= 3) return '進階貓奴';
    if (currentStreak >= 1) return '新手貓奴';
    return '見習貓奴';
  }

  /// 複製並更新
  Streak copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
    int? totalExp,
  }) {
    return Streak(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      totalExp: totalExp ?? this.totalExp,
    );
  }

  /// 轉換成 Map
  Map<String, dynamic> toJson() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'totalActiveDays': totalActiveDays,
      'totalExp': totalExp,
    };
  }

  /// 從 Map 建立
  factory Streak.fromJson(Map<String, dynamic> json) {
    return Streak(
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.parse(json['lastActiveDate'] as String)
          : null,
      totalActiveDays: json['totalActiveDays'] as int? ?? 0,
      totalExp: json['totalExp'] as int? ?? 0,
    );
  }
}
