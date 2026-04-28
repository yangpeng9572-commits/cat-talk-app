// 成就系統 - 遊戲化設計
// 讓使用者在使用 App 的同時學習貓咪知識
// Step 14+ 重構：更情緒化的成就名稱與多階段進度

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
  /// 翻譯相關成就（多階段）
  static List<Achievement> getTranslationAchievements() {
    return [
      Achievement(
        id: 'translation_1',
        name: '初次見面',
        description: '完成第一次翻譯',
        emoji: '👋',
        requiredCount: 1,
      ),
      Achievement(
        id: 'translation_3',
        name: '心有靈犀',
        description: '完成3次翻譯，開始懂牠了',
        emoji: '💕',
        requiredCount: 3,
      ),
      Achievement(
        id: 'translation_5',
        name: '默契滿分',
        description: '完成5次翻譯',
        emoji: '✨',
        requiredCount: 5,
      ),
      Achievement(
        id: 'translation_10',
        name: '靈魂連線',
        description: '完成10次翻譯，與貓咪心意相通',
        emoji: '🔮',
        requiredCount: 10,
      ),
      Achievement(
        id: 'translation_20',
        name: '貓語新手',
        description: '完成20次翻譯',
        emoji: '🐱',
        requiredCount: 20,
      ),
      Achievement(
        id: 'translation_35',
        name: '讀心專家',
        description: '完成35次翻譯',
        emoji: '🧠',
        requiredCount: 35,
      ),
      Achievement(
        id: 'translation_50',
        name: '貓語達人',
        description: '完成50次翻譯',
        emoji: '🏅',
        requiredCount: 50,
      ),
      Achievement(
        id: 'translation_75',
        name: '心靈相通',
        description: '完成75次翻譯',
        emoji: '💫',
        requiredCount: 75,
      ),
      Achievement(
        id: 'translation_100',
        name: '貓語大師',
        description: '完成100次翻譯，傳說境界',
        emoji: '🏆',
        requiredCount: 100,
      ),
      Achievement(
        id: 'translation_120',
        name: '喵星使者',
        description: '完成120次翻譯！你是被選中的孩子',
        emoji: '🌟',
        requiredCount: 120,
      ),
    ];
  }

  /// 姿勢辨識成就
  static List<Achievement> getPoseAchievements() {
    return [
      Achievement(
        id: 'pose_1',
        name: '姿勢分析師',
        description: '完成第一次姿勢分析',
        emoji: '📸',
        requiredCount: 1,
      ),
      Achievement(
        id: 'pose_5',
        name: '肢體解讀',
        description: '完成5次姿勢分析',
        emoji: '🔍',
        requiredCount: 5,
      ),
      Achievement(
        id: 'pose_10',
        name: '姿態專家',
        description: '完成10次姿勢分析',
        emoji: '👁️',
        requiredCount: 10,
      ),
    ];
  }

  /// 知識問答成就
  static List<Achievement> getQuizAchievements() {
    return [
      Achievement(
        id: 'quiz_1',
        name: '好學生',
        description: '完成第一次知識問答',
        emoji: '📝',
        requiredCount: 1,
      ),
      Achievement(
        id: 'quiz_5',
        name: '勤學貓奴',
        description: '答對5題知識問答',
        emoji: '📚',
        requiredCount: 5,
      ),
      Achievement(
        id: 'quiz_10',
        name: '貓咪博士',
        description: '答對10題知識問答',
        emoji: '🎓',
        requiredCount: 10,
      ),
    ];
  }

  /// 忠誠度成就（連續使用天數）
  static List<Achievement> getStreakAchievements() {
    return [
      Achievement(
        id: 'streak_3',
        name: '三天連線',
        description: '連續使用3天',
        emoji: '🔥',
        requiredCount: 3,
      ),
      Achievement(
        id: 'streak_7',
        name: '一週陪伴',
        description: '連續使用7天，謝謝你的陪伴',
        emoji: '💪',
        requiredCount: 7,
      ),
      Achievement(
        id: 'streak_14',
        name: '兩週信任',
        description: '連續使用14天',
        emoji: '🤝',
        requiredCount: 14,
      ),
      Achievement(
        id: 'streak_30',
        name: '一個月摯友',
        description: '連續使用30天，你是最棒的鏟屎官',
        emoji: '👑',
        requiredCount: 30,
      ),
    ];
  }

  /// 特殊成就
  static List<Achievement> getSpecialAchievements() {
    return [
      Achievement(
        id: 'night_owl',
        name: '夜貓族人',
        description: '在半夜使用翻譯功能',
        emoji: '🌙',
        requiredCount: 1,
      ),
      Achievement(
        id: 'early_bird',
        name: '早起鳥兒',
        description: '在早上使用翻譯功能',
        emoji: '🌅',
        requiredCount: 1,
      ),
      Achievement(
        id: 'multi_cat',
        name: '多貓家庭',
        description: '添加3隻以上的貓',
        emoji: '🏠',
        requiredCount: 3,
      ),
      Achievement(
        id: 'feedback_master',
        name: '回饋達人',
        description: '給予10次翻譯回饋',
        emoji: '👍',
        requiredCount: 10,
      ),
    ];
  }

  /// 取得所有成就
  static List<Achievement> getAllAchievements() {
    return [
      ...getTranslationAchievements(),
      ...getPoseAchievements(),
      ...getQuizAchievements(),
      ...getStreakAchievements(),
      ...getSpecialAchievements(),
    ];
  }

  /// 等級系統
  static String getLevel(int totalActions) {
    if (totalActions < 5) return '見習貓奴 🐱';
    if (totalActions < 15) return '新手貓奴 🐱🐱';
    if (totalActions < 30) return '中級貓奴 🐱🐱🐱';
    if (totalActions < 50) return '高級貓奴 🐱🐱🐱🐱';
    if (totalActions < 100) return '貓語專家 🐱⬆️';
    if (totalActions < 150) return '貓語大師 🐱🔥';
    if (totalActions < 200) return '傳說鏟屎官 🐱✨';
    return '喵星使者 🌟';
  }

  static int getLevelProgress(int totalActions) {
    // 計算到下一級的進度
    if (totalActions < 5) return ((totalActions / 5) * 100).round();
    if (totalActions < 15) return ((totalActions / 15) * 100).round();
    if (totalActions < 30) return ((totalActions / 30) * 100).round();
    if (totalActions < 50) return ((totalActions / 50) * 100).round();
    if (totalActions < 100) return ((totalActions / 100) * 100).round();
    if (totalActions < 150) return ((totalActions / 150) * 100).round();
    if (totalActions < 200) return ((totalActions / 200) * 100).round();
    return 100;
  }
}
