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
    
    return Achievement(
      id: template.id,
      name: template.name,
      description: template.description,
      emoji: template.emoji,
      requiredCount: template.requiredCount,
      currentCount: count,
      isUnlocked: unlocked,
    );
  }
  
  /// 紀錄一次動作並檢查成就
  Future<List<Achievement>> recordAction(String actionType, {int count = 1}) async {
    final unlocked = <Achievement>[];
    
    // 根據動作類型增加進度
    switch (actionType) {
      case 'translation':
        unlocked.addAll(await _incrementAchievement('first_translation'));
        unlocked.addAll(await _incrementAchievement('translation_10'));
        unlocked.addAll(await _incrementAchievement('translation_50'));
        unlocked.addAll(await _incrementAchievement('translation_100'));
        break;
      case 'pose':
        unlocked.addAll(await _incrementAchievement('pose_first'));
        unlocked.addAll(await _incrementAchievement('pose_10'));
        break;
      case 'quiz':
        unlocked.addAll(await _incrementAchievement('quiz_first'));
        unlocked.addAll(await _incrementAchievement('quiz_10'));
        break;
      case 'daily':
        // 這個由 StreakService 控制
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
  
  /// 增加成就進度
  Future<List<Achievement>> _incrementAchievement(String id) async {
    final templates = AchievementSystem.getAllAchievements();
    final template = templates.firstWhere((a) => a.id == id, orElse: () => throw Exception('Unknown achievement: $id'));
    
    final currentCount = (_prefs.getInt('$_prefix${id}_count') ?? 0) + 1;
    final wasUnlocked = _prefs.getBool('$_prefix${id}_unlocked') ?? false;
    
    // 檢查是否解鎖
    final shouldUnlock = currentCount >= template.requiredCount && !wasUnlocked;
    
    await _prefs.setInt('$_prefix${id}_count', currentCount);
    if (shouldUnlock) {
      await _prefs.setBool('$_prefix${id}_unlocked', true);
    }
    
    if (shouldUnlock) {
      // 返回新解鎖的成就
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
  Future<List<Achievement>> recordAddCat() async {
    return _incrementAchievement('all_cats');
  }
  
  /// 取得已解鎖的成就數量
  int getUnlockedCount() {
    final achievements = getAllAchievements();
    return achievements.where((a) => a.isUnlocked).length;
  }
  
  /// 取得總動作數
  int getTotalActions() {
    final count = _prefs.getInt('${_prefix}translation_100_count') ?? 0;
    final pose = _prefs.getInt('${_prefix}pose_10_count') ?? 0;
    final quiz = _prefs.getInt('${_prefix}quiz_10_count') ?? 0;
    return count + pose + quiz;
  }
}
