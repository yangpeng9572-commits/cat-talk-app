import 'dart:math';
import '../models/translation_result.dart';
import '../models/bond.dart';

/// 貓咪日記服務
/// 將每日報告轉化為可愛、溫柔的日記風格文字
class CatDiaryService {
  static final CatDiaryService _instance = CatDiaryService._internal();
  factory CatDiaryService() => _instance;
  CatDiaryService._internal();
  
  final Random _random = Random();

  // ===== 情緒日記映射 =====
  
  /// 撒嬌情緒日記
  String _getAffectionateDiary(int count, int bondScore) {
    final lines = <String>[
      '她今天好像特別想黏著你。',
      '也許只是想確認你在不在身邊。',
      if (count >= 3) '出現了 $count 次撒嬌訊號，' '感覺她很享受跟你在一起的時光。',
      '今天很適合多摸摸她，讓她安心一點。',
      if (bondScore >= 60) '你們的默契已經越來越明顯了 💕',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 肚子餓情緒日記
  String _getHungryDiary(int count, int bondScore) {
    final lines = [
      '她今天出現${count >= 2 ? "幾次" : "1次"}像是在提醒吃飯的小訊號。',
      '可以留意飯碗、水碗，或平常餵食時間。',
      '她可能只是想讓你知道：我有點餓餓。',
      if (bondScore >= 60) '你們的默契已經越來越明顯了 💕',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 想要玩情緒日記
  String _getPlayfulDiary(int count, int bondScore) {
    final lines = [
      '她今天精神看起來不錯。',
      if (count >= 2) '出現了 $count 次想玩的訊號，' '像是想找你玩、追東西，或活動一下。',
      if (count < 2) '出現了想玩的訊號，像是想要你陪她動一動。',
      '很適合拿逗貓棒陪她玩幾分鐘。',
      if (bondScore >= 80) '她好像越來越習慣用自己的方式找你。',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 想被注意情緒日記
  String _getAttentionDiary(int count, int bondScore) {
    final lines = [
      '她今天好像有${count >= 2 ? "幾次" : "1次"}想吸引你的注意。',
      '可能只是希望你看她一眼、叫她名字，或回應她一下。',
      '對她來說，你的回應可能就是最好的陪伴。',
      if (bondScore < 25) '慢慢記錄，她的習慣會越來越清楚。',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 焦慮情緒日記
  String _getAnxiousDiary(int count, int bondScore) {
    final lines = [
      '她今天有些訊號像是比較敏感或不安。',
      '可以觀察環境是否有噪音、陌生人或變動。',
      '給她一個安靜熟悉的位置，可能會讓她更放鬆。',
      if (bondScore >= 60) '你們的默契已經越來越明顯了 💕',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 生氣情緒日記
  String _getAngryDiary(int count, int bondScore) {
    final lines = [
      '她今天有${count >= 2 ? "幾次" : "1次"}像是不太想被打擾。',
      '這時候可以先給她一點空間。',
      '等她願意靠近時，再溫柔地回應她。',
      if (bondScore >= 80) '她好像越來越習慣用自己的方式找你。',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 不舒服情緒日記
  String _getUncomfortableDiary(int count, int bondScore) {
    final lines = [
      '今天有些訊號需要多留意。',
      '可以觀察她的精神、食慾、喝水與排便狀況。',
      '這只是聲音與行為推測，若持續異常，建議諮詢獸醫。 🐾',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 打招呼情緒日記
  String _getGreetingDiary(int count, int bondScore) {
    final lines = [
      '她今天有${count >= 2 ? "幾次" : "1次"}像是在跟你打招呼。',
      '整體看起來狀態穩穩的。',
      '偶爾回應她一下，也是在累積你們的小默契。 💕',
      if (bondScore >= 60) '你們的默契已經越來越明顯了 💕',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 無記錄日記
  String _getNoRecordDiary(int bondScore) {
    final lines = [
      '今天還沒有記錄到她的小聲音。',
      '可以找個她比較放鬆的時候，聽聽她想表達什麼。',
      '第一聲喵，也可以成為今天的小日記。',
      if (bondScore < 25) '慢慢記錄，她的習慣會越來越清楚。',
    ];
    return _formatDiary(lines, bondScore);
  }

  /// 格式化日記（加入換行）
  String _formatDiary(List<String> lines, int bondScore) {
    // 過濾掉 null 並確保有內容
    final validLines = lines.where((l) => l.isNotEmpty).toList();
    
    // 如果沒有有效行，給預設訊息
    if (validLines.isEmpty) {
      return '今天是很特別的一天 🐱\n希望明天也能聽到她的聲音。';
    }
    
    return validLines.join('\n');
  }

  /// 取得日記標題
  String getDiaryTitle(String catName) {
    return '$catName 今天的小日記 🐱';
  }

  /// 根據情緒取得日記內容
  String getDiaryText({
    required EmotionType? emotion,
    required int emotionCount,
    required int bondScore,
  }) {
    // 如果沒有情緒，回傳無記錄日記
    if (emotion == null) {
      return _getNoRecordDiary(bondScore);
    }

    switch (emotion) {
      case EmotionType.affectionate:
        return _getAffectionateDiary(emotionCount, bondScore);
      case EmotionType.hungry:
        return _getHungryDiary(emotionCount, bondScore);
      case EmotionType.playful:
        return _getPlayfulDiary(emotionCount, bondScore);
      case EmotionType.attention:
        return _getAttentionDiary(emotionCount, bondScore);
      case EmotionType.anxious:
        return _getAnxiousDiary(emotionCount, bondScore);
      case EmotionType.angry:
        return _getAngryDiary(emotionCount, bondScore);
      case EmotionType.uncomfortable:
        return _getUncomfortableDiary(emotionCount, bondScore);
      case EmotionType.greeting:
        return _getGreetingDiary(emotionCount, bondScore);
      case EmotionType.other:
        return _getGreetingDiary(emotionCount, bondScore); // 當作打招呼處理
    }
  }

  /// 產生完整的日記物件
  CatDiary generateDiary({
    required String catName,
    required EmotionType? dominantEmotion,
    required int totalTranslations,
    required Map<EmotionType, int> emotionCounts,
    required double averageConfidence,
    required int bondScore,
    required bool taskCompleted,
  }) {
    final diaryTitle = getDiaryTitle(catName);
    final emotionCount = dominantEmotion != null ? (emotionCounts[dominantEmotion] ?? 0) : 0;
    
    final diaryText = getDiaryText(
      emotion: dominantEmotion,
      emotionCount: emotionCount,
      bondScore: bondScore,
    );

    final moodSentence = _getMoodSentence(dominantEmotion, totalTranslations);
    final ownerActionSentence = _getOwnerActionSentence(dominantEmotion, taskCompleted);

    return CatDiary(
      title: diaryTitle,
      diaryText: diaryText,
      moodSentence: moodSentence,
      ownerActionSentence: ownerActionSentence,
    );
  }

  /// 取得心情短句
  String _getMoodSentence(EmotionType? emotion, int translationCount) {
    if (emotion == null) {
      return '今天很特別，等待她的第一聲喵 🐱';
    }

    final sentences = {
      EmotionType.affectionate: [
        '她今天很黏人 💕',
        '撒嬌模式啟動中 🐱',
        '很想要你陪陪她',
      ],
      EmotionType.hungry: [
        '肚子在叫了 🍽',
        '小小餓餓訊號 💨',
        '提醒你該備餐了',
      ],
      EmotionType.playful: [
        '精力充沛的一天 🎾',
        '玩心大發中 ✨',
        '想要動一动！',
      ],
      EmotionType.attention: [
        '想要你注意 👀',
        '在呼喚你中...',
        '希望你看過來 💗',
      ],
      EmotionType.anxious: [
        '今天比較敏感 🥺',
        '需要多安撫一下',
        '給她多一點安全感',
      ],
      EmotionType.angry: [
        '今天有點不高興 😾',
        '想要安靜一下',
        '先不要打擾她',
      ],
      EmotionType.uncomfortable: [
        '需要多留意身體 🤔',
        '觀察中...',
        '持續注意中',
      ],
      EmotionType.greeting: [
        '今天狀態不錯 🐾',
        '心情平穩 💖',
        '打招呼中',
      ],
      EmotionType.other: [
        '今天很特別 🐱',
        '有自己的小情緒',
      ],
    };

    final options = sentences[emotion] ?? sentences[EmotionType.other]!;
    return options[_random.nextInt(options.length)];
  }

  /// 取得主人行動短句
  String _getOwnerActionSentence(EmotionType? emotion, bool taskCompleted) {
    if (emotion == null) {
      return '有機會就聽聽她想說什麼吧 🐱';
    }

    final sentences = {
      EmotionType.affectionate: [
        '多摸摸她，讓她更安心',
        '陪她說說話也好',
        '抱抱她吧 💕',
      ],
      EmotionType.hungry: [
        '可以檢查一下飯碗和水碗',
        '快到用餐時間了嗎？',
        '準備小點心安慰她 🍽',
      ],
      EmotionType.playful: [
        '拿逗貓棒陪她玩幾分鐘',
        '準備一些小玩具',
        '陪她消耗一下精力 🎾',
      ],
      EmotionType.attention: [
        '叫她名字回應一下',
        '看她一眼也好',
        '陪她待一會儿 👀',
      ],
      EmotionType.anxious: [
        '給她一個安靜的角落',
        '避免突然的噪音',
        '安撫她一下 🥺',
      ],
      EmotionType.angry: [
        '讓她自己待一會',
        '等她冷靜下來',
        '不要強迫她 😾',
      ],
      EmotionType.uncomfortable: [
        '持續觀察精神與食慾',
        '若持續異常考慮看獸醫',
        '記錄她的狀態 🤔',
      ],
      EmotionType.greeting: [
        '可以輕聲回應她',
        '陪她待一會儿',
        '保持你們的小默契 💕',
      ],
      EmotionType.other: [
        '今天表現得很棒 🐱',
        '持續記錄她的小習慣',
      ],
    };

    final options = sentences[emotion] ?? sentences[EmotionType.other]!;
    return options[_random.nextInt(options.length)];
  }
}

/// 貓咪日記資料類別
class CatDiary {
  final String title;
  final String diaryText;
  final String moodSentence;
  final String ownerActionSentence;

  CatDiary({
    required this.title,
    required this.diaryText,
    required this.moodSentence,
    required this.ownerActionSentence,
  });
}