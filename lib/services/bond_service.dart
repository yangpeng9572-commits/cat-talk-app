import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bond.dart';

/// 默契值服務
/// 負責管理每隻貓的默契值（0-100）
class BondService {
  static final BondService _instance = BondService._internal();
  factory BondService() => _instance;
  BondService._internal();

  static const String _bondKeyPrefix = 'bond_';
  static const String _historyKeyPrefix = 'bond_history_';
  
  SharedPreferences? _prefs;

  // ===== 默契值加分事件類型 =====
  static const String eventTranslation = 'translation';      // 完成翻譯 +2
  static const String eventViewReport = 'view_report';    // 查看報告 +1
  static const String eventFeedback = 'feedback';         // 回饋 +3
  static const String eventTaskComplete = 'task_complete'; // 任務完成 +5
  static const String eventStreakBonus = 'streak_bonus';  // 連續陪伴 +10
  static const String eventActionTap = 'action_tap';       // 點擊建議行動 +1

  // ===== 每種事件的分數 =====
  static const Map<String, int> _eventScores = {
    eventTranslation: 2,
    eventViewReport: 1,
    eventFeedback: 3,
    eventTaskComplete: 5,
    eventStreakBonus: 10,
    eventActionTap: 1,
  };

  // ===== 常數 =====
  static const int maxDailyGain = 20;  // 每日上限
  static const int maxBondScore = 100; // 最高分

