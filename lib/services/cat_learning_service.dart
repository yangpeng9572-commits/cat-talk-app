import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/translation_result.dart';
import 'translation_history_service.dart';

/// 個別貓咪學習服務
/// 
/// 使用 SharedPreferences 持久化儲存學習資料
/// 學習每隻貓的叫聲模式，提高翻譯準確度
class CatLearningService {
  // 單例模式
  static final CatLearningService _instance = CatLearningService._internal();
  factory CatLearningService() => _instance;
  CatLearningService._internal();

  final TranslationHistoryService _historyService = TranslationHistoryService();
  
  SharedPreferences? _prefs;
  
  // Storage key
  static const String _storageKey = 'cat_learning_data';
  
  // 學習因子權重（用於調整翻譯）
  // 每次使用者修正，該情緒的權重 +0.1
  static const double _correctionBoost = 0.1;
  
  // 最大權重上限
  static const double _maxBoost = 0.5;

  // 情緒權重表（依據貓咪 ID）
  // Map<catId, Map<emotionType, boostValue>>
  final Map<String, Map<String, double>> _catEmotionBoosts = {};

  // 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
    await _loadFromDisk();
  }

  /// 從磁碟載入學習資料
  Future<void> _loadFromDisk() async {
    if (_prefs == null) return;
    
    final jsonStr = _prefs!.getString(_storageKey);
    if (jsonStr == null) return;
    
    try {
      final Map<String, dynamic> json = jsonDecode(jsonStr);
      for (final entry in json.entries) {
        final catId = entry.key;
        final boosts = <String, double>{};
        final data = entry.value as Map<String, dynamic>;
        for (final boostEntry in data.entries) {
          boosts[boostEntry.key] = (boostEntry.value as num).toDouble();
        }
        _catEmotionBoosts[catId] = boosts;
      }
    } catch (e) {
      // 忽略解析錯誤
    }
  }

  /// 保存到磁碟
  Future<void> _saveToDisk() async {
    if (_prefs == null) return;
    
    final json = <String, dynamic>{};
    for (final catEntry in _catEmotionBoosts.entries) {
      json[catEntry.key] = catEntry.value;
    }
    await _prefs!.setString(_storageKey, jsonEncode(json));
  }

  // ═══════════════════════════════════════════════════════════════
  // 公開 API
  // ═══════════════════════════════════════════════════════════════

  /// 記錄使用者的修正（學習）
  /// 
  /// 當使用者修正翻譯結果時呼叫
  Future<void> learnFromCorrection(String catId, EmotionType correctedEmotion) async {
    if (!_catEmotionBoosts.containsKey(catId)) {
      _catEmotionBoosts[catId] = {};
    }

    final currentBoost = _catEmotionBoosts[catId]![correctedEmotion.name] ?? 0.0;
    final newBoost = (currentBoost + _correctionBoost).clamp(0.0, _maxBoost);
    _catEmotionBoosts[catId]![correctedEmotion.name] = newBoost;
    
    await _saveToDisk();
  }

  /// 記錄使用者確認正確（正向學習）
  Future<void> learnFromConfirmation(String catId, EmotionType emotion) async {
    // 確認也是一種學習，但權重較低
    if (!_catEmotionBoosts.containsKey(catId)) {
      _catEmotionBoosts[catId] = {};
    }

    final currentBoost = _catEmotionBoosts[catId]![emotion.name] ?? 0.0;
    final newBoost = (currentBoost + _correctionBoost * 0.5).clamp(0.0, _maxBoost);
    _catEmotionBoosts[catId]![emotion.name] = newBoost;
    
    await _saveToDisk();
  }

  /// 根據貓咪歷史取得情緒權重調整
  /// 
  /// 回傳 Map<EmotionType, boost>
  Map<EmotionType, double> getEmotionBoosts(String catId) {
    final boosts = <EmotionType, double>{};

    if (!_catEmotionBoosts.containsKey(catId)) {
      return boosts;
    }

    final catBoosts = _catEmotionBoosts[catId]!;
    for (final entry in catBoosts.entries) {
      final emotion = EmotionType.values.firstWhere(
        (e) => e.name == entry.key,
        orElse: () => EmotionType.other,
      );
      boosts[emotion] = entry.value;
    }

    return boosts;
  }

  /// 取得情緒權重（用於報告生成）
  /// 
  /// 與 getEmotionBoosts 相同，但名稱更直觀
  Map<EmotionType, double> getEmotionWeights(String catId) {
    return getEmotionBoosts(catId);
  }

  /// 取得最常被修正的情緒
  EmotionType? getMostCorrectedEmotion(String catId) {
    if (!_catEmotionBoosts.containsKey(catId)) {
      return null;
    }

    final catBoosts = _catEmotionBoosts[catId]!;
    if (catBoosts.isEmpty) return null;

    // 找出權重最高的
    final sorted = catBoosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return null;

    return EmotionType.values.firstWhere(
      (e) => e.name == sorted.first.key,
      orElse: () => EmotionType.other,
    );
  }

  /// 根據貓咪歷史調整翻譯結果
  /// 
  /// 這個方法會：
  /// 1. 查詢該貓咪過去的修正紀錄
  /// 2. 找出最常被修正成某種情緒
  /// 3. 在翻譯結果出來後，調整該情緒的 confidence
  TranslationResult adjustResultWithLearning(
    TranslationResult result,
    AudioFeatures features,
  ) {
    if (!_catEmotionBoosts.containsKey(result.catId)) {
      return result; // 沒有學習資料，直接回傳
    }

    final boosts = _catEmotionBoosts[result.catId]!;
    
    // 找出這個貓咪最常被修正成哪種情緒
    final sortedBoosts = boosts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedBoosts.isEmpty) {
      return result;
    }

    // 套用調整（套用到翻譯結果的 confidence）
    final topEmotion = EmotionType.values.firstWhere(
      (e) => e.name == sortedBoosts.first.key,
      orElse: () => result.emotionType,
    );

    // 如果原本的結果已經是這個情緒，給予信心加成
    if (result.emotionType == topEmotion) {
      final adjustedConfidence = (result.confidence + sortedBoosts.first.value)
          .clamp(0.0, 1.0);
      return result.copyWith(confidence: adjustedConfidence);
    }

    return result;
  }

  /// 取得該貓咪的學習統計
  CatLearningStats getStats(String catId) {
    final boosts = getEmotionBoosts(catId);
    final history = _historyService.getByCatId(catId);
    
    // 計算各種統計
    final corrections = history.where((r) => 
      r.userFeedback != null && !r.userFeedback!.isCorrect
    ).toList();
    
    final confirmations = history.where((r) => 
      r.userFeedback != null && r.userFeedback!.isCorrect
    ).toList();

    // 找出最常被修正成哪種情緒
    final correctionEmotions = corrections
        .map((r) => r.userFeedback!.correctedEmotion)
        .where((e) => e != null)
        .toList();

    String? favoriteCorrection;
    if (correctionEmotions.isNotEmpty) {
      favoriteCorrection = correctionEmotions.first;
    }

    return CatLearningStats(
      catId: catId,
      totalTranslations: history.length,
      totalCorrections: corrections.length,
      totalConfirmations: confirmations.length,
      emotionBoosts: boosts,
      favoriteCorrection: favoriteCorrection,
      hasLearningData: boosts.isNotEmpty,
    );
  }

  /// 清除特定貓咪的學習資料
  Future<void> clearLearningForCat(String catId) async {
    _catEmotionBoosts.remove(catId);
    await _saveToDisk();
  }

  /// 清除所有學習資料
  Future<void> clearAll() async {
    _catEmotionBoosts.clear();
    await _prefs?.remove(_storageKey);
  }

  // ═══════════════════════════════════════════════════════════════
  // 未來擴充接口（Firebase / AI 模型）
  // ═══════════════════════════════════════════════════════════════

  /// TODO: Firebase 同步
  Future<void> syncToCloud() async {
    throw UnimplementedError('Firebase 同步尚未整合');
  }

  /// TODO: 從雲端恢復學習資料
  Future<void> restoreFromCloud(String catId) async {
    throw UnimplementedError('Firebase 恢復尚未整合');
  }

  /// TODO: AI 模型訓練介面
  Future<void> trainCatModel(String catId) async {
    throw UnimplementedError('AI 模型訓練尚未整合');
  }

  /// TODO: 使用 AI 模型預測
  Future<EmotionType> predictWithAI(
    String catId,
    AudioFeatures features,
  ) async {
    throw UnimplementedError('AI 預測尚未整合');
  }
}

/// 貓咪學習統計資料
class CatLearningStats {
  final String catId;
  final int totalTranslations;
  final int totalCorrections;
  final int totalConfirmations;
  final Map<EmotionType, double> emotionBoosts;
  final String? favoriteCorrection;
  final bool hasLearningData;

  const CatLearningStats({
    required this.catId,
    required this.totalTranslations,
    required this.totalCorrections,
    required this.totalConfirmations,
    required this.emotionBoosts,
    this.favoriteCorrection,
    required this.hasLearningData,
  });

  /// 取得學習進度百分比
  double get learningProgress {
    if (totalTranslations == 0) return 0.0;
    return (totalCorrections + totalConfirmations) / totalTranslations;
  }

  /// 取得準確率（確認 / 總翻譯數）
  double get accuracyRate {
    if (totalTranslations == 0) return 0.0;
    return totalConfirmations / totalTranslations;
  }
}
