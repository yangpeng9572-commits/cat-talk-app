import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_task.dart';
import 'task_companion_service.dart';

/// 每日任務服務
class DailyTaskService {
  static const String _tasksKey = 'daily_tasks';
  static const String _lastResetKey = 'last_task_reset';

  final SharedPreferences _prefs;
  final TaskCompanionService _companion = TaskCompanionService();

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

  /// 生成今日任務（使用陪伴型文案）
  List<DailyTask> _generateTodayTasks() {
    final today = DateTime.now();
    final todayStr = _getTodayStr();

    // 生成新版的每日任務：報告、拍照、小世界互動
    // translate_meow 和 give_feedback 已停用，等待產品調整
    final tasks = [
      DailyTask(
        id: '${todayStr}_report',
        title: _companion.getTitle(TaskType.view_daily_report),
        description: _companion.getDescription(TaskType.view_daily_report),
        type: TaskType.view_daily_report,
        targetCount: 1,
        rewardExp: 5,
        date: today,
      ),
      DailyTask(
        id: '${todayStr}_pose_photo',
        title: _companion.getTitle(TaskType.pose_photo),
        description: _companion.getDescription(TaskType.pose_photo),
        type: TaskType.pose_photo,
        targetCount: 1,
        rewardExp: 5,
        date: today,
      ),
      DailyTask(
        id: '${todayStr}_cat_world',
        title: _companion.getTitle(TaskType.cat_world_interact),
        description: _companion.getDescription(TaskType.cat_world_interact),
        type: TaskType.cat_world_interact,
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

  /// 檢查是否所有任務都完成
  bool isAllCompleted() {
    final tasks = getTodayTasks();
    return tasks.isNotEmpty && tasks.every((t) => t.isCompleted);
  }

  /// 取得今日總默契值（不是 exp）
  int getTodayTotalBond() {
    final tasks = getTodayTasks();
    return tasks
        .where((t) => t.isCompleted)
        .fold(0, (sum, t) => sum + t.rewardExp);
  }

  /// 取得任務完成後的回饋訊息
  String getTaskCompletionMessage(TaskType type) {
    return _companion.getCompletionMessage(type);
  }

  /// 取得全部完成時的回饋訊息
  String getAllTasksCompletedMessage() {
    return _companion.getAllCompletedMessage();
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
