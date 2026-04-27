import '../models/translation_result.dart';
import '../models/cat.dart';

/// 翻譯歷史資料服務
/// 目前用於存放翻譯記錄
/// 未來會改為 SQLite 或 Firebase 持久化
class TranslationHistoryService {
  // 單例模式
  static final TranslationHistoryService _instance = TranslationHistoryService._internal();
  factory TranslationHistoryService() => _instance;
  TranslationHistoryService._internal();

  // 記憶體中的翻譯歷史
  final List<TranslationResult> _history = [];

  /// 取得所有歷史記錄（由新到舊）
  List<TranslationResult> getAll() {
    return List.from(_history.reversed);
  }

  /// 依照貓咪 ID 取得歷史記錄
  List<TranslationResult> getByCatId(String catId) {
    return _history.where((r) => r.catId == catId).toList().reversed.toList();
  }

  /// 新增翻譯記錄
  void add(TranslationResult result) {
    _history.add(result);
  }

  /// 更新翻譯記錄（帶入回饋）
  void updateWithFeedback(TranslationResult result, UserFeedback feedback) {
    final index = _history.indexWhere((r) => r.id == result.id);
    if (index != -1) {
      _history[index] = result.copyWith(userFeedback: feedback);
    }
  }

  /// 刪除單筆記錄
  void delete(String id) {
    _history.removeWhere((r) => r.id == id);
  }

  /// 清除所有記錄
  void clearAll() {
    _history.clear();
  }

  /// 取得總記錄數
  int get count => _history.length;

  /// 測試用：新增一筆模擬資料
  void addMockData() {
    final now = DateTime.now();
    final emotions = EmotionType.values.where((e) => e != EmotionType.other).toList();
    final cats = Cat.getDemoCats();

    for (int i = 0; i < 10; i++) {
      final emotion = emotions[i % emotions.length];
      final cat = cats[i % cats.length];

      _history.add(TranslationResult(
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
      ));
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