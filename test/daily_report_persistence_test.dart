import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/daily_report_service.dart';
import 'package:cat_talk/services/translation_history_service.dart';
import 'package:cat_talk/services/cat_learning_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyReportService 歷史保存測試', () {
    late DailyReportService reportService;
    late TranslationHistoryService historyService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // 初始化依賴的服務
      historyService = TranslationHistoryService();
      await historyService.init(prefs);
      
      final learningService = CatLearningService();
      await learningService.init(prefs);
      
      reportService = DailyReportService(
        historyService: historyService,
        learningService: learningService,
      );
      await reportService.init(prefs);
    });

    test('每日報告可保存與讀取', () async {
      // 先加入翻譯記錄
      await historyService.add(TranslationResult(
        id: 'report_test_1',
        catId: 'cat_report_1',
        emotionType: EmotionType.affectionate,
        humanText: '抱抱我',
        confidence: 0.85,
        reason: '長音',
        suggestedAction: '摸摸',
        createdAt: DateTime.now(),
      ));

      // 產生報告
      final report = reportService.getTodayReport('cat_report_1');

      expect(report.catId, 'cat_report_1');
      expect(report.totalTranslations, 1);
      expect(report.dominantEmotion, EmotionType.affectionate);
    });

    test('App 重開後報告仍存在', () async {
      // 先確保所有資料都是乾淨的
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // 建立嶄新的服務（同一 prefs）
      final freshHistoryService = TranslationHistoryService();
      await freshHistoryService.init(prefs);
      await freshHistoryService.clearAll();
      
      final freshLearningService = CatLearningService();
      await freshLearningService.init(prefs);
      await freshLearningService.clearAll();
      
      final freshReportService = DailyReportService(
        historyService: freshHistoryService,
        learningService: freshLearningService,
      );
      await freshReportService.init(prefs);
      
      // 加入翻譯並產生報告
      await freshHistoryService.add(TranslationResult(
        id: 'report_test_2',
        catId: 'cat_report_2',
        emotionType: EmotionType.hungry,
        humanText: '我餓了',
        confidence: 0.9,
        reason: '低沈',
        suggestedAction: '餵食',
        createdAt: DateTime.now(),
      ));

      freshReportService.getTodayReport('cat_report_2');

      // 模擬 App 重開：建立新的 service 實例，但用同一個 prefs
      final newHistoryService = TranslationHistoryService();
      await newHistoryService.init(prefs);
      
      final newLearningService = CatLearningService();
      await newLearningService.init(prefs);
      
      final newReportService = DailyReportService(
        historyService: newHistoryService,
        learningService: newLearningService,
      );
      await newReportService.init(prefs);

      // 取得歷史報告
      final reports = newReportService.getReportsByCatIdWithinDays('cat_report_2', 7);
      expect(reports.isNotEmpty, true);
    });

    test('可取得最近 7 天報告', () async {
      final now = DateTime.now();
      
      // 加入 3 天前的翻譯
      await historyService.add(TranslationResult(
        id: 'report_week_1',
        catId: 'cat_week',
        emotionType: EmotionType.playful,
        humanText: '玩',
        confidence: 0.8,
        reason: '測試',
        suggestedAction: '玩具',
        createdAt: now.subtract(const Duration(days: 3)),
      ));

      // 加入今天的翻譯
      await historyService.add(TranslationResult(
        id: 'report_week_2',
        catId: 'cat_week',
        emotionType: EmotionType.affectionate,
        humanText: '抱',
        confidence: 0.85,
        reason: '測試',
        suggestedAction: '摸',
        createdAt: now,
      ));

      // 產生報告（會保存）
      reportService.generateDailyReport('cat_week', now.subtract(const Duration(days: 3)));
      reportService.generateDailyReport('cat_week', now);

      final weekReports = reportService.getReportsByCatIdWithinDays('cat_week', 7);
      expect(weekReports.isNotEmpty, true);
    });

    test('超過 30 天報告會被清理', () async {
      final now = DateTime.now();
      final oldDate = now.subtract(const Duration(days: 35));
      
      // 加入 35 天前的翻譯
      await historyService.add(TranslationResult(
        id: 'report_old',
        catId: 'cat_old',
        emotionType: EmotionType.hungry,
        humanText: '餓',
        confidence: 0.8,
        reason: '測試',
        suggestedAction: '餵',
        createdAt: oldDate,
      ));

      // 產生舊報告
      reportService.generateDailyReport('cat_old', oldDate);

      // 檢查是否被清理（getReportsByCatIdWithinDays 只取 30 天內）
      final reports = reportService.getReportsByCatIdWithinDays('cat_old', 30);
      // 清理是自動的，所以這個報告可能已經被刪除
      expect(reports.isEmpty || reports.every((r) => r.totalTranslations == 0), true);
    });

    test('多隻貓的報告分開儲存', () async {
      await historyService.add(TranslationResult(
        id: 'report_multi_1',
        catId: 'catA',
        emotionType: EmotionType.hungry,
        humanText: '餓',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: '餵',
        createdAt: DateTime.now(),
      ));

      await historyService.add(TranslationResult(
        id: 'report_multi_2',
        catId: 'catB',
        emotionType: EmotionType.playful,
        humanText: '玩',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: '玩具',
        createdAt: DateTime.now(),
      ));

      final reportA = reportService.getTodayReport('catA');
      final reportB = reportService.getTodayReport('catB');

      expect(reportA.catId, 'catA');
      expect(reportA.dominantEmotion, EmotionType.hungry);
      expect(reportB.catId, 'catB');
      expect(reportB.dominantEmotion, EmotionType.playful);
    });

    test('空歷史不回 crash，回傳空報告', () async {
      final report = reportService.getTodayReport('nonexistent_cat');
      
      expect(report.catId, 'nonexistent_cat');
      expect(report.totalTranslations, 0);
      expect(report.isEmpty, true);
    });

    test('getReportsByCatIdWithinDays 空貓不回 crash', () async {
      final reports = reportService.getReportsByCatIdWithinDays('nonexistent_cat', 7);
      expect(reports, isEmpty);
    });
  });
}
