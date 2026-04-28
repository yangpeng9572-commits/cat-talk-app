import 'dart:math';
import '../models/translation_result.dart';
import '../models/daily_cat_report.dart';

/// 情感化文案服務
/// 負責生成首頁的 headline、副句等溫暖文案
class EmotionalHeadlineService {
  static final EmotionalHeadlineService _instance = EmotionalHeadlineService._internal();
  factory EmotionalHeadlineService() => _instance;
  EmotionalHeadlineService._internal();
  
  final Random _random = Random();

  // =====  headline 規則 =====
  
  /// 取得 headline 文字（根據 dominantEmotion）
  String getHeadline(String catName, EmotionType? emotion) {
    final lines = _headlineMap[emotion] ?? _emptyHeadlines;
    return lines[_random.nextInt(lines.length)].replaceAll('{catName}', catName);
  }
  
  /// 取得副句文字
  String getSubtitle(String catName, EmotionType? emotion) {
    final lines = _subtitleMap[emotion] ?? _emptySubtitles;
    return lines[_random.nextInt(lines.length)].replaceAll('{catName}', catName);
  }
  
  /// 取得情緒標籤文字
  String getEmotionTag(EmotionType? emotion) {
    return _emotionTagMap[emotion] ?? '還在觀察';
  }
  
  /// 取得情緒 emoji
  String getEmotionEmoji(EmotionType? emotion) {
    return _emotionEmojiMap[emotion] ?? '🐱';
  }

  // ===== headline 資料庫 =====
  
  static final Map<EmotionType?, List<String>> _headlineMap = {
    EmotionType.affectionate: [
      '{catName} 今天好像很想你 🐾',
      '{catName} 今天特別黏你 💕',
      '{catName} 想靠近你一下',
    ],
    EmotionType.hungry: [
      '{catName} 好像在提醒你吃飯時間到了 🍽',
      '{catName} 今天有點小餓餓',
      '{catName} 可能在等你看看飯碗',
    ],
    EmotionType.playful: [
      '{catName} 今天很想找你玩 🎾',
      '{catName} 精神很好，想動一動',
      '{catName} 今天像小淘氣一樣有活力',
    ],
    EmotionType.attention: [
      '{catName} 好像在等你回應 🐱',
      '{catName} 今天想被你注意',
      '{catName} 有話想跟你說',
    ],
    EmotionType.anxious: [
      '{catName} 今天好像有點不安',
      '{catName} 可能需要你多陪一下',
      '{catName} 想確認你在不在身邊',
    ],
    EmotionType.angry: [
      '{catName} 今天脾氣有點大 😾',
      '{catName} 可能需要自己的空間',
      '{catName} 在生悶氣中...',
    ],
    EmotionType.uncomfortable: [
      '{catName} 今天狀態有點需要觀察',
      '{catName} 可能想讓你注意一下',
      '{catName} 今天需要你多留意',
    ],
    EmotionType.greeting: [
      '{catName} 今天跟你打招呼了 🐾',
      '{catName} 看起來狀態穩穩的',
      '{catName} 今天也有可愛地回應你',
    ],
  };
  
  static const List<String> _emptyHeadlines = [
    '{catName} 今天還沒跟你說話',
    '試著聽聽{catName}今天想表達什麼',
    '今天也來記錄一聲喵吧 🐾',
  ];

  // ===== 副句資料庫 =====
  
  static final Map<EmotionType?, List<String>> _subtitleMap = {
    EmotionType.affectionate: [
      '她今天比較想親近你，適合多摸摸或陪她待一下。',
      '💕 她想撒嬌，多給她一些溫暖吧',
      '今天她特別需要你的陪伴',
    ],
    EmotionType.hungry: [
      '她可能在提醒你看看食物、水或平常的餵食時間。',
      '🍽 小肚子餓了？檢查一下飯碗和水碗吧',
      '她的飢餓訊號出現了',
    ],
    EmotionType.playful: [
      '她今天精神不錯，可以用逗貓棒陪她玩幾分鐘。',
      '🎾 活力滿滿！陪她動一動吧',
      '今天的小宇宙充滿能量',
    ],
    EmotionType.attention: [
      '她可能只是想確認你有沒有注意到她。',
      '👀 她在等你回應喔',
      '她希望被你看見',
    ],
    EmotionType.anxious: [
      '她今天可能有點敏感，適合給她安靜安全的空間。',
      '😿 她今天比較敏感，溫柔對待一下',
      '給她一些安撫和安全感',
    ],
    EmotionType.angry: [
      '她今天脾氣有點大，先給她一些空間吧。',
      '😾 她可能需要冷靜一下',
      '別勉強她，先觀察一下',
    ],
    EmotionType.uncomfortable: [
      '今天有些訊號需要觀察，若持續異常，建議諮詢獸醫。',
      '🤒 需要多留意她的狀態',
      '她的身體可能在說不舒服',
    ],
    EmotionType.greeting: [
      '她看起來狀態穩定，也有跟你互動的小訊號。',
      '🐾 她在跟你打招呼喔',
      '今天也是穩穩的一天',
    ],
  };
  
  static const List<String> _emptySubtitles = [
    '長按錄音，記錄今天第一聲喵。',
    '🐾 今天還沒聽到她的聲音',
    '試著按下錄音，聽聽她想說什麼',
  ];

  // ===== 情緒標籤 =====
  
  static final Map<EmotionType?, String> _emotionTagMap = {
    EmotionType.affectionate: '想撒嬌',
    EmotionType.hungry: '肚子餓',
    EmotionType.playful: '想玩',
    EmotionType.attention: '想被注意',
    EmotionType.anxious: '有點不安',
    EmotionType.angry: '生氣中',
    EmotionType.uncomfortable: '不舒服',
    EmotionType.greeting: '打招呼',
    EmotionType.other: '其他',
  };

  // ===== 情緒 Emoji =====
  
  static final Map<EmotionType?, String> _emotionEmojiMap = {
    EmotionType.affectionate: '💕',
    EmotionType.hungry: '🍽',
    EmotionType.playful: '🎾',
    EmotionType.attention: '👀',
    EmotionType.anxious: '😿',
    EmotionType.angry: '😾',
    EmotionType.uncomfortable: '🤒',
    EmotionType.greeting: '🐾',
    EmotionType.other: '🐱',
  };
}

/// 翻譯反饋提示訊息
class FeedbackMessageService {
  static final FeedbackMessageService _instance = FeedbackMessageService._internal();
  factory FeedbackMessageService() => _instance;
  FeedbackMessageService._internal();
  
  final Random _random = Random();
  
  // 完成翻譯後的提示
  static const List<String> _translationCompleted = [
    '我記住這次小情緒了 🐾',
    '了解她多一點了 💕',
    '這次的小心情已記錄 🐱',
    '有心的互動 +1 ✨',
  ];
  
  // 查看每日報告後的提示
  static const List<String> _reportViewed = [
    '今天更了解她一點了 💕',
    '越來越懂她了 🐾',
    '今天的默契值提升了 ✨',
    '記錄著你們的日常 💕',
  ];
  
  String getTranslationCompletedMessage() {
    return _translationCompleted[_random.nextInt(_translationCompleted.length)];
  }
  
  String getReportViewedMessage() {
    return _reportViewed[_random.nextInt(_reportViewed.length)];
  }
}
