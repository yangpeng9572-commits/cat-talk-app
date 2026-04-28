import 'dart:math';
import '../models/translation_result.dart';

/// 擬人化貓咪語氣服務
/// 將情緒翻譯成「貓咪想說的話」
class CatSpeechService {
  static final CatSpeechService _instance = CatSpeechService._internal();
  factory CatSpeechService() => _instance;
  CatSpeechService._internal();
  
  final Random _random = Random();

  // ===== 擬人化文案資料庫 =====
  
  static final Map<EmotionType, List<String>> _speechMap = {
    EmotionType.affectionate: [
      '抱抱我嘛～我想黏著你 💕',
      '你可以摸摸我嗎？我今天想靠近你',
      '我想待在你旁邊一下 🐾',
      '我今天好喜歡你在身邊',
      '不要走嘛，我想陪你',
    ],
    EmotionType.hungry: [
      '我有點餓餓了…你是不是忘記我了 🥺',
      '飯碗好像在呼喚我了 🍽',
      '可以看看我的飯飯嗎？',
      '我不是貪吃，我只是提醒你一下',
      '主人～我想吃一點點',
    ],
    EmotionType.playful: [
      '陪我玩一下嘛！我現在超有精神 🎾',
      '我想追東西！快拿逗貓棒',
      '今天想跑跑跳跳一下',
      '來玩嘛～我準備好了',
      '我現在是小淘氣模式',
    ],
    EmotionType.attention: [
      '你有看到我嗎？我在這裡 🐱',
      '我想讓你注意我一下',
      '可以看我一下嗎？',
      '我剛剛是在叫你喔',
      '我有話想跟你說',
    ],
    EmotionType.anxious: [
      '你在旁邊嗎？我有點不安',
      '這裡好像怪怪的，我想確認你在',
      '我需要一點安全感',
      '你可以陪我一下嗎？',
      '我有點緊張，想靠近熟悉的人',
    ],
    EmotionType.angry: [
      '我现在不太想被打擾',
      '先給我一點空間好嗎',
      '我有點不開心了',
      '我想自己冷靜一下',
      '不要靠太近，我現在需要距離',
    ],
    EmotionType.uncomfortable: [
      '我好像有點不舒服，想讓你注意一下',
      '今天感覺怪怪的，你可以觀察我嗎？',
      '我想安靜一下，也想被你留意',
      '這次叫聲有點不一樣',
      '如果我一直這樣，記得多看看我',
    ],
    EmotionType.greeting: [
      '嗨～你來啦 🐾',
      '我只是想跟你打聲招呼',
      '今天也有看到你喔',
      '喵～我在這裡',
      '我只是想讓你知道我在',
    ],
    EmotionType.other: [
      '喵～你有聽到嗎？',
      '我想跟你說件事 🐱',
      '今天有點特別的感覺',
      '你在看我嗎？',
      '我只是在跟你打招呼',
    ],
  };

  // ===== 情緒強度詞綴 =====
  
  /// 根據 confidence 取得情緒強度詞
  String getIntensityPrefix(double confidence) {
    if (confidence < 0.5) {
      return _intensityLow[_random.nextInt(_intensityLow.length)];
    } else if (confidence < 0.8) {
      return _intensityMedium[_random.nextInt(_intensityMedium.length)];
    } else {
      return _intensityHigh[_random.nextInt(_intensityHigh.length)];
    }
  }
  
  /// 取得情緒強度 + 情緒名稱
  String getEmotionIntensity(EmotionType emotion, double confidence) {
    final prefix = getIntensityPrefix(confidence);
    return '$prefix${_emotionLabelMap[emotion]}';
  }
  
  static const List<String> _intensityLow = [
    '可能有點',
    '好像有點',
    '這次不太確定，但可能是',
    '似乎有點',
    '隱約覺得',
  ];
  
  static const List<String> _intensityMedium = [
    '有點',
    '蠻想',
    '看起來想',
    '似乎有點',
    '有那麼一點',
  ];
  
  static const List<String> _intensityHigh = [
    '很想',
    '超想',
    '明顯想',
    '強烈想',
    '真的很想',
  ];

  // ===== 情緒標籤 =====
  
  static final Map<EmotionType, String> _emotionLabelMap = {
    EmotionType.affectionate: '撒嬌',
    EmotionType.hungry: '餓',
    EmotionType.playful: '玩',
    EmotionType.attention: '被注意',
    EmotionType.anxious: '不安',
    EmotionType.angry: '生氣',
    EmotionType.uncomfortable: '不舒服',
    EmotionType.greeting: '打招呼',
    EmotionType.other: '想說話',
  };

  // ===== 推測原因文案 =====
  
  String getReason(EmotionType emotion, double confidence) {
    final reasons = _reasonMap[emotion] ?? ['這次的叫聲有點特別'];
    return reasons[_random.nextInt(reasons.length)];
  }
  
