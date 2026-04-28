import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/cat_learning_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CatLearningService 持久化測試', () {
    late CatLearningService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = CatLearningService();
      final prefs = await SharedPreferences.getInstance();
      await service.init(prefs);
    });

    test('learnFromCorrection 可保存', () async {
      await service.learnFromCorrection('cat_001', EmotionType.hungry);
      
      final boosts = service.getEmotionBoosts('cat_001');
      expect(boosts[EmotionType.hungry], 0.1);
    });

    test('App 重開後學習資料仍存在', () async {
      // 建立持久化的 prefs（不清理）
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      
      // 第一次：學習
      final service1 = CatLearningService();
      await service1.init(prefs);
      await service1.learnFromCorrection('cat_002', EmotionType.affectionate);
      await service1.learnFromCorrection('cat_002', EmotionType.affectionate); // 累積

      // 驗證有資料
      final boostsBefore = service1.getEmotionBoosts('cat_002');
      expect(boostsBefore[EmotionType.affectionate], 0.2);

      // 模擬 App 重開：建立新的 service 實例，但用同一個 prefs
      final service2 = CatLearningService();
      await service2.init(prefs);

      // 驗證學習資料還在
      final boostsAfter = service2.getEmotionBoosts('cat_002');
      expect(boostsAfter[EmotionType.affectionate], 0.2);
    });

    test('learnFromConfirmation 可保存', () async {
      await service.learnFromConfirmation('cat_003', EmotionType.playful);
      
      final boosts = service.getEmotionBoosts('cat_003');
      expect(boosts[EmotionType.playful], 0.05); // 確認權重是修正的一半
    });

    test('多隻貓的學習資料分開儲存', () async {
      await service.learnFromCorrection('catA', EmotionType.hungry);
      await service.learnFromCorrection('catB', EmotionType.playful);

      final boostsA = service.getEmotionBoosts('catA');
      final boostsB = service.getEmotionBoosts('catB');

      expect(boostsA[EmotionType.hungry], 0.1);
      expect(boostsA.containsKey(EmotionType.playful), false);
      expect(boostsB[EmotionType.playful], 0.1);
      expect(boostsB.containsKey(EmotionType.hungry), false);
    });

    test('getMostCorrectedEmotion 回傳正確', () async {
      await service.learnFromCorrection('cat_004', EmotionType.hungry);
      await service.learnFromCorrection('cat_004', EmotionType.hungry);
      await service.learnFromCorrection('cat_004', EmotionType.affectionate); // 只有一次

      final mostCorrected = service.getMostCorrectedEmotion('cat_004');
      expect(mostCorrected, EmotionType.hungry);
    });

    test('clearLearningForCat 可清除特定貓資料', () async {
      await service.learnFromCorrection('cat_del', EmotionType.hungry);
      await service.clearLearningForCat('cat_del');

      final boosts = service.getEmotionBoosts('cat_del');
      expect(boosts.isEmpty, true);
    });

    test('clearAll 可清除所有學習資料', () async {
      await service.learnFromCorrection('catA', EmotionType.hungry);
      await service.learnFromCorrection('catB', EmotionType.playful);
      
      await service.clearAll();

      expect(service.getEmotionBoosts('catA').isEmpty, true);
      expect(service.getEmotionBoosts('catB').isEmpty, true);
    });

    test('權重上限檢查', () async {
      // 嘗試加超過上限
      for (int i = 0; i < 10; i++) {
        await service.learnFromCorrection('cat_max', EmotionType.hungry);
      }

      final boost = service.getEmotionBoosts('cat_max')[EmotionType.hungry];
      expect(boost, 0.5); // 不應超過 0.5
    });

    test('空資料不回 crash', () async {
      final boosts = service.getEmotionBoosts('nonexistent');
      expect(boosts.isEmpty, true);

      final mostCorrected = service.getMostCorrectedEmotion('nonexistent');
      expect(mostCorrected, null);
    });
  });
}
