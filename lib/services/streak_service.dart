import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/streak.dart';

/// 連續使用服務
class StreakService {
  static const String _streakKey = 'streak_data';

  final SharedPreferences _prefs;

  StreakService(this._prefs);

  /// 取得目前 streak 資料
  Streak getStreak() {
    final streakJson = _prefs.getString(_streakKey);
    if (streakJson == null) {
      return Streak();
    }
    return Streak.fromJson(jsonDecode(streakJson));
  }

  /// 記錄今日活躍（完成任務後呼叫）
  Future<Streak> recordActivity({int expReward = 0}) async {
    final streak = getStreak();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    Streak updatedStreak;

    if (streak.isActiveToday) {
      // 今天已經活躍過，只增加 exp
      updatedStreak = streak.copyWith(
        totalExp: streak.totalExp + expReward,
      );
    } else if (streak.wasActiveYesterday) {
      // 昨天有活躍，連續天數 +1
      updatedStreak = streak.copyWith(
        currentStreak: streak.currentStreak + 1,
        longestStreak: (streak.currentStreak + 1) > streak.longestStreak
            ? streak.currentStreak + 1
            : streak.longestStreak,
        lastActiveDate: today,
        totalActiveDays: streak.totalActiveDays + 1,
        totalExp: streak.totalExp + expReward,
      );
    } else {
      // 連續中斷，重新開始
      updatedStreak = streak.copyWith(
        currentStreak: 1,
        lastActiveDate: today,
        totalActiveDays: streak.totalActiveDays + 1,
        totalExp: streak.totalExp + expReward,
      );
    }

    _saveStreak(updatedStreak);
    return updatedStreak;
  }

  /// 檢查是否今天已完成任務（用於判斷是否該延長連續天數）
  bool shouldIncrementStreak() {
    final streak = getStreak();
    return !streak.isActiveToday;
  }

  /// 取得連續天數
  int getCurrentStreak() {
    return getStreak().currentStreak;
  }

  /// 取得最長連續天數
  int getLongestStreak() {
    return getStreak().longestStreak;
  }

  /// 取得總 exp
  int getTotalExp() {
    return getStreak().totalExp;
  }

  /// 取得等級
  int getLevel() {
    return getStreak().level;
  }

  /// 儲存 streak
  void _saveStreak(Streak streak) {
    _prefs.setString(_streakKey, jsonEncode(streak.toJson()));
  }
}