  static final Map<EmotionType, List<String>> _reasonMap = {
    EmotionType.affectionate: [
      '她的叫聲比較柔和，聽起來像在撒嬌',
      '這次的聲音頻率偏低，帶有依賴感',
      '她一直看著你，可能想引起注意',
      '這個叫聲通常是她在尋求陪伴',
    ],
    EmotionType.hungry: [
      '叫聲比較急促，節奏穩定',
      '她一直看向飯碗或廚房方向',
      '這個時間點她通常會餓了',
      '聲音中帶有期待感',
    ],
    EmotionType.playful: [
      '聲音輕快，節奏變化多',
      '她看起來精力充沛，動作頻繁',
      '這個叫聲通常是想玩的訊號',
      '她可能看到獵物或玩具了',
    ],
    EmotionType.attention: [
      '她對你有回應，聽起來像在叫名字',
      '這個叫聲通常是想確認你在',
      '她一直在你附近走動',
      '叫聲有起伏，像是在對話',
    ],
    EmotionType.anxious: [
      '叫聲比較尖銳，節奏不穩定',
      '她可能聽到了陌生的聲音',
      '這個叫聲通常表示她感到緊張',
      '她可能在尋求安全感',
    ],
    EmotionType.angry: [
      '叫聲低沉帶有威脅性',
      '她可能在保護地盤或資源',
      '耳朵可能向後壓平',
      '這個叫聲通常是要保持距離',
    ],
    EmotionType.uncomfortable: [
      '叫聲比平常低或高',
      '她可能在身體某處感到不適',
      '這個叫聲和平常有明顯不同',
      '建議多觀察她的精神狀態',
    ],
    EmotionType.greeting: [
      '這是短而友好的叫聲',
      '她看到你了，這是打招呼的方式',
      '通常這是她在表達友好',
      '她在歡迎你回家',
    ],
  };

  // ===== 建議行動 =====
  
  List<String> getSuggestedActions(EmotionType emotion) {
    return _actionMap[emotion] ?? ['陪她說說話'];
  }
  
  static final Map<EmotionType, List<String>> _actionMap = {
    EmotionType.affectionate: [
      '摸摸她',
      '陪她待一下',
      '輕聲叫她名字',
    ],
    EmotionType.hungry: [
      '看看飯碗',
      '檢查水碗',
      '確認餵食時間',
    ],
    EmotionType.playful: [
      '拿逗貓棒',
      '陪玩 5 分鐘',
      '給她追小球',
    ],
    EmotionType.attention: [
      '看看她',
      '回應她一下',
      '陪她說說話',
    ],
    EmotionType.anxious: [
      '陪她一下',
      '降低環境噪音',
      '給她安全空間',
    ],
    EmotionType.angry: [
      '給她空間',
      '暫時不要抱',
      '觀察情緒',
    ],
    EmotionType.uncomfortable: [
      '觀察精神',
      '檢查食慾',
      '必要時問獸醫',
    ],
    EmotionType.greeting: [
      '跟她打招呼',
      '摸摸頭',
      '叫她名字',
    ],
  };

  // ===== 回饋提示 =====
  
  String getCorrectFeedback() {
    return '我記住了，下次會更懂她 💕';
  }
  
  String getIncorrectFeedback() {
    return '謝謝你告訴我，我會慢慢學會她的習慣 🐾';
  }
  
  String getActionCompletedFeedback() {
    return '她感受到你的回應了 🐾';
  }
  
  // ===== confidence 提示 =====
  
  String getHighConfidenceHint() {
    return '這次聽起來很像她平常的表達方式';
  }
  
  String getLowConfidenceHint() {
    return '這次我還不太確定，可以幫我修正嗎？';
  }

  // ===== 主翻譯方法 =====
  
  /// 取得擬人化翻譯
  String getSpeech(EmotionType emotion) {
    final speeches = _speechMap[emotion] ?? _speechMap[EmotionType.other]!;
    return speeches[_random.nextInt(speeches.length)];
  }
  
  /// 組合完整翻譯結果
  CatSpeechResult generateSpeechResult(TranslationResult result) {
    return CatSpeechResult(
      speech: getSpeech(result.emotionType),
      emotionIntensity: getEmotionIntensity(result.emotionType, result.confidence),
      reason: getReason(result.emotionType, result.confidence),
      suggestedActions: getSuggestedActions(result.emotionType),
      isHighConfidence: result.confidence >= 0.8,
      isLowConfidence: result.confidence < 0.5,
      needsVetReminder: result.emotionType == EmotionType.uncomfortable,
    );
  }
}

/// 翻譯結果資料類別
class CatSpeechResult {
  final String speech;           // 擬人化翻譯
  final String emotionIntensity; // 情緒強度
  final String reason;          // 推測原因
  final List<String> suggestedActions; // 建議行動
  final bool isHighConfidence;  // 高信心度
  final bool isLowConfidence;   // 低信心度
  final bool needsVetReminder; // 需要獸醫提醒
  
  CatSpeechResult({
    required this.speech,
    required this.emotionIntensity,
    required this.reason,
    required this.suggestedActions,
    required this.isHighConfidence,
    required this.isLowConfidence,
    required this.needsVetReminder,
  });
}
