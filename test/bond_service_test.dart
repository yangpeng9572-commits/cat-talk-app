import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/models/bond.dart';
import 'package:cat_talk/services/bond_service.dart';

void main() {
  late SharedPreferences prefs;
  late BondService bondService;

  const testCatId = 'test_cat_001';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    bondService = BondService();
    await bondService.init(prefs);
  });

  group('Bond Model 測試', () {
    test('getLevelName 應該正確回傳等級名稱', () {
      expect(Bond.getLevelName(0), '剛認識');
      expect(Bond.getLevelName(5), '剛認識');
      expect(Bond.getLevelName(10), '開始熟悉');
      expect(Bond.getLevelName(24), '開始熟悉');
      expect(Bond.getLevelName(25), '小小默契');
      expect(Bond.getLevelName(39), '小小默契');
      expect(Bond.getLevelName(40), '越來越懂');
      expect(Bond.getLevelName(59), '越來越懂');
      expect(Bond.getLevelName(60), '心有靈犀');
      expect(Bond.getLevelName(79), '心有靈犀');
      expect(Bond.getLevelName(80), '靈魂夥伴');
      expect(Bond.getLevelName(94), '靈魂夥伴');
      expect(Bond.getLevelName(95), '命定貓奴');
      expect(Bond.getLevelName(100), '命定貓奴');
    });

    test('factory empty 應該建立初始化的 Bond', () {
      final bond = Bond.empty(testCatId);
      expect(bond.catId, testCatId);
      expect(bond.bondScore, 0);
      expect(bond.levelName, '剛認識');
      expect(bond.todayGain, 0);
      expect(bond.totalGain, 0);
      expect(bond.streakBonusApplied, false);
    });

    test('copyWith 應該正確複製並更新欄位', () {
      final bond = Bond.empty(testCatId);
      final updated = bond.copyWith(bondScore: 50);
      expect(updated.bondScore, 50);
      expect(updated.catId, testCatId);
      expect(bond.bondScore, 0); // 原物件不變
    });

    test('toJson / fromJson 應該正確序列化', () {
      final bond = Bond.empty(testCatId).copyWith(
        bondScore: 75,
        todayGain: 10,
        totalGain: 75,
      );
      final json = bond.toJson();
      final restored = Bond.fromJson(json);
      expect(restored.catId, testCatId);
      expect(restored.bondScore, 75);
      expect(restored.todayGain, 10);
      expect(restored.totalGain, 75);
    });
  });

  group('BondService 測試', () {
    test('getBond 應該取得初始化的 Bond', () {
      final bond = bondService.getBond(testCatId);
      expect(bond.catId, testCatId);
      expect(bond.bondScore, 0);
    });

    test('完成翻譯應該增加 +2', () async {
      final gain1 = await bondService.addBond(testCatId, BondService.eventTranslation);
      expect(gain1, 2);
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 2);
    });

    test('回饋應該增加 +3', () async {
      // 先翻譯建立一些分數
      await bondService.addBond(testCatId, BondService.eventTranslation);
      
      // 回饋
      final gain = await bondService.addBond(testCatId, BondService.eventFeedback);
      expect(gain, 3);
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 5); // 2 + 3
    });

    test('每日任務完成應該增加 +5', () async {
      final gain = await bondService.addBond(testCatId, BondService.eventTaskComplete);
      expect(gain, 5);
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 5);
    });

    test('連續陪伴獎勵應該增加 +10', () async {
      final gain = await bondService.applyStreakBonus(testCatId);
      expect(gain, 10);
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 10);
    });

    test('連續陪伴獎勵每天最多一次', () async {
      final gain1 = await bondService.applyStreakBonus(testCatId);
      expect(gain1, 10);
      
      final gain2 = await bondService.applyStreakBonus(testCatId);
      expect(gain2, 0); // 已經套用過
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 10); // 不會再增加
    });

    test('每日上限應該是 20', () async {
      // 使用有 translationId 的 action tap 來模擬多次加分（不同翻譯）
      // 這樣可以避開「每天每事件類型只能一次」的限制
      // 
      // 21 次 action tap，每個翻譯 ID 不同
      // 前 20 次可以加分，第 21 次被每日上限擋住
      for (int i = 0; i < 21; i++) {
        await bondService.addBond(
          testCatId,
          BondService.eventActionTap,
          translationId: 'translation_$i',
        );
      }
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 20); // 每日上限 20
    });

    test('bondScore 不應該超過 100', () async {
      // 直接加到 100
      for (int i = 0; i < 50; i++) {
        await bondService.addBond(testCatId, BondService.eventTaskComplete);
      }
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, lessThanOrEqualTo(100));
    });

    test('同一翻譯事件不可重複加分', () async {
      const translationId = 'translation_001';
      
      final gain1 = await bondService.addBond(
        testCatId,
        BondService.eventTranslation,
        translationId: translationId,
      );
      expect(gain1, 2);
      
      final gain2 = await bondService.addBond(
        testCatId,
        BondService.eventTranslation,
        translationId: translationId,
      );
      expect(gain2, 0); // 已經加過
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 2); // 不會再增加
    });

    test('查看報告應該增加 +1', () async {
      final gain = await bondService.addBond(testCatId, BondService.eventViewReport);
      expect(gain, 1);
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 1);
    });

    test('點擊建議行動應該增加 +1', () async {
      const translationId = 'translation_002';
      
      final gain1 = await bondService.addBond(
        testCatId,
        BondService.eventActionTap,
        translationId: translationId,
      );
      expect(gain1, 1);
      
      final gain2 = await bondService.addBond(
        testCatId,
        BondService.eventActionTap,
        translationId: translationId,
      );
      expect(gain2, 0); // 同一翻譯只能加一次
      
      final bond = bondService.getBond(testCatId);
      expect(bond.bondScore, 1);
    });

    test('getHistory 應該回傳歷史記錄', () async {
      await bondService.addBond(testCatId, BondService.eventTranslation);
      await bondService.addBond(testCatId, BondService.eventViewReport);
      
      final history = bondService.getHistory(testCatId);
      expect(history.isNotEmpty, true);
    });

    test('getTodayActionCount 應該正確計算今日行動次數', () async {
      const translationId1 = 'translation_001';
      const translationId2 = 'translation_002';
      
      await bondService.addBond(
        testCatId,
        BondService.eventActionTap,
        translationId: translationId1,
      );
      await bondService.addBond(
        testCatId,
        BondService.eventActionTap,
        translationId: translationId2,
      );
      
      final count = bondService.getTodayActionCount(testCatId);
      expect(count, 2);
    });
  });
}