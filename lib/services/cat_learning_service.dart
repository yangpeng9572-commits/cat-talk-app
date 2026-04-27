import '../models/translation_result.dart';
import 'translation_history_service.dart';

/// 個別貓咪學習服務
/// 
/// 學習每隻貓的叫聲模式，提高翻譯準確度
/// 
/// 現況：第一版使用簡單規則
/// 未來：可擴充為 Firebase + AI 模型
class CatLearningService {
  // 單例模式
  static final CatLearningService _instance = CatLearningService._internal();
  factory CatLearningService() => _instance;
  CatLearningService._internal();

  final TranslationHistoryService _historyService = TranslationHistoryService();

  /// 學習因子權重（用於調整翻譯）
  /// 每次使用者修正，該情緒的權重 +0.1
  static const double _correctionBoost = 0.1;
  
  /// 最大權重上限
  static const double _maxBoost = 0.5;

  /// 情緒權重表（依據貓咪 ID）
  /// Map<catId, Map<emotionType, boostValue>>
  final Map<String, Map<String, double>> _catEmotionBoosts = {};

  // ═══════════════════════════════════════════════════════════════
  // 公開 API
  // ═══════════════════════════════════════════════════════════════

  /// 記錄使用者的修正（學習）
  /// 
  /// 當使用者修正翻譯結果時呼叫
  void learnFromCorrection(String catId, EmotionType correctedEmotion) {
    if (!_catEmotionBoosts.containsKey(catId)) {
      _catEmotionBoosts[catId] = {};
    }

    final currentBoost = _catEmotionBoosts[catId]![correctedEmotion.name] ?? 0.0;
    final newBoost = (currentBoost + _correctionBoost).clamp(0.0, _maxBoost);
    _catEmotionBoosts[catId]![correctedEmotion.name] = newBoost;
  }

  /// 記錄使用者確認正確（正向學習）
  void learnFromConfirmation(String catId, EmotionType emotion) {
    // 確認也是一種學習，但權重較低
    if (!_catEmotionBoosts.containsKey(catId)) {
      _catEmotionBoosts[catId] = {};
    }

    final currentBoost = _catEmotionBoosts[catId]![emotion.name] ?? 0.0;
    final newBoost = (currentBoost + _correctionBoost * 0.5).clamp(0.0, _maxBoost);
    _catEmotionBoosts[catId]![emotion.name] = newBoost;
  }

  /// 根據貓咪歷史取得情緒權重調整
  /// 
  /// 回傳 Map<EmotionType, boost>
  /// 調用者可以用這些 boost 調整翻譯信心值
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

  /// 根據貓咪歷史調整翻譯結果
  /// 
  /// 這個方法會：
  /// 1. 查詢該貓咪過去的修正紀錄
  /// 2. 找出最常被修正成某種情緒
  /// 3. 在翻譯結果出來後，調整該情緒的 confidence
  /// 
  /// 情境：
  /// - 使用者常把某種叫聲修正成 hungry → 這種模式的 hungry confidence 提高
  /// - 使用者常把某種叫聲修正成 affectionate → 这种模式的 affectionate 提高
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
  void clearLearningForCat(String catId) {
    _catEmotionBoosts.remove(catId);
  }

  /// 清除所有學習資料
  void clearAll() {
    _catEmotionBoosts.clear();
  }

  // ═══════════════════════════════════════════════════════════════
  // 未來擴充接口（Firebase / AI 模型）
  // ═══════════════════════════════════════════════════════════════

  /// TODO: Firebase 同步
  /// 
  /// 未來可以將學習資料同步到 Firebase Firestore
  /// 这样换手机也不会丢失学习记录
  Future<void> syncToCloud() async {
    // 預留接口
    // await FirebaseFirestore.instance.collection('cat_learning').doc(catId).set({
    //   'emotionBoosts': _catEmotionBoosts[catId],
    //   'lastUpdated': DateTime.now(),
    // });
    throw UnimplementedError('Firebase 同步尚未整合');
  }

  /// TODO: 從雲端恢復學習資料
  Future<void> restoreFromCloud(String catId) async {
    throw UnimplementedError('Firebase 恢復尚未整合');
  }

  /// TODO: AI 模型訓練介面
  /// 
  /// 未來可以收集音訊特徵，訓練 TensorFlow Lite 模型
  /// 每隻貓有自己的叫聲模型
  Future<void> trainCatModel(String catId) async {
    throw UnimplementedError('AI 模型訓練尚未整合');
  }

  /// TODO: 使用 AI 模型預測
  Future<EmotionType> predictWithAI(
    String catId,
    AudioFeatures features,
  ) async {
    // 預留接口：未來使用 Cat-specific 模型
    // 1. 載入該貓咪的 .tflite 模型
    // 2. 輸入 features
    // 3. 輸出預測情緒
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