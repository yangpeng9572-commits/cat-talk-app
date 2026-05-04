import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/daily_task.dart';
import 'package:cat_talk/services/task_companion_service.dart';

void main() {
  late TaskCompanionService companion;

  setUp(() {
    companion = TaskCompanionService();
  });

  group('TaskCompanionService 測試', () {
    test('每種 TaskType 都能取得正確標題', () {
      for (final type in TaskType.values) {
        final title = companion.getTitle(type);
        expect(title, isNotEmpty);
        expect(title, isNot(contains('exp')));
        expect(title, isNot(contains('任務達成')));
      }
    });

    test('每種 TaskType 都能取得正確描述', () {
      for (final type in TaskType.values) {
        final desc = companion.getDescription(type);
        expect(desc, isNotEmpty);
        expect(desc, isNot(contains('打卡')));
        expect(desc, isNot(contains('遊戲')));
      }
    });

    test('每種 TaskType 都有對應的完成訊息', () {
      for (final type in TaskType.values) {
        final msg = companion.getCompletionMessage(type);
        expect(msg, isNotEmpty);
        // 每種任務都應該有 emoji
        final hasEmoji = msg.contains(RegExp(r'[🐾💕✨🌱🐱]'));
        expect(hasEmoji, isTrue, reason: '${type.name} message should contain an emoji');
      }
    });

    test('翻譯任務的陪伴文案內容正確', () {
      expect(companion.getTitle(TaskType.translate_meow), '今天聽她說一次話');
      expect(companion.getDescription(TaskType.translate_meow), contains('錄下'));
      expect(companion.getCompletionMessage(TaskType.translate_meow), contains('聽見'));
    });

    test('報告任務的陪伴文案內容正確', () {
      expect(companion.getTitle(TaskType.view_daily_report), '看看她今天的小心情');
      expect(companion.getDescription(TaskType.view_daily_report), contains('小日記'));
      expect(companion.getCompletionMessage(TaskType.view_daily_report), contains('了解'));
    });

    test('回饋任務的陪伴文案內容正確', () {
      expect(companion.getTitle(TaskType.give_feedback), '回應她一次小情緒');
      expect(companion.getDescription(TaskType.give_feedback), contains('記住'));
      expect(companion.getCompletionMessage(TaskType.give_feedback), contains('習慣'));
    });

    test('玩耍任務的陪伴文案內容正確', () {
      expect(companion.getTitle(TaskType.play_with_cat), '陪她玩一下');
      expect(companion.getDescription(TaskType.play_with_cat), contains('默契'));
      expect(companion.getCompletionMessage(TaskType.play_with_cat), contains('陪伴'));
    });

    test('備註任務的陪伴文案內容正確', () {
      expect(companion.getTitle(TaskType.add_cat_note), '記下她的小習慣');
      expect(companion.getDescription(TaskType.add_cat_note), contains('留下')); // 留下來
      expect(companion.getCompletionMessage(TaskType.add_cat_note), contains('保存'));
    });

    test('getAllCompletedMessage 包含默契關鍵字', () {
      final msg = companion.getAllCompletedMessage();
      expect(msg, isNotEmpty);
      expect(msg, contains('默契'));
      expect(msg, contains('✨'));
    });

    test('getCardTitle 不使用任務詞彙', () {
      final title = companion.getCardTitle();
      expect(title, isNot(contains('任務')));
      expect(title, isNot(contains('打卡')));
    });

    test('getCardSubtitle 使用陪伴語言', () {
      final subtitle = companion.getCardSubtitle();
      expect(subtitle, contains('陪伴'));
      expect(subtitle, contains('默契'));
    });

    test('getBondRewardText 使用默契而非 exp', () {
      final reward = companion.getBondRewardText(5);
      expect(reward, '默契 +5');
      expect(reward, isNot(contains('exp')));
    });

    test('getEmptyMessage 不使用遊戲語言', () {
      final msg = companion.getEmptyMessage();
      expect(msg, isNot(contains('任務')));
      expect(msg, contains('🐾'));
    });

    test('getAllDoneMessage 使用陪伴語言', () {
      final msg = companion.getAllDoneMessage();
      expect(msg, contains('陪伴'));
      expect(msg, contains('默契'));
      expect(msg, contains('💕'));
    });
  });
}
