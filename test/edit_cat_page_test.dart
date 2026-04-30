import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/models/cat.dart';
import 'package:cat_talk/services/cat_service.dart';

void main() {
  group('EditCatPage - Cat copyWith and birthdayType logic', () {
    late SharedPreferences prefs;
    late CatService catService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      catService = CatService(prefs);
    });

    test('copyWith preserves id and updates name', () {
      final cat = Cat(
        id: 'test-id-123',
        name: '小花',
        breed: '英國短毛貓',
        gender: 'female',
        age: 2.0,
        ageStage: 'adult',
        birthMonth: 3,
        birthDay: 15,
        birthYear: 2022,
        birthdayType: 'exact',
      );

      final updated = cat.copyWith(name: '小花了');

      expect(updated.id, 'test-id-123'); // id unchanged
      expect(updated.name, '小花了');
      expect(updated.breed, '英國短毛貓');
      expect(updated.gender, 'female');
      expect(updated.birthMonth, 3);
    });

    test('updateCat with unknown birthdayType: id preserved, null fields explicit', () async {
      // Using direct Cat() construction (as in EditCatPage) to properly set null fields
      final cat = Cat(
        id: 'unknown-bday-test',
        name: '未知生日貓',
        birthMonth: 6,
        birthDay: 1,
        birthYear: 2021,
        birthdayType: 'exact',
      );

      await catService.addCat(cat);

      // Simulate EditCatPage behavior: create new Cat with explicit state
      final updated = Cat(
        id: cat.id, // preserve id
        name: cat.name,
        breed: cat.breed,
        gender: cat.gender,
        age: cat.age,
        ageStage: cat.ageStage,
        avatarPath: cat.avatarPath,
        birthMonth: null, // explicitly null for unknown
        birthDay: null,
        birthYear: null,
        birthdayType: 'unknown',
      );

      await catService.updateCat(updated);

      final retrieved = catService.getCatById('unknown-bday-test');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'unknown-bday-test');
      expect(retrieved.birthdayType, 'unknown');
      expect(retrieved.birthMonth, null);
      expect(retrieved.birthDay, null);
      expect(retrieved.birthYear, null);
      expect(retrieved.name, '未知生日貓');
    });

    test('updateCat with adoptionDay: id preserved, null fields explicit', () async {
      final cat = Cat(
        id: 'adoption-day-test',
        name: '領養日貓',
        birthMonth: 6,
        birthDay: 1,
        birthYear: 2021,
        birthdayType: 'exact',
      );

      await catService.addCat(cat);

      final updated = Cat(
        id: cat.id,
        name: cat.name,
        breed: cat.breed,
        gender: cat.gender,
        age: cat.age,
        ageStage: cat.ageStage,
        avatarPath: cat.avatarPath,
        birthMonth: null,
        birthDay: null,
        birthYear: null,
        birthdayType: 'adoptionDay',
      );

      await catService.updateCat(updated);

      final retrieved = catService.getCatById('adoption-day-test');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'adoption-day-test');
      expect(retrieved.birthdayType, 'adoptionDay');
      expect(retrieved.birthMonth, null);
    });

    test('copyWith with birthdayType=monthDayOnly keeps month and day only', () {
      final cat = Cat(
        id: 'test-id-mdo',
        name: '小橘',
        birthdayType: 'exact',
      );

      final updated = cat.copyWith(
        birthMonth: 7,
        birthDay: 4,
        birthdayType: 'monthDayOnly',
      );

      expect(updated.birthMonth, 7);
      expect(updated.birthDay, 4);
      expect(updated.birthYear, null);
      expect(updated.birthdayType, 'monthDayOnly');
    });

    test('updateCat saves and retrieves updated cat', () async {
      final cat = Cat(
        id: 'update-test-id',
        name: '原始名字',
        breed: '波斯貓',
        gender: 'male',
        age: 3.0,
        ageStage: 'adult',
        birthMonth: 5,
        birthDay: 20,
        birthYear: 2021,
        birthdayType: 'exact',
      );

      await catService.addCat(cat);

      final updated = cat.copyWith(
        name: '新名字',
        birthMonth: 12,
        birthDay: 25,
        birthYear: 2020,
        birthdayType: 'exact',
      );

      await catService.updateCat(updated);

      final retrieved = catService.getCatById('update-test-id');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, '新名字');
      expect(retrieved.birthMonth, 12);
      expect(retrieved.birthDay, 25);
      expect(retrieved.birthYear, 2020);
      expect(retrieved.birthdayType, 'exact');
    });

    test('updateCat preserves other fields when editing only name', () async {
      final cat = Cat(
        id: 'partial-update-test',
        name: '咪咪',
        breed: '混種貓',
        gender: 'female',
        age: 1.5,
        ageStage: 'junior',
        birthMonth: 8,
        birthDay: 10,
        birthdayType: 'monthDayOnly',
      );

      await catService.addCat(cat);

      final updated = cat.copyWith(name: '咪咪兒');

      await catService.updateCat(updated);

      final retrieved = catService.getCatById('partial-update-test');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, '咪咪兒');
      expect(retrieved.breed, '混種貓');
      expect(retrieved.gender, 'female');
      expect(retrieved.age, 1.5);
      expect(retrieved.birthMonth, 8);
      expect(retrieved.birthDay, 10);
      expect(retrieved.birthdayType, 'monthDayOnly');
    });

    test('Cat.fromJson handles all valid birthdayType values', () {
      final types = ['exact', 'monthDayOnly', 'adoptionDay', 'unknown'];

      for (final type in types) {
        final json = {
          'id': 'json-test',
          'name': 'JSON貓',
          'birthdayType': type,
          'birthMonth': type == 'exact' ? 4 : (type == 'monthDayOnly' ? 4 : null),
          'birthDay': type == 'exact' ? 10 : (type == 'monthDayOnly' ? 10 : null),
          'birthYear': type == 'exact' ? 2020 : null,
        };

        final cat = Cat.fromJson(json);
        expect(cat.birthdayType, type, reason: 'birthdayType $type should parse correctly');
      }
    });

    test('Cat.fromJson converts invalid birthdayType to unknown', () {
      final json = {
        'id': 'bad-type-test',
        'name': '壞類型貓',
        'birthdayType': 'full', // invalid
      };

      final cat = Cat.fromJson(json);
      expect(cat.birthdayType, 'unknown');
    });
  });
}