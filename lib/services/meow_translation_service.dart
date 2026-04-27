import '../models/translation_result.dart';

/// 貓叫聲翻譯服務
/// 
/// 第一版：Rule-based 規則翻譯
/// 未來：接 TensorFlow Lite AI 模型
/// 
/// 使用方式：
/// ```dart
/// final service = MeowTranslationService();
/// final result = await service.analyzeAudio(audioPath);
/// ```
class MeowTranslationService {
  // ═══════════════════════════════════════════════════════════════
  // 公開 API
  // ═══════════════════════════════════════════════════════════════

  /// 分析音訊檔案並翻譯
  /// 
  /// [audioPath] 音訊檔案路徑
  /// [catId] 貓咪 ID（用於個人化翻譯）
  /// 回傳翻譯結果
  Future<TranslationResult> analyzeAudio(String audioPath, {String? catId}) async {
    // TODO: 未來接 TensorFlow Lite
    // 先用 Rule-based 模擬分析
    final audioFeatures = await _extractAudioFeatures(audioPath);
    return translateMeowWithCat(audioFeatures, catId ?? 'demo');
  }

  /// 直接翻譯已分析好的音訊特徵（可指定貓咪）
  TranslationResult translateMeow(AudioFeatures features, {String? catId}) {
    return translateMeowWithCat(features, catId ?? 'demo');
  }

  TranslationResult translateMeowWithCat(AudioFeatures features, String catId) {
    final emotion = _classifyEmotion(features);
    final humanText = generateHumanText(emotion, features);
    final confidence = calculateConfidence(features);
    final reason = _generateUserFriendlyReason(emotion, features);
    final suggestedAction = _getSuggestedAction(emotion);

    return TranslationResult(
      id: _generateId(),
      catId: catId,
      emotionType: emotion,
      humanText: humanText,
      confidence: confidence,
      reason: reason,
      suggestedAction: suggestedAction,
      audioFeatures: features,
      createdAt: DateTime.now(),
    );
  }

  /// 根據情緒類型生成人類可理解的文字（更自然的表達）
  String generateHumanText(EmotionType emotion, AudioFeatures features) {
    switch (emotion) {
      case EmotionType.hungry:
        return _generateHungryText(features);
      case EmotionType.affectionate:
        return _generateAffectionateText(features);
      case EmotionType.playful:
        return _generatePlayfulText(features);
      case EmotionType.attention:
        return _generateAttentionText(features);
      case EmotionType.anxious:
        return _generateAnxiousText(features);
      case EmotionType.angry:
        return _generateAngryText(features);
      case EmotionType.uncomfortable:
        return _generateUncomfortableText(features);
      case EmotionType.greeting:
        return _generateGreetingText(features);
      case EmotionType.other:
        return '喵～';
    }
  }

  /// 計算翻譯的置信度（0.0 - 1.0）
  double calculateConfidence(AudioFeatures features) {
    double confidence = 0.5;

    // 根據音量調整（太大或太小都降低置信度）
    if (features.volume >= 0.3 && features.volume <= 0.8) {
      confidence += 0.15;
    }

    // 根據音高調整
    if (features.pitch >= 350 && features.pitch <= 550) {
      confidence += 0.15;
    }

    // 根據時長調整（太短或太長都降低置信度）
    if (features.duration >= 500 && features.duration <= 3000) {
      confidence += 0.1;
    }

    // 根據喵聲次數調整
    if (features.meowCount >= 1 && features.meowCount <= 5) {
      confidence += 0.1;
    }

    return confidence.clamp(0.0, 1.0);
  }

  // ═══════════════════════════════════════════════════════════════
  // 私有方法（Rule-based 規則引擎）
  // ═══════════════════════════════════════════════════════════════

