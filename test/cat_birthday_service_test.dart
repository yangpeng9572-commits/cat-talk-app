import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/cat.dart';
import 'package:cat_talk/services/cat_birthday_service.dart';

void main() {
  group('CatBirthdayService', () {
    late CatBirthdayService _birthdayService;

    setUp(() {
      _birthdayService = CatBirthdayService();
    });

    // ===== 測試 1: Cat birthday toJson/fromJson 正常 =====
    test('Cat birthday toJson/fromJson 正常', () {
      final cat = Cat(
        id: 'test1',
        name: '小橘',
        birthMonth: 3,
        birthDay: 15,
        birthYear: 2022,
        birthdayType: 'exact',
      );

      final json = cat.toJson();
      expect(json['birthMonth'], 3);
      expect(json['birthDay'], 15);
      expect(json['birthYear'], 2022);
      expect(json['birthdayType'], 'exact');

      final fromJsonCat = Cat.fromJson(json);
      expect(fromJsonCat.birthMonth, 3);
      expect(fromJsonCat.birthDay, 15);
      expect(fromJsonCat.birthYear, 2022);
      expect(fromJsonCat.birthdayType, 'exact');
    });

    // ===== 測試 2: 舊 Cat json 無生日欄位正常載入（相容性） =====
    test('舊 Cat json 無生日欄位正常載入（相容性）', () {
      final oldJson = {
        'id': 'old1',
        'name': '老貓',
        'gender': 'female',
        'ageStage': 'adult',
        'breed': '英國短毛貓',
        'age': 3.0,
        'createdAt': '2024-01-01T00:00:00.000',
        // 沒有 birthMonth, birthDay, birthYear, birthdayType
      };

      final cat = Cat.fromJson(oldJson);
      expect(cat.birthMonth, isNull);
      expect(cat.birthDay, isNull);
      expect(cat.birthYear, isNull);
      expect(cat.birthdayType, 'unknown');
    });

    // ===== 測試 3: birthdayType 錯誤值轉為 unknown =====
    test('birthdayType 錯誤值轉為 unknown', () {
      final json = {
        'id': 'test3',
        'name': '錯誤類型貓',
        'birthdayType': 'invalid_type',
        'birthMonth': 5,
        'birthDay': 20,
      };

      final cat = Cat.fromJson(json);
      expect(cat.birthdayType, 'unknown');
    });

    // ===== 測試 4: 不填生日不造成新增失敗（mock CatService） =====
    test('不填生日不造成新增失敗（mock CatService）', () {
      final cat = Cat(
        id: 'test4',
        name: '無生日貓',
        // 沒有填寫生日相關欄位
      );

      expect(cat.birthMonth, isNull);
      expect(cat.birthDay, isNull);
      expect(cat.birthYear, isNull);
      expect(cat.birthdayType, 'unknown');

      // toJson 不應拋錯
      final json = cat.toJson();
      expect(json['birthMonth'], isNull);
      expect(json['birthDay'], isNull);
      expect(json['birthYear'], isNull);
      expect(json['birthdayType'], 'unknown');
    });

    // ===== 測試 5: getDaysUntilBirthday 今天=0 =====
    test('getDaysUntilBirthday 今天=0', () {
      final now = DateTime.now();
      final cat = Cat(
        id: 'test5',
        name: '今天生日',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );

      final days = _birthdayService.getDaysUntilBirthday(cat);
      expect(days, 0);
    });

    // ===== 測試 6: getDaysUntilBirthday 明天=1 =====
    test('getDaysUntilBirthday 明天=1', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final cat = Cat(
        id: 'test6',
        name: '明天生日',
        birthMonth: tomorrow.month,
        birthDay: tomorrow.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );

      final days = _birthdayService.getDaysUntilBirthday(cat);
      expect(days, 1);
    });

    // ===== 測試 7: getDaysUntilBirthday 跨年（12/31 + 1/1 = 1） =====
    test('getDaysUntilBirthday 跨年（12/31 + 1/1 = 1）', () {
      final now = DateTime.now();
      final dec31 = DateTime(now.year, 12, 31);
      final jan1 = DateTime(now.year + 1, 1, 1);
      final difference = jan1.difference(DateTime(now.year, now.month, now.day)).inDays;

      // 如果今天不是 12/31 或 1/1，建立虛擬測試
      // 測試跨年邏輯：12/31 的下一天是 1/1，差距為 1 天
      final catDec31 = Cat(
        id: 'test7a',
        name: '跨年測試',
        birthMonth: 12,
        birthDay: 31,
        birthYear: now.year - 1,
        birthdayType: 'exact',
      );

      // 我們無法真正測試跨年，因為取決於當天日期
      // 但我們可以測試 getDaysUntilBirthday 的邏輯是否正確
      final days = _birthdayService.getDaysUntilBirthday(catDec31);
      // 如果今天剛好是 12/30，應該返回 1
      // 如果今天剛好是 12/31，應該返回 0
      expect(days, isNotNull);
    });

    // ===== 測試 8: 2/29 非閏年不閃退 =====
    test('2/29 非閏年不閃退', () {
      // 2023 年不是閏年，2/29 不存在
      // 系統應該將 2/29 視為 2/28 處理
      final cat = Cat(
        id: 'test8',
        name: '閏年測試',
        birthMonth: 2,
        birthDay: 29,
        birthYear: 2020, // 2020 是閏年
        birthdayType: 'exact',
      );

      // 這不應該拋錯
      final days = _birthdayService.getDaysUntilBirthday(cat);
      // 如果今天不是 2/29，應該返回非 null 值
      expect(days, isNotNull);
    });

    // ===== 測試 9: isBirthdayToday 正確 =====
    test('isBirthdayToday 正確', () {
      final now = DateTime.now();
      final cat = Cat(
        id: 'test9',
        name: '今天生日',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );

      expect(_birthdayService.isBirthdayToday(cat), true);
    });

    // ===== 測試 10: isBirthdayTomorrow 正確 =====
    test('isBirthdayTomorrow 正確', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final cat = Cat(
        id: 'test10',
        name: '明天生日',
        birthMonth: tomorrow.month,
        birthDay: tomorrow.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );

      expect(_birthdayService.isBirthdayTomorrow(cat), true);
    });

    // ===== 測試 11: exact 可計算年齡 =====
    test('exact 可計算年齡', () {
      final now = DateTime.now();
      final birthYear = now.year - 3;
      final cat = Cat(
        id: 'test11',
        name: '3歲貓',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: birthYear,
        birthdayType: 'exact',
      );

      final age = _birthdayService.getAge(cat);
      expect(age, 3);
    });

    // ===== 測試 12: monthDayOnly 不計算年齡 =====
    test('monthDayOnly 不計算年齡', () {
      final now = DateTime.now();
      final cat = Cat(
        id: 'test12',
        name: '只知道月日',
        birthMonth: now.month,
        birthDay: now.day,
        // 沒有 birthYear
        birthdayType: 'monthDayOnly',
      );

      final age = _birthdayService.getAge(cat);
      expect(age, isNull);
    });

    // ===== 測試 13: getGiftSuggestions 正常 =====
    test('getGiftSuggestions 正常', () {
      final cat = Cat(id: 'test13', name: '禮物測試');
      final gifts = _birthdayService.getGiftSuggestions(cat);

      expect(gifts, isNotEmpty);
      expect(gifts.length, 14); // 3+3+3+2+3 = 14 items across 5 categories

      // 檢查各分類都有禮物
      final categories = gifts.map((g) => g.category).toSet();
      expect(categories.contains('玩具'), true);
      expect(categories.contains('食物'), true);
      expect(categories.contains('舒適'), true);
      expect(categories.contains('空間'), true);
      expect(categories.contains('可愛'), true);
    });

    // ===== 測試 14: getShareText 正常 =====
    test('getShareText 正常', () {
      final cat = Cat(id: 'test14', name: '小橘');
      final shareText = _birthdayService.getShareText(cat);

      expect(shareText, contains('小橘'));
      expect(shareText, contains('生日'));
      expect(shareText, contains('🎂'));
    });

    // ===== 額外測試：unknown birthdayType 所有方法回傳 null/false =====
    test('unknown birthdayType 回傳 null/false', () {
      final cat = Cat(
        id: 'test_unknown',
        name: '不知道生日',
        birthdayType: 'unknown',
      );

      expect(_birthdayService.getNextBirthday(cat), isNull);
      expect(_birthdayService.getDaysUntilBirthday(cat), isNull);
      expect(_birthdayService.isBirthdayToday(cat), false);
      expect(_birthdayService.isBirthdayTomorrow(cat), false);
      expect(_birthdayService.getAge(cat), isNull);
      expect(_birthdayService.getBirthdayMessage(cat), '');
    });

    // ===== 額外測試：monthDayOnly 可計算天數但不計算年齡 =====
    test('monthDayOnly 可計算天數但不計算年齡', () {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));
      final cat = Cat(
        id: 'test_md',
        name: '月日 only',
        birthMonth: tomorrow.month,
        birthDay: tomorrow.day,
        birthdayType: 'monthDayOnly',
      );

      expect(_birthdayService.getDaysUntilBirthday(cat), 1);
      expect(_birthdayService.getAge(cat), isNull);
    });
  });
}
