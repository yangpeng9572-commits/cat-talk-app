import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';

class AchievementPage extends StatefulWidget {
  const AchievementPage({super.key});

  @override
  State<AchievementPage> createState() => _AchievementPageState();
}

class _AchievementPageState extends State<AchievementPage> {
  AchievementService? _achievementService;
  List<Achievement> _achievements = [];
  int _totalActions = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final prefs = await SharedPreferences.getInstance();
    final service = AchievementService(prefs);
    final achievements = service.getAllAchievements();
    final totalActions = service.getTotalActions();

    if (mounted) {
      setState(() {
        _achievementService = service;
        _achievements = achievements;
        _totalActions = totalActions;
        _isLoading = false;
      });
    }
  }

  String get _levelName {
    return AchievementSystem.getLevel(_totalActions);
  }

  double get _levelProgress {
    return AchievementSystem.getLevelProgress(_totalActions) / 100.0;
  }

  String _getNextLevelHint() {
    final levels = [
      (5, '新手貓奴 🐱🐱'),
      (15, '中級貓奴 🐱🐱🐱'),
      (30, '高級貓奴 🐱🐱🐱🐱'),
      (50, '貓語專家 🐱⬆️'),
      (100, '貓語大師 🐱🔥'),
      (150, '傳說鏟屎官 🐱✨'),
      (200, '喵星使者 🌟'),
    ];
    for (final (threshold, name) in levels) {
      if (_totalActions < threshold) {
        final remaining = threshold - _totalActions;
        return '距離下一級「$name」還差 $remaining 次動作';
      }
    }
    return '已達最高等級！🌟';
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('成就'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // 等級卡片
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '🐱⬆️',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _levelName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '已解鎖 $unlockedCount / ${_achievements.length} 成就',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 等級進度條
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white30,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width *
                                  0.85 *
                                  _levelProgress,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '總動作數：$_totalActions',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNextLevelHint(),
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // 成就列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = _achievements[index];
                      return _buildAchievementCard(achievement);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  /// 根據成就 ID 取得動作類型標籤
  String _getActionLabel(String id) {
    if (id.startsWith('translation')) return '翻譯';
    if (id.startsWith('pose')) return '姿勢分析';
    if (id.startsWith('quiz')) return '答題';
    if (id.startsWith('streak')) return '連續使用';
    if (id == 'multi_cat') return '添加貓咪';
    if (id == 'feedback_master') return '回饋';
    if (id == 'night_owl') return '半夜翻譯';
    if (id == 'early_bird') return '早起翻譯';
    return '動作';
  }

  /// 根據成就 ID 取得解鎖條件文字
  String _getUnlockHint(String id, int required) {
    if (id == 'night_owl') return '在半夜使用翻譯功能';
    if (id == 'early_bird') return '在早上使用翻譯功能';
    if (id == 'multi_cat') return '添加 ${required} 隻以上的貓';
    final label = _getActionLabel(id);
    return '完成 $label × $required 次';
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final hasProgress = achievement.currentCount > 0 && !isUnlocked;
    final actionLabel = _getActionLabel(achievement.id);
    final unlockHint = _getUnlockHint(achievement.id, achievement.requiredCount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(color: Colors.orange, width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Emoji
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked ? Colors.orange.shade100 : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement.emoji : '🔒',
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                // 說明 / 解鎖條件
                if (!isUnlocked && !hasProgress)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '💡 $unlockHint',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )
                else
                  Text(
                    achievement.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isUnlocked ? Colors.orange : Colors.grey,
                    ),
                  ),
                if (hasProgress) ...[
                  const SizedBox(height: 4),
                  // 明確的進度計數
                  Text(
                    '$actionLabel ${achievement.currentCount} / ${achievement.requiredCount} 次',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // 進度條
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: achievement.progress,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        achievement.progressText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (isUnlocked) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '已解鎖',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