  /// 產生唯一 ID
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// 擷取音訊特徵（Mock 實現）
  /// 
  /// TODO: 未來替換成 TensorFlow Lite / ML Kit 分析
  Future<AudioFeatures> _extractAudioFeatures(String audioPath) async {
    // 模擬音訊分析
    // 真實實現會使用：
    // - flutter_sound 或 record 套件錄製
    // - TensorFlow Lite 模型分析音頻
    // - MFCC 特徵提取
    await Future.delayed(const Duration(milliseconds: 100));

    // 根據路徑生成一些變化的 mock 數據
    final hash = audioPath.hashCode;
    return AudioFeatures(
      duration: 1000.0 + (hash % 2000).toDouble(),
      volume: 0.5 + (hash % 30) / 100,
      pitch: 400.0 + (hash % 200).toDouble(),
      meowCount: 1 + (hash % 4),
      isRapid: hash % 3 == 0,
      isLongMeow: hash % 5 == 0,
      recordedAt: DateTime.now(),
    );
  }

  /// 情緒分類（Rule-based）
  EmotionType _classifyEmotion(AudioFeatures features) {
    // 規則優先順序：非常明確的模式先判斷

    // 🚨 生氣：高音量 + 高音 + 快速
    if (features.volume > 0.7 && features.pitch > 500 && features.isRapid) {
      return EmotionType.angry;
    }

    // 😿 焦慮：快速連續 + 高音
    if (features.isRapid && features.pitch > 450) {
      return EmotionType.anxious;
    }

    // 🍽️ 餓了：低沈 + 重複叫聲
    if (features.pitch < 400 && features.meowCount >= 2) {
      return EmotionType.hungry;
    }

    // 💕 撒嬌：長音 + 中等音量
    if (features.isLongMeow && features.volume >= 0.4 && features.volume <= 0.7) {
      return EmotionType.affectionate;
    }

    // 🎾 玩耍：高音 + 非快速
    if (features.pitch > 450 && !features.isRapid && features.meowCount <= 2) {
      return EmotionType.playful;
    }

    // 👋 問候：中等音量 + 單次叫聲
    if (!features.isRapid && features.meowCount == 1 && features.volume >= 0.4 && features.volume <= 0.7) {
      return EmotionType.greeting;
    }

    // 👀 需要關注：中等音量 + 多次叫聲
    if (features.meowCount >= 2 && features.meowCount <= 3 && features.volume >= 0.4) {
      return EmotionType.attention;
    }

    // 🤒 不舒服：低音 + 緩慢
    if (features.pitch < 350 && !features.isRapid) {
      return EmotionType.uncomfortable;
    }

    return EmotionType.other;
  }

  /// 生成「使用者看得懂」的原因說明
  String _generateUserFriendlyReason(EmotionType emotion, AudioFeatures features) {
    // 根據音高和音量描述來解釋判斷原因
    // 音高：${features.pitchCategory.label}，音量：${features.volumeCategory.label}

    switch (emotion) {
      case EmotionType.hungry:
        return '聽起來像低沈的叫聲，重複了好幾次，可能是肚子餓了在催飯。';
      case EmotionType.affectionate:
        return '這個叫聲比較長、聽起來很溫柔，像是想討摸摸或撒撒嬌。';
      case EmotionType.playful:
        return '叫聲偏高、節奏輕快，通常是想要玩耍或狩猎的訊號。';
      case EmotionType.attention:
        return '連續叫了好幾聲，音量穩定，可能是想要引起你的注意。';
      case EmotionType.anxious:
        return '叫聲急促且持續，通常出現在環境改變或感到不安的時候。';
      case EmotionType.angry:
        return '叫聲又大又尖銳，節奏很快，應該是不高興了，要注意！';
      case EmotionType.uncomfortable:
        return '叫聲偏低、節奏慢，可能表示身體有點不舒服或想安靜休息。';
      case EmotionType.greeting:
        return '只有一聲，音量適中，這是貓咪在跟你打招呼喔！';
      case EmotionType.other:
        return '這次的叫聲特徵不太明顯，參考過去資料後推測可能是這個意思。';
    }
  }

