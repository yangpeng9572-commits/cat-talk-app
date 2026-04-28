import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/translation_result.dart';
import 'package:cat_talk/services/cat_diary_service.dart';

void main() {
  late CatDiaryService diaryService;

  setUp(() {
    diaryService = CatDiaryService();
  });

  group('CatDiaryService 測試', () {
    test('getDiaryTitle 應該正確產生標題', () {
      final title = diaryService.getDiaryTitle('奶茶');
      expect(title, '奶茶 今天的小日記 🐱');
    });

    test('每種情緒都能生成日記文字', () {
      for (final emotion in EmotionType.values) {
        final diaryText = diaryService.getDiaryText(
          emotion: emotion,
          emotionCount: 3,
          bondScore: 50,
        );
        expect(diaryText, isNotEmpty);
        expect(diaryText.contains('\n'), isTrue); // 應該有多行
      }
    });

    test('無情緒（null）應該生成無記錄日記', () {
      final diaryText = diaryService.getDiaryText(
        emotion: null,
        emotionCount: 0,
        bondScore: 10,
      );
      expect(diaryText, contains('今天還沒有記錄到她的小聲音'));
    });

    test('uncomfortable 應該包含安全提醒', () {
      final diaryText = diaryService.getDiaryText(
        emotion: EmotionType.uncomfortable,
        emotionCount: 2,
        bondScore: 30,
      );
      expect(diaryText, contains('獸醫'));
    });

    test('bondScore >= 60 應該有默契句', () {
      final diaryText = diaryService.getDiaryText(
        emotion: EmotionType.affectionate,
        emotionCount: 3,
        bondScore: 65,
      );
      expect(diaryText, contains('默契'));
    });

    test('bondScore >= 80 應該有習慣句', () {
      final diaryText = diaryService.getDiaryText(
        emotion: EmotionType.playful,
        emotionCount: 3,
        bondScore: 85,
      );
      expect(diaryText, contains('習慣'));
    });

    test('bondScore < 25 應該有鼓勵句', () {
      final diaryText = diaryService.getDiaryText(
        emotion: EmotionType.attention,
        emotionCount: 2,
        bondScore: 15,
      );
      expect(diaryText, contains('慢慢記錄'));
    });

    test('generateDiary 應該產生完整日記物件', () {
      final diary = diaryService.generateDiary(
        catName: '奶茶',
        dominantEmotion: EmotionType.affectionate,
        totalTranslations: 5,
        emotionCounts: {EmotionType.affectionate: 3},
        averageConfidence: 0.75,
        bondScore: 50,
        taskCompleted: false,
      );

      expect(diary.title, isNotEmpty);
      expect(diary.diaryText, isNotEmpty);
      expect(diary.moodSentence, isNotEmpty);
      expect(diary.ownerActionSentence, isNotEmpty);
    });

    test('generateDiary 針對不同情緒應該有不同的 moodSentence', () {
      final affectionateDiary = diaryService.generateDiary(
        catName: '奶茶',
        dominantEmotion: EmotionType.affectionate,
        totalTranslations: 5,
        emotionCounts: {},
        averageConfidence: 0.75,
        bondScore: 50,
        taskCompleted: false,
      );

      final hungryDiary = diaryService.generateDiary(
        catName: '奶茶',
        dominantEmotion: EmotionType.hungry,
        totalTranslations: 5,
        emotionCounts: {},
        averageConfidence: 0.75,
        bondScore: 50,
        taskCompleted: false,
      );

      // 不同情緒應該有不同的 moodSentence
      expect(affectionateDiary.moodSentence, isNot(equals(hungryDiary.moodSentence)));
    });
  });
}