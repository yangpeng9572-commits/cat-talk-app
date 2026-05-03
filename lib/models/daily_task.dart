/// 每日任務 Model
class DailyTask {
  final String id;
  final String title;
  final String description;
  final TaskType type;
  final int targetCount;
  final int currentCount;
  final int rewardExp;
  final bool isCompleted;
  final DateTime date;
  final DateTime? completedAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    this.currentCount = 0,
    required this.rewardExp,
    this.isCompleted = false,
    required this.date,
    this.completedAt,
  });

  /// 取得完成進度（0.0 - 1.0）
  double get progress => targetCount > 0 
      ? (currentCount / targetCount).clamp(0.0, 1.0) 
      : 0.0;

  /// 進度文字
  String get progressText => '$currentCount / $targetCount';

  /// 是否已達成
  bool get isAchieved => currentCount >= targetCount;

  /// 複製並更新
  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    TaskType? type,
    int? targetCount,
    int? currentCount,
    int? rewardExp,
    bool? isCompleted,
    DateTime? date,
    DateTime? completedAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardExp: rewardExp ?? this.rewardExp,
      isCompleted: isCompleted ?? this.isCompleted,
      date: date ?? this.date,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// 轉換成 Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'rewardExp': rewardExp,
      'isCompleted': isCompleted,
      'date': date.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// 從 Map 建立
  factory DailyTask.fromJson(Map<String, dynamic> json) {
    return DailyTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: TaskType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TaskType.translate_meow,
      ),
      targetCount: json['targetCount'] as int,
      currentCount: json['currentCount'] as int? ?? 0,
      rewardExp: json['rewardExp'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      date: DateTime.parse(json['date'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

/// 任務類型
enum TaskType {
  translate_meow,    // 翻譯貓叫聲（已停用，等待產品調整）
  view_daily_report, // 查看每日報告
  give_feedback,     // 回饋翻譯（已停用，等待產品調整）
  add_cat_note,      // 新增貓咪備註
  play_with_cat,     // 陪貓玩耍
  pose_photo,        // 拍照記錄（新增）
  cat_world_interact, // 小世界互動（新增）
}

extension TaskTypeExtension on TaskType {
  /// 任務 icon
  String get emoji {
    switch (this) {
      case TaskType.translate_meow:
        return '🎤';
      case TaskType.view_daily_report:
        return '📊';
      case TaskType.give_feedback:
        return '👍';
      case TaskType.add_cat_note:
        return '📝';
      case TaskType.play_with_cat:
        return '🎾';
      case TaskType.pose_photo:
        return '📷';
      case TaskType.cat_world_interact:
        return '🏡';
    }
  }

  /// 任務類型名稱
  String get label {
    switch (this) {
      case TaskType.translate_meow:
        return '翻譯';
      case TaskType.view_daily_report:
        return '報告';
      case TaskType.give_feedback:
        return '回饋';
      case TaskType.add_cat_note:
        return '備註';
      case TaskType.play_with_cat:
        return '玩耍';
      case TaskType.pose_photo:
        return '拍照';
      case TaskType.cat_world_interact:
        return '小世界';
    }
  }
}
