import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/translation_result.dart';

/// 喵語合成服務
/// 將翻譯結果的文字內容轉換為音訊
///
/// 使用 flutter_tts 文字轉語音功能
class MeowSpeechService {
  static final MeowSpeechService _instance = MeowSpeechService._internal();
  factory MeowSpeechService() => _instance;

  FlutterTts? _flutterTts;
  bool _isInitialized = false;
  bool _isPlaying = false;

  MeowSpeechService._internal();

  // ===== 初始化 =====

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;

    _flutterTts = FlutterTts();

    // 設定 TTS 引擎
    await _flutterTts?.setLanguage('zh-TW');
    await _flutterTts?.setSpeechRate(0.4); // 比較慢、可愛的語速
    await _flutterTts?.setPitch(1.2); // 音調高一點，比較像貓咪
    await _flutterTts?.setVolume(0.8);

    // iOS 特有設定
    await _flutterTts?.setIosAudioCategory(
      IosTextToSpeechAudioCategory.playback,
      [
        IosTextToSpeechAudioCategoryOptions.allowBluetooth,
        IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        IosTextToSpeechAudioCategoryOptions.mixWithOthers,
      ],
      IosTextToSpeechAudioMode.voicePrompt,
    );

    _flutterTts?.setCompletionHandler(() {
      _isPlaying = false;
    });

    _flutterTts?.setCancelHandler(() {
      _isPlaying = false;
    });

    _flutterTts?.setErrorHandler((msg) {
      debugPrint('TTS 錯誤: $msg');
      _isPlaying = false;
    });

    _isInitialized = true;
  }

  // ===== 公開 API =====

  /// 將翻譯結果轉換為語音並播放
  ///
  /// [result] 翻譯結果（包含情緒與翻譯文字）
  /// [catName] 貓咪名字（用於個人化）
  Future<bool> speakTranslation(TranslationResult result, {String? catName}) async {
    await _ensureInitialized();
    if (_flutterTts == null) return false;

    // 根據情緒選擇不同的說話風格
    final text = _generateCatSpeechText(result, catName);

    _isPlaying = true;
    final success = await _flutterTts!.speak(text);
    return success;
  }

  /// 停止播放
  Future<void> stop() async {
    if (_flutterTts != null) {
      await _flutterTts!.stop();
    }
    _isPlaying = false;
  }

  /// 直接說一段文字（用於人話轉喵聲功能）
  Future<bool> speakText(String text) async {
    await _ensureInitialized();
    if (_flutterTts == null) return false;

    _isPlaying = true;
    final success = await _flutterTts!.speak(text);
    return success;
  }

  /// 暫停播放
  Future<void> pause() async {
    if (_flutterTts != null) {
      await _flutterTts!.pause();
    }
  }

  /// 是否正在播放
  bool get isPlaying => _isPlaying;

  // ===== 私人方法 =====

  /// 根據翻譯結果生成 TTS 文字
  String _generateCatSpeechText(TranslationResult result, String? catName) {
    final name = catName ?? '小貓';
    final emotion = result.emotionType;

    // 情緒修飾前綴
    final prefix = _getEmotionPrefix(emotion);
    final mainText = result.humanText;

    // 組合完整句子
    return '$name 說：$prefix$mainText';
  }

  /// 根據情緒取得修飾前綴
  String _getEmotionPrefix(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.affectionate:
        return '撒嬌地說：';
      case EmotionType.hungry:
        return '肚子餓餒地說：';
      case EmotionType.playful:
        return '活潑地說：';
      case EmotionType.attention:
        return '呼喚你說：';
      case EmotionType.anxious:
        return '緊張地說：';
      case EmotionType.angry:
        return '生氣地說：';
      case EmotionType.uncomfortable:
        return '不舒服地說：';
      case EmotionType.greeting:
        return '打招呼說：';
      case EmotionType.other:
        return '輕輕地說：';
    }
  }

  // ===== 資源釋放 =====

  Future<void> dispose() async {
    await stop();
    _flutterTts?.dispose();
    _flutterTts = null;
    _isInitialized = false;
  }
}
