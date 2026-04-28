import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';

/// 成就服務
/// 管理成就的解鎖進度
class AchievementService {
  static const _prefix = 'achievement_';
  
  final SharedPreferences _prefs;
  
  AchievementService(this._prefs);
  
  /// 取得所有成就（含進度）
  List<Achievement> getAllAchievements() {
    final templates = AchievementSystem.getAllAchievements();
    return templates.map((a) => _loadAchievement(a)).toList();
  }
  
  /// 載入單一成就的進度
  Achievement _loadAchievement(Achievement template) {
    final count = _prefs.getInt('$_prefix${template.id}_count') ?? 0;
    final unlocked = _prefs.getBool('$_prefix${template.id}_unlocked') ?? false;
    final unlockedAtStr = _prefs.getString('$_prefix${template.id}_unlocked_at');
    
    return Achievement(
      id: template.id,
      name: template.name,
      description: template.description,
      emoji: template.emoji,
      requiredCount: template.requiredCount,
      currentCount: count,
      isUnlocked: unlocked,
      unlockedAt: unlockedAtStr != null ? DateTime.tryParse(unlockedAtStr) : null,
    );
  }
  
  /// 紀錄一次翻譯動作並檢查成就
  Future<List<Achievement>> recordTranslation() async {
    return _incrementAchievements('translation');
  }
  
  /// 通用動作記錄
  Future<List<Achievement>> recordAction(String actionType) async {
    switch (actionType) {
      case 'translation':
        return recordTranslation();
      case 'pose':
        return recordPose();
      case 'quiz':
        return recordQuiz();
      case 'feedback':
        return recordFeedback();
      default:
        return [];
    }
  }
  
  /// 紀錄一次姿勢分析動作
  Future<List<Achievement>> recordPose() async {
    return _incrementAchievements('pose');
  }
  
  /// 紀錄一次問答動作
  Future<List<Achievement>> recordQuiz() async {
    return _incrementAchievements('quiz');
  }
  
  /// 紀錄連續天數
  Future<List<Achievement>> recordStreak(int days) async {
    final unlocked = <Achievement>[];
    
    final streakIds = ['streak_3', 'streak_7', 'streak_14', 'streak_30'];
    for (final id in streakIds) {
      final templates = AchievementSystem.getAllAchievements();
      final template = templates.firstWhere((a) => a.id == id, orElse: () => throw Exception('Unknown: $id'));
      
      if (days >= template.requiredCount) {
        unlocked.addAll(await _incrementAchievement(id));
      }
    }
    
    return unlocked;
  }
  
  /// 紀錄回饋
  Future<List<Achievement>> recordFeedback() async {
    return _incrementAchievements('feedback');
  }
  
  /// 內部：根據類型增加進度
  Future<List<Achievement>> _incrementAchievements(String type) async {
    final unlocked = <Achievement>[];
    
    switch (type) {
      case 'translation':
        final ids = ['translation_1', 'translation_3', 'translation_5', 'translation_10', 
                     'translation_20', 'translation_35', 'translation_50', 'translation_75', 
                     'translation_100', 'translation_120'];
        for (final id in ids) {
          unlocked.addAll(await _incrementAchievement(id));
        }
        break;
      case 'pose':
        final ids = ['pose_1', 'pose_5', 'pose_10'];
        for (final id in ids) {
          unlocked.addAll(await _incrementAchievement(id));
        }
        break;
      case 'quiz':
        final ids = ['quiz_1', 'quiz_5', 'quiz_10'];
        for (final id in ids) {
          unlocked.addAll(await _incrementAchievement(id));
        }
        break;
      case 'feedback':
        unlocked.addAll(await _incrementAchievement('feedback_master'));
        break;
    }
    
    // 檢查時間相關成就
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      unlocked.addAll(await _incrementAchievement('night_owl'));
    }
    if (hour >= 6 && hour < 9) {
      unlocked.addAll(await _incrementAchievement('early_bird'));
    }
    
    return unlocked;
  }
  
  /// 增加單一成就進度
  Future<List<Achievement>> _incrementAchievement(String id) async {
    final templates = AchievementSystem.getAllAchievements();
    final template = templates.firstWhere(
      (a) => a.id == id,
      orElse: () => throw Exception('Unknown achievement: $id'),
    );
    
    final currentCount = (_prefs.getInt('$_prefix${id}_count') ?? 0) + 1;
    final wasUnlocked = _prefs.getBool('$_prefix${id}_unlocked') ?? false;
    
    // 檢查是否解鎖
    final shouldUnlock = currentCount >= template.requiredCount && !wasUnlocked;
    
    await _prefs.setInt('$_prefix${id}_count', currentCount);
    if (shouldUnlock) {
      await _prefs.setBool('$_prefix${id}_unlocked', true);
      await _prefs.setString('$_prefix${id}_unlocked_at', DateTime.now().toIso8601String());
    }
    
    if (shouldUnlock) {
      return [Achievement(
        id: template.id,
        name: template.name,
        description: template.description,
        emoji: template.emoji,
        requiredCount: template.requiredCount,
        currentCount: currentCount,
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      )];
    }
    
    return [];
  }
  
  /// 增加貓咪數量
  Future<List<Achievement>> recordAddCat(int catCount) async {
    final unlocked = <Achievement>[];
    
    if (catCount >= 3) {
      unlocked.addAll(await _incrementAchievement('multi_cat'));
    }
    
    return unlocked;
  }
  
  /// 取得已解鎖的成就數量
  int getUnlockedCount() {
    final achievements = getAllAchievements();
    return achievements.where((a) => a.isUnlocked).length;
  }
  
  /// 取得總動作數
  int getTotalActions() {
    int total = 0;
    
    // 翻譯
    final translationIds = ['translation_1', 'translation_3', 'translation_5', 'translation_10', 
                           'translation_20', 'translation_35', 'translation_50', 'translation_75', 
                           'translation_100', 'translation_120'];
    for (final id in translationIds) {
      total += _prefs.getInt('$_prefix${id}_count') ?? 0;
    }
    
    // 姿勢
    final poseIds = ['pose_1', 'pose_5', 'pose_10'];
    for (final id in poseIds) {
      total += _prefs.getInt('$_prefix${id}_count') ?? 0;
    }
    
    return total;
  }
}
