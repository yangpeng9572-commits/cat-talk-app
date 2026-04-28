import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/translation_result.dart';
import 'package:cat_talk/models/daily_cat_report.dart';
import 'package:cat_talk/services/emotional_headline_service.dart';

void main() {
  group('EmotionalHeadlineService 測試', () {
    late EmotionalHeadlineService service;

    setUp(() {
      service = EmotionalHeadlineService();
    });

    test('affectionate 情緒應該有對應的 headline', () {
      final headline = service.getHeadline('奶茶', EmotionType.affectionate);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('hungry 情緒應該有對應的 headline', () {
      final headline = service.getHeadline('奶茶', EmotionType.hungry);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('playful 情緒應該有對應的 headline', () {
      final headline = service.getHeadline('奶茶', EmotionType.playful);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('焦慮情緒應該有安慰性的 headline', () {
      final headline = service.getHeadline('奶茶', EmotionType.anxious);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('打招呼情緒應該有正面的 headline', () {
      final headline = service.getHeadline('奶茶', EmotionType.greeting);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('無情緒（null）應該顯示空狀態文案', () {
      final headline = service.getHeadline('奶茶', null);
      expect(headline, isNotEmpty);
      expect(headline, contains('奶茶'));
    });

    test('getSubtitle 應該返回非空字串', () {
      final subtitle = service.getSubtitle('奶茶', EmotionType.affectionate);
      expect(subtitle, isNotEmpty);
    });

    test('getEmotionTag 應該返回情緒標籤', () {
      expect(service.getEmotionTag(EmotionType.affectionate), '想撒嬌');
      expect(service.getEmotionTag(EmotionType.hungry), '肚子餓');
      expect(service.getEmotionTag(EmotionType.playful), '想玩');
      expect(service.getEmotionTag(EmotionType.attention), '想被注意');
      expect(service.getEmotionTag(EmotionType.anxious), '有點不安');
      expect(service.getEmotionTag(EmotionType.angry), '生氣中');
      expect(service.getEmotionTag(EmotionType.uncomfortable), '不舒服');
      expect(service.getEmotionTag(EmotionType.greeting), '打招呼');
      expect(service.getEmotionTag(EmotionType.other), '其他');
      expect(service.getEmotionTag(null), '還在觀察');
    });

    test('getEmotionEmoji 應該返回情緒 emoji', () {
      expect(service.getEmotionEmoji(EmotionType.affectionate), '💕');
      expect(service.getEmotionEmoji(EmotionType.hungry), '🍽');
      expect(service.getEmotionEmoji(EmotionType.playful), '🎾');
      expect(service.getEmotionEmoji(EmotionType.attention), '👀');
      expect(service.getEmotionEmoji(EmotionType.anxious), '😿');
      expect(service.getEmotionEmoji(EmotionType.angry), '😾');
      expect(service.getEmotionEmoji(EmotionType.uncomfortable), '🤒');
      expect(service.getEmotionEmoji(EmotionType.greeting), '🐾');
      expect(service.getEmotionEmoji(null), '🐱');
    });
  });

  group('FeedbackMessageService 測試', () {
    late FeedbackMessageService service;

    setUp(() {
      service = FeedbackMessageService();
    });

    test('getTranslationCompletedMessage 應該返回非空字串', () {
      final message = service.getTranslationCompletedMessage();
      expect(message, isNotEmpty);
    });

    test('getReportViewedMessage 應該返回非空字串', () {
      final message = service.getReportViewedMessage();
      expect(message, isNotEmpty);
    });
  });
}
