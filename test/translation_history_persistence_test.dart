import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/translation_history_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranslationHistoryService 持久化測試', () {
    late TranslationHistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      // 清理單例
      service = TranslationHistoryService();
      final prefs = await SharedPreferences.getInstance();
      await service.init(prefs);
      // 清理所有資料
      await service.clearAll();
    });

    test('翻譯記錄可保存與讀取', () async {
      final result = TranslationResult(
        id: 'test_1',
        catId: 'cat_001',
        emotionType: EmotionType.affectionate,
        humanText: '抱抱我嘛～',
        confidence: 0.85,
        reason: '長音喵叫',
        suggestedAction: '花幾分鐘撫摸',
        createdAt: DateTime.now(),
      );

      await service.add(result);
      final history = service.getByCatId('cat_001');

      expect(history.length, 1);
      expect(history[0].id, 'test_1');
      expect(history[0].emotionType, EmotionType.affectionate);
    });

    test('App 重開後資料仍存在', () async {
      // 建立持久化的 prefs（不清理）
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      final result = TranslationResult(
        id: 'test_2',
        catId: 'cat_002',
        emotionType: EmotionType.hungry,
        humanText: '我餓了！',
        confidence: 0.9,
        reason: '低沈叫聲',
        suggestedAction: '檢查貓碗',
        createdAt: DateTime.now(),
      );

      // 第一次：新增資料
      final service1 = TranslationHistoryService();
      await service1.init(prefs);
      await service1.add(result);

      // 模擬 App 重開：建立新的 service 實例，但用同一個 prefs
      final service2 = TranslationHistoryService();
      await service2.init(prefs);

      final history = service2.getByCatId('cat_002');
      expect(history.length, 1);
      expect(history[0].humanText, '我餓了！');
    });

    test('可取得最近 7 天資料', () async {
      final now = DateTime.now();
      
      // 加入 3 天前的資料
      final oldResult = TranslationResult(
        id: 'old_1',
        catId: 'cat_003',
        emotionType: EmotionType.playful,
        humanText: '陪我玩',
        confidence: 0.8,
        reason: '高音',
        suggestedAction: '拿出玩具',
        createdAt: now.subtract(const Duration(days: 3)),
      );

      await service.add(oldResult);

      // 加入今天的資料
      final todayResult = TranslationResult(
        id: 'today_1',
        catId: 'cat_003',
        emotionType: EmotionType.affectionate,
        humanText: '抱抱',
        confidence: 0.85,
        reason: '長音',
        suggestedAction: '摸摸',
        createdAt: now,
      );
      await service.add(todayResult);

      final weekHistory = service.getByCatIdWithinDays('cat_003', 7);
      expect(weekHistory.length, 2);
    });

    test('超過 30 天資料會被清理', () async {
      final now = DateTime.now();
      
      // 加入 35 天前的資料（應該被清理）
      final oldResult = TranslationResult(
        id: 'very_old',
        catId: 'cat_004',
        emotionType: EmotionType.hungry,
        humanText: '我餓了',
        confidence: 0.8,
        reason: '測試',
        suggestedAction: '餵食',
        createdAt: now.subtract(const Duration(days: 35)),
      );

      await service.add(oldResult);

      final history = service.getByCatId('cat_004');
      // 資料應該被自動清理
      expect(history.where((r) => r.id == 'very_old').isEmpty, true);
    });

    test('可刪除特定貓咪的所有歷史', () async {
      await service.add(TranslationResult(
        id: 'del_1',
        catId: 'cat_del',
        emotionType: EmotionType.affectionate,
        humanText: 'test1',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: 'test',
        createdAt: DateTime.now(),
      ));

      expect(service.getByCatId('cat_del').length, 1);

      await service.deleteByCatId('cat_del');

      expect(service.getByCatId('cat_del').length, 0);
    });

    test('多隻貓的資料分開儲存', () async {
      await service.add(TranslationResult(
        id: 'catA_1',
        catId: 'catA',
        emotionType: EmotionType.hungry,
        humanText: '餓',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: '餵食',
        createdAt: DateTime.now(),
      ));

      await service.add(TranslationResult(
        id: 'catB_1',
        catId: 'catB',
        emotionType: EmotionType.playful,
        humanText: '玩',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: '玩具',
        createdAt: DateTime.now(),
      ));

      final catAHistory = service.getByCatId('catA');
      final catBHistory = service.getByCatId('catB');

      expect(catAHistory.length, 1);
      expect(catBHistory.length, 1);
      expect(catAHistory[0].catId, 'catA');
      expect(catBHistory[0].catId, 'catB');
    });

    test('getAll() 回傳所有貓的歷史', () async {
      // 先清理確保乾淨
      await service.clearAll();
      
      await service.add(TranslationResult(
        id: 'all_1',
        catId: 'catX',
        emotionType: EmotionType.hungry,
        humanText: 'test',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: 'test',
        createdAt: DateTime.now(),
      ));

      await service.add(TranslationResult(
        id: 'all_2',
        catId: 'catY',
        emotionType: EmotionType.playful,
        humanText: 'test2',
        confidence: 0.8,
        reason: 'test',
        suggestedAction: 'test',
        createdAt: DateTime.now(),
      ));

      final all = service.getAll();
      expect(all.length, 2);
    });

    test('空列表不可 crash', () async {
      final history = service.getByCatId('nonexistent_cat');
      expect(history, isEmpty);

      final weekHistory = service.getByCatIdWithinDays('nonexistent_cat', 7);
      expect(weekHistory, isEmpty);
    });
  });
}
