import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_result.dart';
import '../models/cat.dart';

/// 翻譯歷史資料服務
/// 
/// 使用 SharedPreferences 持久化儲存
/// 依 catId 分開儲存，保留最近 30 天資料
class TranslationHistoryService {
  // 單例模式
  static final TranslationHistoryService _instance = TranslationHistoryService._internal();
  factory TranslationHistoryService() => _instance;
  TranslationHistoryService._internal();

  SharedPreferences? _prefs;
  
  // 記憶體緩存（減少磁碟讀取）
  final Map<String, List<TranslationResult>> _memoryCache = {};
  
  // Storage key prefix
  static const String _storageKeyPrefix = 'translation_history_';
  static const int _maxDaysToKeep = 30; // 保留最近 30 天

  /// 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    // 載入所有貓的歷史到記憶體
    await _loadAllToMemory();
  }

  /// 將所有貓的歷史載入記憶體
  Future<void> _loadAllToMemory() async {
    if (_prefs == null) return;
    
    final allKeys = _prefs!.getKeys();
    final historyKeys = allKeys.where((k) => k.startsWith(_storageKeyPrefix));
    
    for (final key in historyKeys) {
      final catId = key.substring(_storageKeyPrefix.length);
      final jsonStr = _prefs!.getString(key);
      if (jsonStr != null) {
        try {
          final List<dynamic> jsonList = jsonDecode(jsonStr);
          _memoryCache[catId] = jsonList
              .map((j) => TranslationResult.fromJson(j as Map<String, dynamic>))
              .toList();
          // 清理過期資料
          _memoryCache[catId] = _filterRecentDays(_memoryCache[catId]!);
        } catch (e) {
          _memoryCache[catId] = [];
        }
      }
    }
  }

  /// 過濾出最近 N 天的資料
  List<TranslationResult> _filterRecentDays(List<TranslationResult> history, {int? days}) {
    final cutoff = DateTime.now().subtract(Duration(days: days ?? _maxDaysToKeep));
    return history.where((r) => r.createdAt.isAfter(cutoff)).toList();
  }

  /// 取得所有歷史記錄（由新到舊）
  List<TranslationResult> getAll() {
    final all = <TranslationResult>[];
    for (final list in _memoryCache.values) {
      all.addAll(list);
    }
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  /// 依照貓咪 ID 取得歷史記錄
  List<TranslationResult> getByCatId(String catId) {
    return List<TranslationResult>.from(_memoryCache[catId] ?? []).reversed.toList();
  }

  /// 依照貓咪 ID 取得最近 N 天的歷史記錄
  List<TranslationResult> getByCatIdWithinDays(String catId, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final all = _memoryCache[catId] ?? [];
    return all.where((r) => r.createdAt.isAfter(cutoff)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 新增翻譯記錄
  Future<void> add(TranslationResult result) async {
    if (!_memoryCache.containsKey(result.catId)) {
      _memoryCache[result.catId] = [];
    }
    _memoryCache[result.catId]!.add(result);
    
    // 清理過期資料
    _memoryCache[result.catId] = _filterRecentDays(_memoryCache[result.catId]!);
    
    // 保存到磁碟
    await _saveToDisk(result.catId);
  }

  /// 更新翻譯記錄（帶入回饋）
  Future<void> updateWithFeedback(TranslationResult result, UserFeedback feedback) async {
    final list = _memoryCache[result.catId];
    if (list == null) return;
    
    final index = list.indexWhere((r) => r.id == result.id);
    if (index != -1) {
      _memoryCache[result.catId]![index] = result.copyWith(userFeedback: feedback);
      await _saveToDisk(result.catId);
    }
  }

  /// 刪除單筆記錄
  Future<void> delete(String id) async {
    for (final catId in _memoryCache.keys) {
      final list = _memoryCache[catId]!;
      final index = list.indexWhere((r) => r.id == id);
      if (index != -1) {
        list.removeAt(index);
        await _saveToDisk(catId);
        break;
      }
    }
  }

  /// 刪除特定貓咪的所有歷史
  Future<void> deleteByCatId(String catId) async {
    _memoryCache.remove(catId);
    await _prefs?.remove('$_storageKeyPrefix$catId');
  }

  /// 清除所有記錄
  Future<void> clearAll() async {
    _memoryCache.clear();
    if (_prefs == null) return;
    
    final allKeys = _prefs!.getKeys().where((k) => k.startsWith(_storageKeyPrefix));
    for (final key in allKeys) {
      await _prefs!.remove(key);
    }
  }

  /// 取得總記錄數
  int get count {
    int total = 0;
    for (final list in _memoryCache.values) {
      total += list.length;
    }
    return total;
  }

  /// 儲存到磁碟
  Future<void> _saveToDisk(String catId) async {
    if (_prefs == null) return;
    
    final list = _memoryCache[catId] ?? [];
    final jsonList = list.map((r) => r.toJson()).toList();
    await _prefs!.setString('$_storageKeyPrefix$catId', jsonEncode(jsonList));
  }

  /// 取得某隻貓的記錄數量
  int getCountByCatId(String catId) {
    return _memoryCache[catId]?.length ?? 0;
  }

  /// 測試用：新增一筆模擬資料（使用記憶體，不持久化）
  void addMockData() {
    final now = DateTime.now();
    final emotions = EmotionType.values.where((e) => e != EmotionType.other).toList();
    final cats = Cat.getDemoCats();

    // 如果沒有 demo 貓，建立一個預設貓
    if (cats.isEmpty) {
      cats.add(Cat(
        id: 'demo_cat',
        name: '奶茶',
        breed: '英國短毛貓',
      ));
    }

    for (int i = 0; i < 10; i++) {
      final emotion = emotions[i % emotions.length];
      final cat = cats[i % cats.length];

      final result = TranslationResult(
        id: 'mock_${now.millisecondsSinceEpoch}_$i',
        catId: cat.id,
        emotionType: emotion,
        humanText: _generateHumanText(emotion),
        confidence: 0.6 + (i % 4) * 0.1,
        reason: _generateReason(emotion),
        suggestedAction: _getSuggestedAction(emotion),
        audioFeatures: AudioFeatures(
          duration: 1000.0 + i * 200,
          volume: 0.5 + i * 0.05,
          pitch: 400.0 + i * 20,
          meowCount: 1 + i % 3,
          isRapid: i % 2 == 0,
          isLongMeow: i % 3 == 0,
          recordedAt: now.subtract(Duration(hours: i)),
        ),
        createdAt: now.subtract(Duration(hours: i)),
        userFeedback: i % 3 == 0
            ? UserFeedback(
                isCorrect: false,
                correctedEmotion: emotions[(i + 1) % emotions.length].name,
                timestamp: now.subtract(Duration(hours: i - 1)),
              )
            : i % 4 == 0
                ? UserFeedback.correct()
                : null,
      );
      
      // 加入記憶體（但不放磁碟，因為這是 mock 資料）
      _memoryCache.putIfAbsent(cat.id, () => []).add(result);
    }
  }

  String _generateHumanText(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.hungry:
        return '我餓了！快給我吃的！🍽️';
      case EmotionType.affectionate:
        return '抱抱我嘛～我想要撒嬌 💕';
      case EmotionType.playful:
        return '陪我玩嘛！我好無聊！ 🎾';
      case EmotionType.attention:
        return '你在哪裡？我需要你！ 👀';
      case EmotionType.anxious:
        return '我覺得不太對勁... 😿';
      case EmotionType.angry:
        return '哼！我生氣了！ 😾';
      case EmotionType.uncomfortable:
        return '我不舒服... 🤒';
      case EmotionType.greeting:
        return '嗨！你在這裡！ 👋';
      default:
        return '喵～';
    }
  }

  String _generateReason(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.hungry:
        return '低沈的叫聲搭配重複的喵聲，符合肚子餓的特徵';
      case EmotionType.affectionate:
        return '長音喵叫搭配柔和的音量，像是想要撒嬌';
      case EmotionType.playful:
        return '高音叫聲，搭配輕快的節奏';
      case EmotionType.attention:
        return '連續叫聲，音量穩定，需要關注';
      case EmotionType.anxious:
        return '快速且高音的叫聲，通常表示焦慮不安';
      case EmotionType.angry:
        return '大聲且高音的急促叫聲';
      case EmotionType.uncomfortable:
        return '低沉且緩慢的叫聲，可能表示身體不適';
      case EmotionType.greeting:
        return '單次且音量適中的叫聲，符合問候模式';
      default:
        return '無法明確分類';
    }
  }

  String _getSuggestedAction(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.hungry:
        return '檢查貓碗是否空了，考慮給予食物';
      case EmotionType.affectionate:
        return '花幾分鐘撫摸你的貓，或陪牠玩一下';
      case EmotionType.playful:
        return '拿出玩具或逗貓棒，和貓咪互動玩耍';
      case EmotionType.attention:
        return '停下手中的事，花時間陪伴你的貓';
      case EmotionType.anxious:
        return '檢查環境是否有讓貓咪緊張的因素，提供安撫';
      case EmotionType.angry:
        return '給貓咪一些空間，避免直接接觸，等牠冷靜下來';
      case EmotionType.uncomfortable:
        return '觀察貓咪是否有其他異常症狀，必要时就醫';
      case EmotionType.greeting:
        return '回應貓咪的問候，和牠打招呼';
      default:
        return '持續觀察貓咪的行為和狀態';
    }
  }
}