  /// 取得建議動作（更自然的描述）
  String _getSuggestedAction(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.hungry:
        return '去看看貓碗是不是空了，或者給他一點小點心吧！';
      case EmotionType.affectionate:
        return '停下手中的事，花幾分鐘摸摸他或陪他玩一下。';
      case EmotionType.playful:
        return '拿出逗貓棒或小玩具，和他互動一下吧！';
      case EmotionType.attention:
        return '抬頭看看他，也許他只是想確認你還在。';
      case EmotionType.anxious:
        return '檢查一下環境中是否有讓他緊張的東西，提供一些安撫。';
      case EmotionType.angry:
        return '給他一點空間，不要強迫互動，等他自己冷靜下來。';
      case EmotionType.uncomfortable:
        return '觀察一下有沒有其他異常症狀，若持續就帶去看獸醫。';
      case EmotionType.greeting:
        return '跟他打个招呼吧，他會很開心的！';
      case EmotionType.other:
        return '持續觀察他的行為，慢慢了解他的習慣。';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // Text Generation Helpers
  // ═══════════════════════════════════════════════════════════════

  String _generateHungryText(AudioFeatures features) {
    final messages = [
      '我餓了！快給我吃的！🍽️',
      '肚子好餓喔...有的吃嗎？',
      '該吃飯了吧！我在等！',
      '碗空了啦，什麼時候餵我？',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateAffectionateText(AudioFeatures features) {
    final messages = [
      '抱抱我嘛～我想要撒嬌 💕',
      '陪陪我好不好？',
      '好想被你摸摸...',
      '來這裡，我需要你 ❤️',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generatePlayfulText(AudioFeatures features) {
    final messages = [
      '陪我玩嘛！我好無聊！ 🎾',
      '我想狩獵！有玩具嗎？',
      '來追我啊～',
      '那個小蟲子好好玩！',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateAttentionText(AudioFeatures features) {
    final messages = [
      '你在哪裡？我需要你！ 👀',
      '為什麼不理我？',
      '我需要一些關注...',
      '抬頭看看我嘛～',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateAnxiousText(AudioFeatures features) {
    final messages = [
      '我覺得不太對勁... 😿',
      '有點害怕...',
      '怎麼了？讓我緊張...',
      '環境改變了嗎？',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateAngryText(AudioFeatures features) {
    final messages = [
      '哼！我生氣了！ 😾',
      '不要碰我！',
      '離我遠一點！',
      '我警告你喔！',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateUncomfortableText(AudioFeatures features) {
    final messages = [
      '我不舒服... 🤒',
      '感覺不太對...',
      '需要休息一下...',
      '讓我靜一靜...',
    ];
    return messages[features.hashCode % messages.length];
  }

  String _generateGreetingText(AudioFeatures features) {
    final messages = [
      '嗨！你在這裡！ 👋',
      '你好啊～',
      '嘿！我在這裡！',
      '回來啦？我想你了！',
    ];
    return messages[features.hashCode % messages.length];
  }

  // ═══════════════════════════════════════════════════════════════
  // 未來 AI 接口預留
  // ═══════════════════════════════════════════════════════════════

  /// TODO: TensorFlow Lite 模型路徑
  /// ，未來替換 _extractAudioFeatures 的實現
  static const String kModelPath = 'assets/models/meow_classifier.tflite';

  /// TODO: ML Kit 音頻分析
  /// 未來可用於更精確的音頻特徵提取
  Future<AudioFeatures> analyzeWithML(String audioPath) async {
    // 預留接口：未來接入 TensorFlow Lite
    // 1. 載入 .tflite 模型
    // 2. 輸入音頻資料
    // 3. 輸出分類結果
    throw UnimplementedError('TensorFlow Lite 模型尚未整合');
  }
}