  /// 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// 取得某隻貓的默契值資料
  Bond getBond(String catId) {
    if (_prefs == null) return Bond.empty(catId);
    
    final jsonStr = _prefs!.getString('$_bondKeyPrefix$catId');
    if (jsonStr == null) return Bond.empty(catId);
    
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final bond = Bond.fromJson(json);
      
      // 檢查是否新的一天，如果是則重置
      return _checkAndResetDaily(bond);
    } catch (e) {
      return Bond.empty(catId);
    }
  }

  /// 檢查並重置每日狀態
  Bond _checkAndResetDaily(Bond bond) {
    final now = DateTime.now();
    final lastUpdate = bond.lastUpdated;
    
    // 如果是最後更新是今天
    if (lastUpdate.year == now.year &&
        lastUpdate.month == now.month &&
        lastUpdate.day == now.day) {
      return bond;
    }
    
    // 新的一天，重置
    return bond.copyWith(
      todayGain: 0,
      streakBonusApplied: false,
      lastUpdated: now,
    );
  }

  /// 儲存默契值
  Future<void> _saveBond(Bond bond) async {
    if (_prefs == null) return;
    
    // 檢查是否升級
    final newLevelName = Bond.getLevelName(bond.bondScore);
    final updatedBond = bond.copyWith(
      levelName: newLevelName,
      lastUpdated: DateTime.now(),
    );
    
    await _prefs!.setString(
      '$_bondKeyPrefix${bond.catId}',
      jsonEncode(updatedBond.toJson()),
    );
  }

  /// 嘗試加分
  /// 返回分數增加量（0 表示未加分）
  /// 
  /// eventKey 規則：
  /// - 有 translationId 的事件：${eventType}_${translationId}（每翻譯最多一次）
  /// - 無 translationId 的事件：${eventType}_${timestamp}（每天每事件型別可多次）
  Future<int> addBond(String catId, String eventType, {String? translationId}) async {
    final bond = getBond(catId);
    
    // 檢查每日上限
    if (bond.todayGain >= maxDailyGain) {
      return 0;
    }
    
    // 建立事件 key
    // 有 translationId → 每翻譯唯一（有 translationId 表示該事件與特定翻譯綁定）
    // 無 translationId → 每天每 eventType 只能加一次（視為一次性事件）
    final String eventKey;
    if (translationId != null) {
      eventKey = '${eventType}_$translationId';
    } else {
      // 一次性事件：每天每 eventType 只能加一次
      // 使用日期作為區分，這樣第二天可以重新計算
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month}${now.day}';
      eventKey = '${eventType}_$dateStr';
    }
    
    if (bond.eventTracking[eventKey] == true) {
      return 0; // 已加過分
    }
    
    // 取得分數
    final scoreToAdd = _eventScores[eventType] ?? 0;
    if (scoreToAdd == 0) return 0;
    
    // 計算新分數（不超過100）
    final newScore = (bond.bondScore + scoreToAdd).clamp(0, maxBondScore);
    
    // 計算今日增加
    final actualGain = newScore - bond.bondScore;
    final newTodayGain = bond.todayGain + actualGain;
    
    // 更新追蹤
    final newTracking = Map<String, bool>.from(bond.eventTracking);
    newTracking[eventKey] = true;
    
    // 建立新 Bond
    final newBond = bond.copyWith(
      bondScore: newScore,
      todayGain: newTodayGain,
      totalGain: bond.totalGain + actualGain,
      eventTracking: newTracking,
    );
    
    await _saveBond(newBond);
    
    // 記錄歷史
    await _recordHistory(catId, actualGain);
    
    return actualGain;
  }

  /// 記錄歷史
  Future<void> _recordHistory(String catId, int gain) async {
    if (_prefs == null) return;
    
    final now = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final historyKey = '$_historyKeyPrefix$catId';
    final historyJson = _prefs!.getString(historyKey);
    
    Map<String, int> history = {};
    if (historyJson != null) {
      history = Map<String, int>.from(jsonDecode(historyJson) as Map);
    }
    
    // 取得或初始化當天
    history[dateKey] = (history[dateKey] ?? 0) + gain;
    
    // 只保留最近7天
    final sortedKeys = history.keys.toList()..sort();
    if (sortedKeys.length > 7) {
      for (final key in sortedKeys.take(sortedKeys.length - 7)) {
        history.remove(key);
      }
    }
    
    await _prefs!.setString(historyKey, jsonEncode(history));
  }

  /// 取得歷史記錄（最近7天）
  Map<String, int> getHistory(String catId) {
    if (_prefs == null) return {};
    
    final historyJson = _prefs!.getString('$_historyKeyPrefix$catId');
    if (historyJson == null) return {};
    
    try {
      return Map<String, int>.from(jsonDecode(historyJson) as Map);
    } catch (e) {
      return {};
    }
  }

  /// 套用連續陪伴獎勵
  Future<int> applyStreakBonus(String catId) async {
    final bond = getBond(catId);
    
    // 檢查是否已套用
    if (bond.streakBonusApplied) {
      return 0;
    }
    
    // 檢查每日上限
    if (bond.todayGain >= maxDailyGain) {
      return 0;
    }
    
    // 計算實際可加分
    final remainingDaily = maxDailyGain - bond.todayGain;
    final actualGain = _eventScores[eventStreakBonus]!.clamp(0, remainingDaily);
    
    if (actualGain == 0) return 0;
    
    // 計算新分數
    final newScore = (bond.bondScore + actualGain).clamp(0, maxBondScore);
    final actualAdded = newScore - bond.bondScore;
    
    // 更新
    final newBond = bond.copyWith(
      bondScore: newScore,
      todayGain: bond.todayGain + actualAdded,
      totalGain: bond.totalGain + actualAdded,
      streakBonusApplied: true,
      eventTracking: {
        ...bond.eventTracking,
        eventStreakBonus: true,
      },
    );
    
    await _saveBond(newBond);
    await _recordHistory(catId, actualAdded);
    
    return actualAdded;
  }

  /// 取得今日親密動作數量
  int getTodayActionCount(String catId) {
    final bond = getBond(catId);
    return bond.eventTracking.keys
        .where((k) => k.startsWith(eventActionTap))
        .length;
  }

  /// 重置所有事件追蹤（新的一天自動）
  /// 這個方法在內部調用，不需要外部調用
}
