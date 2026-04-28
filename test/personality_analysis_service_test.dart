import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/personality_analysis_service.dart';
import 'package:cat_talk/services/translation_history_service.dart';
import 'package:cat_talk/services/daily_report_service.dart';
import 'package:cat_talk/services/bond_service.dart';
import 'package:cat_talk/services/cat_learning_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PersonalityAnalysisService 測試', () {
    late TranslationHistoryService historyService;
    late DailyReportService reportService;
    late BondService bondService;
    late CatLearningService learningService;
    late PersonalityAnalysisService analysisService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      historyService = TranslationHistoryService();
      await historyService.init(prefs);
      await historyService.clearAll();

      learningService = CatLearningService();
      await learningService.init(prefs);
      await learningService.clearAll();

      reportService = DailyReportService(
        historyService: historyService,
        learningService: learningService,
      );
      await reportService.init(prefs);

      bondService = BondService();
      await bondService.init(prefs);

      analysisService = PersonalityAnalysisService(
        historyService: historyService,
        reportService: reportService,
        bondService: bondService,
        learningService: learningService,
      );
    });

    test('資料不足（< 3筆）顯示空狀態', () async {
      // 只加入 2 筆翻譯
      for (int i = 0; i < 2; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_001',
          emotionType: EmotionType.affectionate,
          humanText: '撒嬌',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_001', '奶茶');

      expect(result.hasEnoughData, false);
      expect(result.personalityType, '');
      expect(result.ownerSuggestion, contains('再記錄幾天'));
    });

    test('可正確計算 TOP 3 情緒', () async {
      // 加入不同情緒的翻譯
      final emotions = [
        EmotionType.affectionate,
        EmotionType.affectionate,
        EmotionType.affectionate, // 3次
        EmotionType.hungry,
        EmotionType.hungry, // 2次
        EmotionType.playful, // 1次
      ];

      for (int i = 0; i < emotions.length; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_002',
          emotionType: emotions[i],
          humanText: 'test',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_002', '奶茶');

      expect(result.hasEnoughData, true);
      expect(result.topEmotions.length, 3);
      expect(result.topEmotions[0], EmotionType.affectionate);
      expect(result.topEmotions[1], EmotionType.hungry);
      expect(result.topEmotions[2], EmotionType.playful);
    });

    test('affectionate 多 → 黏人撒嬌型', () async {
      for (int i = 0; i < 5; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_003',
          emotionType: EmotionType.affectionate,
          humanText: '撒嬌',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_003', '奶茶');

      expect(result.personalityType, '黏人撒嬌型');
      expect(result.personalityDescription, contains('喜歡靠近'));
    });

    test('playful 多 → 活力小淘氣型', () async {
      for (int i = 0; i < 5; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_004',
          emotionType: EmotionType.playful,
          humanText: '想玩',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_004', '奶茶');

      expect(result.personalityType, '活力小淘氣型');
      expect(result.personalityDescription, contains('精神很好'));
    });

    test('hungry 多 → 飯飯提醒型', () async {
      for (int i = 0; i < 5; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_005',
          emotionType: EmotionType.hungry,
          humanText: '餓了',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_005', '奶茶');

      expect(result.personalityType, '飯飯提醒型');
      expect(result.personalityDescription, contains('提醒你生活節奏'));
    });

    test('anxious 多 → 敏感依賴型', () async {
      for (int i = 0; i < 5; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_006',
          emotionType: EmotionType.anxious,
          humanText: '焦慮',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_006', '奶茶');

      expect(result.personalityType, '敏感依賴型');
      expect(result.personalityDescription, contains('比較敏感'));
    });

    test('uncomfortable 有 → 需要觀察型 + 安全提醒', () async {
      for (int i = 0; i < 3; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_007',
          emotionType: EmotionType.uncomfortable,
          humanText: '不舒服',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }
      // 加入其他情緒讓總數 >= 3
      await historyService.add(TranslationResult(
        id: 'test_extra',
        catId: 'cat_007',
        emotionType: EmotionType.affectionate,
        humanText: '撒嬌',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: 'test',
        createdAt: DateTime.now(),
      ));

      final result = analysisService.getAnalysis('cat_007', '奶茶');

      expect(result.personalityType, '需要觀察型');
      expect(result.personalityDescription, contains('需要多留意'));
      expect(result.ownerSuggestion, contains('觀察'));
    });

    test('平均信心值計算正確', () async {
      // 加入不同信心值的翻譯
      final confidences = [0.6, 0.8, 1.0];
      for (int i = 0; i < confidences.length; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_008',
          emotionType: EmotionType.affectionate,
          humanText: 'test',
          confidence: confidences[i],
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      final result = analysisService.getAnalysis('cat_008', '奶茶');

      expect(result.averageConfidence, closeTo(0.8, 0.01));
    });

    test('默契值成長計算', () async {
      // 加入翻譯並加分
      for (int i = 0; i < 5; i++) {
        await historyService.add(TranslationResult(
          id: 'test_$i',
          catId: 'cat_009',
          emotionType: EmotionType.affectionate,
          humanText: 'test',
          confidence: 0.8,
          reason: 'test',
          suggestedAction: 'test',
          createdAt: DateTime.now(),
        ));
      }

      // 手動加分模擬
      await bondService.addBond('cat_009', BondService.eventTranslation);

      final result = analysisService.getAnalysis('cat_009', '奶茶');

      expect(result.bondGrowth, greaterThanOrEqualTo(0));
    });

    test('空資料不回 crash', () async {
      final result = analysisService.getAnalysis('nonexistent_cat', '不存在');

      expect(result.hasEnoughData, false);
      expect(result.catName, '不存在');
    });
  });
}