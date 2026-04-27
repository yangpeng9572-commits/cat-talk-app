import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task.dart';

/// 每日任務服務
class DailyTaskService {
  static const String _tasksKey = 'daily_tasks';
  static const String _lastResetKey = 'last_task_reset';

  final SharedPreferences _prefs;

  DailyTaskService(this._prefs);

  /// 取得今日任務
  List<DailyTask> getTodayTasks() {
    final todayStr = _getTodayStr();
    final lastReset = _prefs.getString(_lastResetKey);

    // 如果不是今天，重置任務
    if (lastReset != todayStr) {
      _resetDailyTasks();
    }

    final tasksJson = _prefs.getString(_tasksKey);
    if (tasksJson == null) {
      return _generateTodayTasks();
    }

    final List<dynamic> tasksList = jsonDecode(tasksJson);
    return tasksList.map((json) => DailyTask.fromJson(json)).toList();
  }

  /// 生成今日任務
  List<DailyTask> _generateTodayTasks() {
    final today = DateTime.now();
    final todayStr = _getTodayStr();

    final tasks = [
      DailyTask(
        id: '${todayStr}_translate',
        title: '錄下貓叫聲',
        description: '錄下 1 次貓叫聲，翻譯看看牠想說什麼',
        type: TaskType.translate_meow,
        targetCount: 1,
        rewardExp: 10,
        date: today,
      ),
      DailyTask(
        id: '${todayStr}_report',
        title: '查看每日報告',
        description: '看看你家貓咪今天的情緒怎麼樣',
        type: TaskType.view_daily_report,
        targetCount: 1,
        rewardExp: 5,
        date: today,
      ),
      DailyTask(
        id: '${todayStr}_feedback',
        title: '給予回饋',
        description: '幫翻譯結果回饋，讓我更懂你家貓',
        type: TaskType.give_feedback,
        targetCount: 1,
        rewardExp: 5,
        date: today,
      ),
    ];

    _saveTasks(tasks);
    return tasks;
  }

  /// 更新任務進度
  Future<DailyTask?> updateTaskProgress(TaskType type, {int delta = 1}) async {
    final tasks = getTodayTasks();
    final taskIndex = tasks.indexWhere((t) => t.type == type);

    if (taskIndex == -1) return null;

    final task = tasks[taskIndex];
    if (task.isCompleted) return task; // 已經完成，不再更新

    final newCount = task.currentCount + delta;
    final updatedTask = task.copyWith(
      currentCount: newCount,
      isCompleted: newCount >= task.targetCount,
      completedAt: newCount >= task.targetCount ? DateTime.now() : null,
    );

    tasks[taskIndex] = updatedTask;
    _saveTasks(tasks);

    return updatedTask;
  }

  /// 完成任務
  Future<DailyTask?> completeTask(String taskId) async {
    final tasks = getTodayTasks();
    final taskIndex = tasks.indexWhere((t) => t.id == taskId);

    if (taskIndex == -1) return null;

    final task = tasks[taskIndex];
    final updatedTask = task.copyWith(
      isCompleted: true,
      currentCount: task.targetCount,
      completedAt: DateTime.now(),
    );

    tasks[taskIndex] = updatedTask;
    _saveTasks(tasks);

    return updatedTask;
  }

  /// 取得任務完成數量
  int getCompletedCount() {
    final tasks = getTodayTasks();
    return tasks.where((t) => t.isCompleted).length;
  }

  /// 取得今日總獎勵 exp
  int getTodayTotalExp() {
    final tasks = getTodayTasks();
    return tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, t) => sum + t.rewardExp);
  }

  /// 重置每日任務（如果需要）
  void _resetDailyTasks() {
    _prefs.setString(_lastResetKey, _getTodayStr());
    _generateTodayTasks();
  }

  /// 儲存任務
  void _saveTasks(List<DailyTask> tasks) {
    final tasksJson = tasks.map((t) => t.toJson()).toList();
    _prefs.setString(_tasksKey, jsonEncode(tasksJson));
  }

  /// 取得今天日期字串
  String _getTodayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
