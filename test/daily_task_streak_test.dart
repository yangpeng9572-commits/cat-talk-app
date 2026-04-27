import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/daily_task.dart';
import 'package:cat_talk/models/streak.dart';

void main() {
  group('DailyTask Model 測試', () {
    test('应该能正确计算进度', () {
      final task = DailyTask(
        id: 'test_1',
        title: '测试任务',
        description: '描述',
        type: TaskType.translate_meow,
        targetCount: 5,
        currentCount: 2,
        rewardExp: 10,
        date: DateTime.now(),
      );

      expect(task.progress, 0.4);
      expect(task.progressText, '2 / 5');
      expect(task.isAchieved, false);
    });

    test('已完成任务进度应为1.0', () {
      final task = DailyTask(
        id: 'test_2',
        title: '测试任务',
        description: '描述',
        type: TaskType.translate_meow,
        targetCount: 3,
        currentCount: 3,
        rewardExp: 10,
        date: DateTime.now(),
        isCompleted: true,
      );

      expect(task.progress, 1.0);
      expect(task.isAchieved, true);
      expect(task.isCompleted, true);
    });

    test('应该能正确转换为 JSON', () {
      final now = DateTime.now();
      final task = DailyTask(
        id: 'test_3',
        title: '测试任务',
        description: '描述',
        type: TaskType.give_feedback,
        targetCount: 2,
        currentCount: 1,
        rewardExp: 5,
        date: now,
      );

      final json = task.toJson();
      final fromJson = DailyTask.fromJson(json);

      expect(fromJson.id, 'test_3');
      expect(fromJson.type, TaskType.give_feedback);
      expect(fromJson.targetCount, 2);
      expect(fromJson.currentCount, 1);
    });

    test('copyWith 应该能更新字段', () {
      final task = DailyTask(
        id: 'test_4',
        title: '原始标题',
        description: '描述',
        type: TaskType.translate_meow,
        targetCount: 1,
        rewardExp: 10,
        date: DateTime.now(),
      );

      final updated = task.copyWith(
        currentCount: 1,
        isCompleted: true,
      );

      expect(updated.currentCount, 1);
      expect(updated.isCompleted, true);
      expect(updated.title, '原始标题'); // 未更新的字段保持不变
    });
  });

  group('TaskType Extension 測試', () {
    test('emoji 应该正确返回', () {
      expect(TaskType.translate_meow.emoji, '🎤');
      expect(TaskType.view_daily_report.emoji, '📊');
      expect(TaskType.give_feedback.emoji, '👍');
      expect(TaskType.add_cat_note.emoji, '📝');
      expect(TaskType.play_with_cat.emoji, '🎾');
    });

    test('label 应该正确返回', () {
      expect(TaskType.translate_meow.label, '翻譯');
      expect(TaskType.view_daily_report.label, '報告');
      expect(TaskType.give_feedback.label, '回饋');
      expect(TaskType.add_cat_note.label, '備註');
      expect(TaskType.play_with_cat.label, '玩耍');
    });
  });

  group('Streak Model 測試', () {
    test('新用户应该是0连击', () {
      final streak = Streak();
      expect(streak.currentStreak, 0);
      expect(streak.longestStreak, 0);
      expect(streak.totalActiveDays, 0);
      expect(streak.totalExp, 0);
    });

    test('等级应该根据 exp 正确计算', () {
      final streak = Streak(totalExp: 0);
      expect(streak.level, 1);

      final streak2 = Streak(totalExp: 100);
      expect(streak2.level, 2);

      final streak3 = Streak(totalExp: 250);
      expect(streak3.level, 3);
    });

    test('expToNextLevel 应该正确计算', () {
      final streak = Streak(totalExp: 30);
      expect(streak.expToNextLevel, 70);

      final streak2 = Streak(totalExp: 100);
      expect(streak2.expToNextLevel, 100);

      final streak3 = Streak(totalExp: 150);
      expect(streak3.expToNextLevel, 50);
    });

    test('levelProgress 应该正确计算', () {
      final streak = Streak(totalExp: 50);
      expect(streak.levelProgress, 0.5);

      final streak2 = Streak(totalExp: 75);
      expect(streak2.levelProgress, 0.75);
    });

    test('等级标题应该根据连击正确返回', () {
      expect(Streak(currentStreak: 0).levelTitle, '見習貓奴');
      expect(Streak(currentStreak: 1).levelTitle, '新手貓奴');
      expect(Streak(currentStreak: 3).levelTitle, '進階貓奴');
      expect(Streak(currentStreak: 7).levelTitle, '忠誠貓奴');
      expect(Streak(currentStreak: 14).levelTitle, '資深貓奴');
      expect(Streak(currentStreak: 30).levelTitle, '傳說貓奴');
    });

    test('应该能正确转换为 JSON', () {
      final now = DateTime.now();
      final streak = Streak(
        currentStreak: 5,
        longestStreak: 10,
        lastActiveDate: now,
        totalActiveDays: 20,
        totalExp: 150,
      );

      final json = streak.toJson();
      final fromJson = Streak.fromJson(json);

      expect(fromJson.currentStreak, 5);
      expect(fromJson.longestStreak, 10);
      expect(fromJson.totalActiveDays, 20);
      expect(fromJson.totalExp, 150);
    });

    test('copyWith 应该能更新字段', () {
      final streak = Streak(currentStreak: 3, totalExp: 50);
      final updated = streak.copyWith(
        currentStreak: 4,
        totalExp: 60,
      );

      expect(updated.currentStreak, 4);
      expect(updated.totalExp, 60);
      expect(updated.longestStreak, 0); // 未更新的保持默认值
    });
  });

  group('Streak 日期判断测试', () {
    test('今天活跃应该返回 true', () {
      final now = DateTime.now();
      final streak = Streak(lastActiveDate: now);
      expect(streak.isActiveToday, true);
    });

    test('昨天活跃应该返回 true for wasActiveYesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final streak = Streak(lastActiveDate: yesterday);
      expect(streak.wasActiveYesterday, true);
    });

    test('非连续日期应该返回 false for wasActiveYesterday', () {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final streak = Streak(lastActiveDate: twoDaysAgo);
      expect(streak.wasActiveYesterday, false);
    });
  });
}
