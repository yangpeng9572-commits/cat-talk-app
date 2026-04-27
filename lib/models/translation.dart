class Translation {
  final String id;
  final String catId;
  final String originalSound;
  final String translation;
  final TranslationMeaning meaning;
  final DateTime timestamp;
  final String? audioPath;

  Translation({
    required this.id,
    required this.catId,
    required this.originalSound,
    required this.translation,
    required this.meaning,
    required this.timestamp,
    this.audioPath,
  });

  // 翻譯含義
  static TranslationMeaning getMeaning(String sound) {
    // 簡單的關鍵字匹配
    if (sound.contains('餵') || sound.contains('吃')) {
      return TranslationMeaning.hungry;
    } else if (sound.contains('門') || sound.contains('開')) {
      return TranslationMeaning.openDoor;
    } else if (sound.contains('媽') || sound.contains('爸')) {
      return TranslationMeaning.callOwner;
    } else if (sound.contains('愛') || sound.contains('撒')) {
      return TranslationMeaning.love;
    }
    return TranslationMeaning.other;
  }
}

enum TranslationMeaning {
  hungry,       // 餓了
  openDoor,     // 開門
  callOwner,    // 呼喚主人
  love,         // 表達愛意
  play,         // 想玩
  angry,        // 生氣
  fear,         // 害怕
  pain,         // 不舒服
  other,        // 其他
}

extension TranslationMeaningExtension on TranslationMeaning {
  String get emoji {
    switch (this) {
      case TranslationMeaning.hungry:
        return '🍽️';
      case TranslationMeaning.openDoor:
        return '🚪';
      case TranslationMeaning.callOwner:
        return '👋';
      case TranslationMeaning.love:
        return '💕';
      case TranslationMeaning.play:
        return '🎾';
      case TranslationMeaning.angry:
        return '😾';
      case TranslationMeaning.fear:
        return '😿';
      case TranslationMeaning.pain:
        return '🤒';
      case TranslationMeaning.other:
        return '🐱';
    }
  }

  String get label {
    switch (this) {
      case TranslationMeaning.hungry:
        return '餵我！';
      case TranslationMeaning.openDoor:
        return '開門！';
      case TranslationMeaning.callOwner:
        return '媽媽/爸爸！';
      case TranslationMeaning.love:
        return '我愛你！';
      case TranslationMeaning.play:
        return '陪我玩！';
      case TranslationMeaning.angry:
        return '我生氣了！';
      case TranslationMeaning.fear:
        return '我害怕！';
      case TranslationMeaning.pain:
        return '我不舒服...';
      case TranslationMeaning.other:
        return '喵～';
    }
  }
}
