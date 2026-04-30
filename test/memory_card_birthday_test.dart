import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/models/cat.dart';
import 'package:cat_talk/services/cat_birthday_service.dart';

void main() {
  group('first_birthday 回憶卡解鎖邏輯', () {
    late CatBirthdayService birthdayService;

    setUp(() {
      birthdayService = CatBirthdayService();
    });

    test('生日當天 + birthdayType != unknown → isBirthdayToday = true', () {
      final now = DateTime.now();
      final cat = Cat(
        id: 'cat1',
        name: '小橘',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );

      expect(birthdayService.isBirthdayToday(cat), true);
    });

    test('birthdayType == unknown → isBirthdayToday = false', () {
      final cat = Cat(
        id: 'cat_unknown',
        name: '小黑',
        birthdayType: 'unknown',
      );

      expect(birthdayService.isBirthdayToday(cat), false);
    });

    test('monthDayOnly 生日當天 → isBirthdayToday = true', () {
      final now = DateTime.now();
      final cat = Cat(
        id: 'cat_month_day',
        name: '小花的',
        birthMonth: now.month,
        birthDay: now.day,
        birthdayType: 'monthDayOnly',
      );

      expect(birthdayService.isBirthdayToday(cat), true);
    });

    test('adoptionDay 無 adoptionDate → isBirthdayToday = false', () {
      final cat = Cat(
        id: 'cat_adoption',
        name: '小黑的',
        birthdayType: 'adoptionDay',
      );

      expect(birthdayService.isBirthdayToday(cat), false);
    });

    test('不同貓咪各自獨立解鎖 first_birthday', () {
      final now = DateTime.now();
      final cat1 = Cat(
        id: 'cat_a',
        name: '貓A',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: now.year - 2,
        birthdayType: 'exact',
      );
      final cat2 = Cat(
        id: 'cat_b',
        name: '貓B',
        birthMonth: now.month,
        birthDay: now.day,
        birthYear: now.year - 1,
        birthdayType: 'exact',
      );

      // 兩隻貓都在今天生日
      expect(birthdayService.isBirthdayToday(cat1), true);
      expect(birthdayService.isBirthdayToday(cat2), true);
    });

    test('生日卡片不顯示 unknown 類型', () {
      final cat = Cat(
        id: 'cat_no_birthday',
        name: '沒有生日的貓',
        birthdayType: 'unknown',
      );

      final days = birthdayService.getDaysUntilBirthday(cat);
      expect(days, isNull);
    });

    test('adoptionDay 回傳 null，birthday card 不顯示', () {
      final cat = Cat(
        id: 'cat_adoption_day',
        name: '領養日貓',
        birthdayType: 'adoptionDay',
      );

      final days = birthdayService.getDaysUntilBirthday(cat);
      expect(days, isNull);
    });
  });
}
