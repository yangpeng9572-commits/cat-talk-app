/// 貓叫聲翻譯結果模型
/// 儲存每一次翻譯的完整資料
class TranslationResult {
  final String id;
  final String catId;
  final EmotionType emotionType;
  final String humanText;
  final double confidence;
  final String reason;
  final String suggestedAction;
  final AudioFeatures? audioFeatures;
  final DateTime createdAt;
  final UserFeedback? userFeedback;

  const TranslationResult({
    required this.id,
    required this.catId,
    required this.emotionType,
    required this.humanText,
    required this.confidence,
    required this.reason,
    required this.suggestedAction,
    this.audioFeatures,
    required this.createdAt,
    this.userFeedback,
  });

  /// 從 JSON 建立 TranslationResult
  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      id: json['id'] as String,
      catId: json['catId'] as String,
      emotionType: EmotionType.values.firstWhere(
        (e) => e.name == json['emotionType'],
        orElse: () => EmotionType.other,
      ),
      humanText: json['humanText'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      reason: json['reason'] as String,
      suggestedAction: json['suggestedAction'] as String,
      audioFeatures: json['audioFeatures'] != null
          ? AudioFeatures.fromJson(json['audioFeatures'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      userFeedback: json['userFeedback'] != null
          ? UserFeedback.fromJson(json['userFeedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'emotionType': emotionType.name,
      'humanText': humanText,
      'confidence': confidence,
      'reason': reason,
      'suggestedAction': suggestedAction,
      'audioFeatures': audioFeatures?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'userFeedback': userFeedback?.toJson(),
    };
  }

  /// 複製並修改特定欄位
  TranslationResult copyWith({
    String? id,
    String? catId,
    EmotionType? emotionType,
    String? humanText,
    double? confidence,
    String? reason,
    String? suggestedAction,
    AudioFeatures? audioFeatures,
    DateTime? createdAt,
    UserFeedback? userFeedback,
  }) {
    return TranslationResult(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      emotionType: emotionType ?? this.emotionType,
      humanText: humanText ?? this.humanText,
      confidence: confidence ?? this.confidence,
      reason: reason ?? this.reason,
      suggestedAction: suggestedAction ?? this.suggestedAction,
      audioFeatures: audioFeatures ?? this.audioFeatures,
      createdAt: createdAt ?? this.createdAt,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }
}

/// 情緒類型列舉（8種）
enum EmotionType {
  hungry,        // 餓了想吃
  affectionate,  // 想要撒嬌
  playful,       // 想要玩耍
  attention,     // 需要關注
  anxious,       // 焦慮不安
  angry,         // 生氣不滿
  uncomfortable, // 不舒服
  greeting,      // 問候打招呼
  other,         // 其他/無法判斷
}

extension EmotionTypeExtension on EmotionType {
  /// 取得情緒 Emoji
  String get emoji {
    switch (this) {
      case EmotionType.hungry:
        return '🍽️';
      case EmotionType.affectionate:
        return '💕';
      case EmotionType.playful:
        return '🎾';
      case EmotionType.attention:
        return '👀';
      case EmotionType.anxious:
        return '😿';
      case EmotionType.angry:
        return '😾';
      case EmotionType.uncomfortable:
        return '🤒';
      case EmotionType.greeting:
        return '👋';
      case EmotionType.other:
        return '🐱';
    }
  }

  /// 取得情緒標籤（中文）
  String get label {
    switch (this) {
      case EmotionType.hungry:
        return '肚子餓了';
      case EmotionType.affectionate:
        return '想要撒嬌';
      case EmotionType.playful:
        return '想要玩耍';
      case EmotionType.attention:
        return '需要關注';
      case EmotionType.anxious:
        return '焦慮不安';
      case EmotionType.angry:
        return '生氣不滿';
      case EmotionType.uncomfortable:
        return '不舒服';
      case EmotionType.greeting:
        return '問候打招呼';
      case EmotionType.other:
        return '無法判斷';
    }
  }

  /// 取得顏色
  int get colorValue {
    switch (this) {
      case EmotionType.hungry:
        return 0xFFFF9800; // 橙色
      case EmotionType.affectionate:
        return 0xFFE91E63; // 粉紅色
      case EmotionType.playful:
        return 0xFF4CAF50; // 綠色
      case EmotionType.attention:
        return 0xFF9C27B0; // 紫色
      case EmotionType.anxious:
        return 0xFF795548; // 棕色
      case EmotionType.angry:
        return 0xFFF44336; // 紅色
      case EmotionType.uncomfortable:
        return 0xFF607D8B; // 藍灰色
      case EmotionType.greeting:
        return 0xFF2196F3; // 藍色
      case EmotionType.other:
        return 0xFF9E9E9E; // 灰色
    }
  }
}

/// 音訊特徵資料
class AudioFeatures {
  /// 錄音時長（毫秒）
  final double duration;

  /// 音量大小（0.0 - 1.0）
  final double volume;

  /// 音高頻率（Hz）
  final double pitch;

  /// 偵測到的喵聲次數
  final int meowCount;

  /// 是否為快速連續叫聲
  final bool isRapid;

  /// 是否為長音喵叫
  final bool isLongMeow;

  /// 錄音時間
  final DateTime recordedAt;

  const AudioFeatures({
    required this.duration,
    required this.volume,
    required this.pitch,
    required this.meowCount,
    required this.isRapid,
    required this.isLongMeow,
    required this.recordedAt,
  });

  /// 從 JSON 建立
  factory AudioFeatures.fromJson(Map<String, dynamic> json) {
    return AudioFeatures(
      duration: (json['duration'] as num).toDouble(),
      volume: (json['volume'] as num).toDouble(),
      pitch: (json['pitch'] as num).toDouble(),
      meowCount: json['meowCount'] as int,
      isRapid: json['isRapid'] as bool,
      isLongMeow: json['isLongMeow'] as bool,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'duration': duration,
      'volume': volume,
      'pitch': pitch,
      'meowCount': meowCount,
      'isRapid': isRapid,
      'isLongMeow': isLongMeow,
      'recordedAt': recordedAt.toIso8601String(),
    };
  }

  /// 建立 Mock 測試用的 AudioFeatures
  factory AudioFeatures.mock() {
    return AudioFeatures(
      duration: 1500.0,
      volume: 0.7,
      pitch: 450.0,
      meowCount: 3,
      isRapid: false,
      isLongMeow: false,
      recordedAt: DateTime.now(),
    );
  }

  /// 複製並修改特定欄位
  AudioFeatures copyWith({
    double? duration,
    double? volume,
    double? pitch,
    int? meowCount,
    bool? isRapid,
    bool? isLongMeow,
    DateTime? recordedAt,
  }) {
    return AudioFeatures(
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
      meowCount: meowCount ?? this.meowCount,
      isRapid: isRapid ?? this.isRapid,
      isLongMeow: isLongMeow ?? this.isLongMeow,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  /// 取得音高分類
  PitchCategory get pitchCategory {
    if (pitch < 300) return PitchCategory.low;
    if (pitch < 500) return PitchCategory.medium;
    if (pitch < 700) return PitchCategory.high;
    return PitchCategory.veryHigh;
  }

  /// 取得音量分類
  VolumeCategory get volumeCategory {
    if (volume < 0.3) return VolumeCategory.quiet;
    if (volume < 0.6) return VolumeCategory.medium;
    return VolumeCategory.loud;
  }
}

/// 音高分類
enum PitchCategory {
  low,      // 低沉
  medium,   // 普通
  high,     // 高亢
  veryHigh, // 非常尖銳
}

/// 音量分類
enum VolumeCategory {
  quiet,  // 安靜
  medium, // 普通
  loud,   // 大聲
}

extension PitchCategoryExtension on PitchCategory {
  String get label {
    switch (this) {
      case PitchCategory.low:
        return '低沉';
      case PitchCategory.medium:
        return '普通';
      case PitchCategory.high:
        return '高亢';
      case PitchCategory.veryHigh:
        return '尖銳';
    }
  }
}

extension VolumeCategoryExtension on VolumeCategory {
  String get label {
    switch (this) {
      case VolumeCategory.quiet:
        return '安靜';
      case VolumeCategory.medium:
        return '普通';
      case VolumeCategory.loud:
        return '大聲';
    }
  }
}

/// 用戶回饋
class UserFeedback {
  final bool isCorrect;
  final String? correctedEmotion;
  final String? comment;
  final DateTime timestamp;

  const UserFeedback({
    required this.isCorrect,
    this.correctedEmotion,
    this.comment,
    required this.timestamp,
  });

  factory UserFeedback.fromJson(Map<String, dynamic> json) {
    return UserFeedback(
      isCorrect: json['isCorrect'] as bool,
      correctedEmotion: json['correctedEmotion'] as String?,
      comment: json['comment'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isCorrect': isCorrect,
      'correctedEmotion': correctedEmotion,
      'comment': comment,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// 建立「正確」的回饋
  factory UserFeedback.correct() {
    return UserFeedback(
      isCorrect: true,
      timestamp: DateTime.now(),
    );
  }

  /// 建立「修正」的回饋
  factory UserFeedback.corrected(String correctEmotion, {String? comment}) {
    return UserFeedback(
      isCorrect: false,
      correctedEmotion: correctEmotion,
      comment: comment,
      timestamp: DateTime.now(),
    );
  }
}