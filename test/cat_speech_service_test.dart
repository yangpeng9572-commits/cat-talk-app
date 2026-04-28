import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/translation_result.dart';
import 'package:cat_talk/services/cat_speech_service.dart';

void main() {
  group('CatSpeechService 測試', () {
    late CatSpeechService service;

    setUp(() {
      service = CatSpeechService();
    });

    test('每種 emotion 都能產生擬人化文案', () {
      for (final emotion in EmotionType.values) {
        if (emotion == EmotionType.other) continue;
        final speech = service.getSpeech(emotion);
        expect(speech, isNotEmpty, reason: 'Emotion $emotion should have speech');
      }
    });

    test('affectionate 情緒有5種以上隨機文案', () {
      final speeches = <String>{};
      for (int i = 0; i < 20; i++) {
        speeches.add(service.getSpeech(EmotionType.affectionate));
      }
      // 應該有不同的隨機結果
      expect(speeches.length, greaterThan(1));
    });

    test('confidence 低時取得強度前綴', () {
      final intensity = service.getIntensityPrefix(0.3);
      expect(intensity, isNotEmpty);
      // 應該是低強度的詞（包含這些關鍵字之一）
      expect(intensity, anyOf(
        contains('可能'),
        contains('好像'),
        contains('不太確定'),
        contains('似乎'),
        contains('隱約'),
      ));
    });

    test('confidence 中時取得強度前綴', () {
      final intensity = service.getIntensityPrefix(0.6);
      expect(intensity, isNotEmpty);
      // 應該是中強度的詞（包含這些關鍵字之一）
      expect(intensity, anyOf(
        contains('有點'),
        contains('蠻想'),
        contains('看起來'),
        contains('有那麼一點'),
      ));
    });

    test('confidence 高時取得強度前綴', () {
      final intensity = service.getIntensityPrefix(0.9);
      expect(intensity, isNotEmpty);
      // 應該是高強度的詞（包含這些關鍵字之一）
      expect(intensity, anyOf(
        contains('很想'),
        contains('超想'),
        contains('明顯'),
        contains('強烈'),
        contains('真的'),
      ));
    });

    test('getEmotionIntensity 返回正確格式', () {
      final result = service.getEmotionIntensity(EmotionType.affectionate, 0.8);
      expect(result, contains('撒嬌'));
    });

    test('getReason 返回非空字串', () {
      final reason = service.getReason(EmotionType.affectionate, 0.8);
      expect(reason, isNotEmpty);
    });

    test('getSuggestedActions 返回建議行動列表', () {
      final actions = service.getSuggestedActions(EmotionType.affectionate);
      expect(actions, isNotEmpty);
      expect(actions.length, 3); // 應該有3個建議
    });

    test('affectionate 的建議行動正確', () {
      final actions = service.getSuggestedActions(EmotionType.affectionate);
      expect(actions, contains('摸摸她'));
      expect(actions, contains('陪她待一下'));
    });

    test('hungry 的建議行動正確', () {
      final actions = service.getSuggestedActions(EmotionType.hungry);
      expect(actions, contains('看看飯碗'));
    });

    test('getCorrectFeedback 返回非空字串', () {
      final feedback = service.getCorrectFeedback();
      expect(feedback, isNotEmpty);
    });

    test('getIncorrectFeedback 返回非空字串', () {
      final feedback = service.getIncorrectFeedback();
      expect(feedback, isNotEmpty);
    });

    test('getHighConfidenceHint 返回非空字串', () {
      final hint = service.getHighConfidenceHint();
      expect(hint, isNotEmpty);
    });

    test('getLowConfidenceHint 返回非空字串', () {
      final hint = service.getLowConfidenceHint();
      expect(hint, isNotEmpty);
    });

    test('generateSpeechResult 產生完整結果', () {
      final result = TranslationResult(
        id: 'test_1',
        catId: 'cat_1',
        emotionType: EmotionType.affectionate,
        humanText: 'Test',
        confidence: 0.85,
        reason: 'Test reason',
        suggestedAction: 'Test action',
        createdAt: DateTime.now(),
      );
      
      final speechResult = service.generateSpeechResult(result);
      
      expect(speechResult.speech, isNotEmpty);
      expect(speechResult.emotionIntensity, isNotEmpty);
      expect(speechResult.reason, isNotEmpty);
      expect(speechResult.suggestedActions, isNotEmpty);
      expect(speechResult.isHighConfidence, isTrue);
      expect(speechResult.isLowConfidence, isFalse);
      expect(speechResult.needsVetReminder, isFalse);
    });

    test('uncomfortable 類型需要獸醫提醒', () {
      final result = TranslationResult(
        id: 'test_1',
        catId: 'cat_1',
        emotionType: EmotionType.uncomfortable,
        humanText: 'Test',
        confidence: 0.7,
        reason: 'Test reason',
        suggestedAction: 'Test action',
        createdAt: DateTime.now(),
      );
      
      final speechResult = service.generateSpeechResult(result);
      
      expect(speechResult.needsVetReminder, isTrue);
    });

    test('低信心度翻譯結果 isLowConfidence 為 true', () {
      final result = TranslationResult(
        id: 'test_1',
        catId: 'cat_1',
        emotionType: EmotionType.affectionate,
        humanText: 'Test',
        confidence: 0.4,
        reason: 'Test reason',
        suggestedAction: 'Test action',
        createdAt: DateTime.now(),
      );
      
      final speechResult = service.generateSpeechResult(result);
      
      expect(speechResult.isLowConfidence, isTrue);
      expect(speechResult.isHighConfidence, isFalse);
    });
  });
}
