import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/services/push_notification_service.dart';
import 'package:cat_talk/models/translation_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PushNotificationService 測試', () {
    late PushNotificationService service;

    setUp(() {
      service = PushNotificationService();
    });

    test('getFirstTimeMessage 返回非空字串', () {
      final message = service.getFirstTimeMessage();
      expect(message, isNotEmpty);
      expect(message, contains('🐱'));
    });

    test('NotificationType 枚舉包含所有類型', () {
      expect(NotificationType.values.length, equals(5));
      expect(NotificationType.values, contains(NotificationType.catCall));
      expect(NotificationType.values, contains(NotificationType.dailyDiary));
      expect(NotificationType.values, contains(NotificationType.affectionate));
      expect(NotificationType.values, contains(NotificationType.companion));
      expect(NotificationType.values, contains(NotificationType.light));
    });

    test('PushNotificationService 可以正常初始化', () {
      expect(service, isNotNull);
    });
  });
}