import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/daily_cat_report.dart';
import 'package:cat_talk/models/translation_result.dart';
import 'package:cat_talk/services/daily_report_service.dart';
import 'package:cat_talk/services/translation_history_service.dart';
import 'package:cat_talk/services/cat_learning_service.dart';

void main() {
  group('DailyCatReport Model 測試', () {
    test('应该能建立空状态报告', () {
      final report = DailyCatReport.empty(
        catId: 'cat_1',
        date: DateTime.now(),
      );

      expect(report.isEmpty, true);
      expect(report.totalTranslations, 0);
      expect(report.dominantEmotion, null);
      expect(report.headlineText, '今天還沒有紀錄');
    });

    test('应该能正确计算 isEmpty', () {
      final emptyReport = DailyCatReport(
        id: '1',
        catId: 'cat_1',
        date: DateTime.now(),
        totalTranslations: 0,
        dominantEmotion: null,
        averageConfidence: 0.0,
        emotionCounts: {},
        summaryText: '',
        suggestedAction: '',
        warningLevel: WarningLevel.normal,
        createdAt: DateTime.now(),
        headlineText: '今天還沒有紀錄',
      );

      final nonEmptyReport = DailyCatReport(
        id: '2',
        catId: 'cat_1',
        date: DateTime.now(),
        totalTranslations: 5,
        dominantEmotion: EmotionType.hungry,
        averageConfidence: 0.75,
        emotionCounts: {EmotionType.hungry: 3},
        summaryText: 'Test',
        suggestedAction: 'Test',
        warningLevel: WarningLevel.normal,
        createdAt: DateTime.now(),
        headlineText: '今天牠有點愛吃',
      );

      expect(emptyReport.isEmpty, true);
      expect(nonEmptyReport.isEmpty, false);
    });

    test('应该能正确转换 JSON', () {
      final report = DailyCatReport(
        id: 'test_id',
        catId: 'cat_1',
        date: DateTime(2026, 4, 27),
        totalTranslations: 10,
        dominantEmotion: EmotionType.hungry,
        averageConfidence: 0.85,
        emotionCounts: {EmotionType.hungry: 5, EmotionType.affectionate: 5},
        summaryText: '今天牠比较饿',
        suggestedAction: '去看看猫碗',
        warningLevel: WarningLevel.notice,
        createdAt: DateTime(2026, 4, 27, 12, 0),
        headlineText: '今天牠一直在討吃',
      );

      final json = report.toJson();
      final fromJson = DailyCatReport.fromJson(json);

      expect(fromJson.id, 'test_id');
      expect(fromJson.catId, 'cat_1');
      expect(fromJson.totalTranslations, 10);
      expect(fromJson.dominantEmotion, EmotionType.hungry);
      expect(fromJson.averageConfidence, 0.85);
      expect(fromJson.warningLevel, WarningLevel.notice);
      expect(fromJson.headlineText, '今天牠一直在討吃');
    });

    test('应该能正确显示情续分布文字', () {
      final report = DailyCatReport(
        id: '1',
        catId: 'cat_1',
        date: DateTime.now(),
        totalTranslations: 10,
        dominantEmotion: EmotionType.hungry,
        averageConfidence: 0.85,
        emotionCounts: {
          EmotionType.hungry: 5,
          EmotionType.affectionate: 3,
          EmotionType.playful: 2,
        },
        summaryText: 'Test',
        suggestedAction: 'Test',
        warningLevel: WarningLevel.normal,
        createdAt: DateTime.now(),
        headlineText: '今天牠一直在討吃',
      );

      final text = report.emotionDistributionText;
      expect(text.isNotEmpty, true);
      expect(text.contains('5'), true); // 包含次数信息
    });
  });

  group('WarningLevel 測試', () {
    test('应该正确显示 label', () {
      expect(WarningLevel.normal.label, '正常');
      expect(WarningLevel.notice.label, '留意');
      expect(WarningLevel.attention.label, '關注');
    });

    test('应该正确显示 emoji', () {
      expect(WarningLevel.normal.emoji, '✅');
      expect(WarningLevel.notice.emoji, '👀');
      expect(WarningLevel.attention.emoji, '⚠️');
    });
  });

  group('DailyReportService 核心逻辑测试', () {
    late DailyReportService reportService;
    late TranslationHistoryService historyService;

    setUp(() {
      historyService = TranslationHistoryService();
      reportService = DailyReportService(
        historyService: historyService,
        learningService: CatLearningService(),
      );
    });

    test('无记录时应返回空状态报告', () {
      final report = reportService.getTodayReport('cat_no_data');

      expect(report.isEmpty, true);
      expect(report.totalTranslations, 0);
      expect(report.summaryText.isNotEmpty, true);
    });

    test('应该正确计算 dominantEmotion', () {
      // 先加入一些测试数据到历史记录
      final mockResults = [
        TranslationResult(
          id: '1',
          catId: 'cat_test',
          emotionType: EmotionType.hungry,
          humanText: '我饿了',
          confidence: 0.8,
          reason: 'Test',
          suggestedAction: '喂食',
          createdAt: DateTime.now(),
        ),
        TranslationResult(
          id: '2',
          catId: 'cat_test',
          emotionType: EmotionType.hungry,
          humanText: '我饿了',
          confidence: 0.7,
          reason: 'Test',
          suggestedAction: '喂食',
          createdAt: DateTime.now(),
        ),
        TranslationResult(
          id: '3',
          catId: 'cat_test',
          emotionType: EmotionType.affectionate,
          humanText: '摸摸我',
          confidence: 0.9,
          reason: 'Test',
          suggestedAction: '抚摸',
          createdAt: DateTime.now(),
        ),
      ];

      for (final result in mockResults) {
        historyService.add(result);
      }

      final report = reportService.generateDailyReport('cat_test', DateTime.now());

      expect(report.totalTranslations, 3);
      expect(report.dominantEmotion, EmotionType.hungry); // 出现最多
      expect(report.emotionCounts[EmotionType.hungry], 2);
      expect(report.emotionCounts[EmotionType.affectionate], 1);
    });

    test('应该正确计算 averageConfidence', () {
      final mockResults = [
        TranslationResult(
          id: '1',
          catId: 'cat_conf',
          emotionType: EmotionType.hungry,
          humanText: 'Test',
          confidence: 0.8,
          reason: 'Test',
          suggestedAction: 'Test',
          createdAt: DateTime.now(),
        ),
        TranslationResult(
          id: '2',
          catId: 'cat_conf',
          emotionType: EmotionType.affectionate,
          humanText: 'Test',
          confidence: 0.6,
          reason: 'Test',
          suggestedAction: 'Test',
          createdAt: DateTime.now(),
        ),
        TranslationResult(
          id: '3',
          catId: 'cat_conf',
          emotionType: EmotionType.playful,
          humanText: 'Test',
          confidence: 0.9,
          reason: 'Test',
          suggestedAction: 'Test',
          createdAt: DateTime.now(),
        ),
      ];

      for (final result in mockResults) {
        historyService.add(result);
      }

      final report = reportService.generateDailyReport('cat_conf', DateTime.now());

      // (0.8 + 0.6 + 0.9) / 3 = 0.767
      expect(report.averageConfidence, closeTo(0.767, 0.01));
    });

    test('应该正确判断 warningLevel - uncomfortable > 2', () {
      final level = reportService.calculateWarningLevel({
        EmotionType.uncomfortable: 3,
      });
      expect(level, WarningLevel.attention);
    });

    test('应该正确判断 warningLevel - anxious > 3', () {
      final level = reportService.calculateWarningLevel({
        EmotionType.anxious: 4,
      });
      expect(level, WarningLevel.notice);
    });

    test('应该正确判断 warningLevel - 其他情况', () {
      final level = reportService.calculateWarningLevel({
        EmotionType.hungry: 5,
        EmotionType.affectionate: 3,
      });
      expect(level, WarningLevel.normal);
    });

    test('应该生成 summaryText', () {
      final summary = reportService.generateSummaryText(
        catId: 'cat_test',
        dominantEmotion: EmotionType.hungry,
        totalTranslations: 5,
        averageConfidence: 0.7,
        emotionCounts: {EmotionType.hungry: 5},
      );

      expect(summary.isNotEmpty, true);
      expect(summary.length > 10, true);
    });

    test('totalTranslations > 10 应追加提醒', () {
      final summary = reportService.generateSummaryText(
        catId: 'cat_test',
        dominantEmotion: EmotionType.attention,
        totalTranslations: 15,
        averageConfidence: 0.7,
        emotionCounts: {EmotionType.attention: 15},
      );

      expect(summary.contains('需要多給予關注'), true);
    });

    test('averageConfidence < 0.5 应追加说明', () {
      final summary = reportService.generateSummaryText(
        catId: 'cat_test',
        dominantEmotion: EmotionType.other,
        totalTranslations: 5,
        averageConfidence: 0.4,
        emotionCounts: {EmotionType.other: 5},
      );

      expect(summary.contains('不確定'), true);
    });

    test('应该生成 suggestedAction', () {
      final action = reportService.generateSuggestedAction(
        catId: 'cat_test',
        dominantEmotion: EmotionType.hungry,
        emotionCounts: {EmotionType.hungry: 3},
      );

      expect(action.isNotEmpty, true);
      expect(action.length > 5, true);
    });

    test('应该返回空状态报告当无记录时', () {
      final report = reportService.generateDailyReport(
        'cat_never_used',
        DateTime(2026, 4, 27),
      );

      expect(report.isEmpty, true);
      expect(report.summaryText.isNotEmpty, true);
    });
  });

  group('EmotionType 測試', () {
    test('所有情绪应该有 emoji', () {
      for (final emotion in EmotionType.values) {
        expect(emotion.emoji.isNotEmpty, true);
      }
    });

    test('所有情绪应该有 label', () {
      for (final emotion in EmotionType.values) {
        expect(emotion.label.isNotEmpty, true);
      }
    });

    test('EmotionType 应该有9种情绪', () {
      expect(EmotionType.values.length, 9);
    });
  });

  group('CatLearningService 測試', () {
    late CatLearningService learningService;

    setUp(() {
      learningService = CatLearningService();
      learningService.clearAll();
    });

    test('应该能记录修正并调整权重', () {
      learningService.learnFromCorrection('cat_1', EmotionType.hungry);
      learningService.learnFromCorrection('cat_1', EmotionType.hungry);

      final weights = learningService.getEmotionWeights('cat_1');
      expect(weights[EmotionType.hungry], closeTo(0.2, 0.01));
    });

    test('权重上限为 0.5', () {
      for (int i = 0; i < 10; i++) {
        learningService.learnFromCorrection('cat_max', EmotionType.hungry);
      }

      final weights = learningService.getEmotionWeights('cat_max');
      expect(weights[EmotionType.hungry], 0.5);
    });

    test('应该返回空map当无学习记录', () {
      final weights = learningService.getEmotionWeights('cat_new');
      expect(weights.isEmpty, true);
    });

    test('应该能获取最常被修正的情绪', () {
      learningService.learnFromCorrection('cat_1', EmotionType.hungry);
      learningService.learnFromCorrection('cat_1', EmotionType.hungry);
      learningService.learnFromCorrection('cat_1', EmotionType.affectionate);

      final mostCorrected = learningService.getMostCorrectedEmotion('cat_1');
      expect(mostCorrected, EmotionType.hungry);
    });

    test('getStats 应该返回正确统计', () {
      learningService.learnFromCorrection('cat_stats', EmotionType.hungry);

      final stats = learningService.getStats('cat_stats');
      expect(stats.catId, 'cat_stats');
      expect(stats.hasLearningData, true);
    });
  });
}
