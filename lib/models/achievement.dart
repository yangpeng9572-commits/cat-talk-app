// 成就系統 - 遊戲化設計
// 讓使用者在使用 App 的同時學習貓咪知識

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int requiredCount;
  final int currentCount;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requiredCount,
    this.currentCount = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progress => (currentCount / requiredCount).clamp(0.0, 1.0);

  String get progressText => '$currentCount / $requiredCount';
}

class AchievementSystem {
  static List<Achievement> getAllAchievements() {
    return [
      // ===== 翻譯相關成就 =====
      Achievement(
        id: 'first_translation',
        name: '初次見面',
        description: '完成第一次翻譯',
        emoji: '👋',
        requiredCount: 1,
      ),
      Achievement(
        id: 'translation_10',
        name: '貓語新手',
        description: '完成10次翻譯',
        emoji: '🐱',
        requiredCount: 10,
      ),
      Achievement(
        id: 'translation_50',
        name: '貓語達人',
        description: '完成50次翻譯',
        emoji: '🐱⬆️',
        requiredCount: 50,
      ),
      Achievement(
        id: 'translation_100',
        name: '貓語大師',
        description: '完成100次翻譯',
        emoji: '🐱🔥',
        requiredCount: 100,
      ),

      // ===== 姿勢辨識成就 =====
      Achievement(
        id: 'pose_first',
        name: '姿勢分析師',
        description: '完成第一次姿勢分析',
        emoji: '📸',
        requiredCount: 1,
      ),
      Achievement(
        id: 'pose_10',
        name: '肢體語言專家',
        description: '完成10次姿勢分析',
        emoji: '🔍',
        requiredCount: 10,
      ),

      // ===== 知識問答成就 =====
      Achievement(
        id: 'quiz_first',
        name: '好學生',
        description: '完成第一次知識問答',
        emoji: '📝',
        requiredCount: 1,
      ),
      Achievement(
        id: 'quiz_10',
        name: '貓咪博士',
        description: '答對10題知識問答',
        emoji: '🎓',
        requiredCount: 10,
      ),

      // ===== 忠誠度成就 =====
      Achievement(
        id: 'daily_3',
        name: '連續3天',
        description: '連續使用3天',
        emoji: '🔥',
        requiredCount: 3,
      ),
      Achievement(
        id: 'daily_7',
        name: '一週貓奴',
        description: '連續使用7天',
        emoji: '💪',
        requiredCount: 7,
      ),
      Achievement(
        id: 'daily_30',
        name: '一個月鏟屎官',
        description: '連續使用30天',
        emoji: '👑',
        requiredCount: 30,
      ),

      // ===== 特殊成就 =====
      Achievement(
        id: 'night_owl',
        name: '夜貓子',
        description: '在半夜使用翻譯功能',
        emoji: '🌙',
        requiredCount: 1,
      ),
      Achievement(
        id: 'early_bird',
        name: '早起鳥',
        description: '在早上使用翻譯功能',
        emoji: '🌅',
        requiredCount: 1,
      ),
      Achievement(
        id: 'all_cats',
        name: '多貓家庭',
        description: '添加3隻以上的貓',
        emoji: '🏠',
        requiredCount: 3,
      ),
    ];
  }

  // 等級系統
  static String getLevel(int totalActions) {
    if (totalActions < 10) return '見習貓奴 🐱';
    if (totalActions < 30) return '新手貓奴 🐱🐱';
    if (totalActions < 50) return '中級貓奴 🐱🐱🐱';
    if (totalActions < 100) return '高級貓奴 🐱🐱🐱🐱';
    if (totalActions < 200) return '貓語專家 🐱⬆️';
    if (totalActions < 500) return '貓語大師 🐱🔥';
    return '傳說中的貓語宗師 🐱✨';
  }

  static int getLevelProgress(int totalActions) {
    // 計算到下一級的進度
    if (totalActions < 10) return ((totalActions / 10) * 100).round();
    if (totalActions < 30) return ((totalActions / 30) * 100).round();
    if (totalActions < 50) return ((totalActions / 50) * 100).round();
    if (totalActions < 100) return ((totalActions / 100) * 100).round();
    if (totalActions < 200) return ((totalActions / 200) * 100).round();
    if (totalActions < 500) return ((totalActions / 500) * 100).round();
    return 100;
  }
}
