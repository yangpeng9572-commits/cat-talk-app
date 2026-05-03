import '../models/daily_task.dart';

/// 任務陪伴文案服務
/// 將任務從「遊戲任務」轉化為「陪伴體驗」
class TaskCompanionService {
  static final TaskCompanionService _instance = TaskCompanionService._internal();
  factory TaskCompanionService() => _instance;
  TaskCompanionService._internal();

  /// 取得任務標題（陪伴型）
  String getTitle(TaskType type) {
    switch (type) {
      case TaskType.translate_meow:
        return '今天聽她說一次話'; // 已停用，僅保留結構相容性
      case TaskType.view_daily_report:
        return '看看她今天的小心情';
      case TaskType.give_feedback:
        return '回應她一次小情緒'; // 已停用，僅保留結構相容性
      case TaskType.play_with_cat:
        return '陪她玩一下';
      case TaskType.add_cat_note:
        return '記下她的小習慣';
      case TaskType.pose_photo:
        return '今天幫她拍照或記錄';
      case TaskType.cat_world_interact:
        return '在小世界完成一次動作';
    }
  }

  /// 取得任務描述（陪伴型）
  String getDescription(TaskType type) {
    switch (type) {
      case TaskType.translate_meow:
        return '錄下一聲喵，看看她今天想表達什麼'; // 已停用
      case TaskType.view_daily_report:
        return '讀一讀今天的小日記，更了解她一點';
      case TaskType.give_feedback:
        return '告訴我這次像不像她，我會慢慢記住'; // 已停用
      case TaskType.play_with_cat:
        return '用幾分鐘陪伴，累積你們的小默契';
      case TaskType.add_cat_note:
        return '把她可愛或特別的反應留下來';
      case TaskType.pose_photo:
        return '拍張照片或寫下今天的小日記';
      case TaskType.cat_world_interact:
        return '在小世界裡和她互動一下';
    }
  }

  /// 取得任務完成後的短提示
  String getCompletionMessage(TaskType type) {
    switch (type) {
      case TaskType.translate_meow:
        return '你今天有聽見她的聲音了 🐾';
      case TaskType.view_daily_report:
        return '你更了解她今天的小心情了 💕';
      case TaskType.give_feedback:
        return '她的習慣又被你記住一點了 🌱';
      case TaskType.play_with_cat:
        return '今天的陪伴讓她更安心了 ✨';
      case TaskType.add_cat_note:
        return '她的小習慣被好好保存了 💕';
      case TaskType.pose_photo:
        return '這一刻被好好記錄下來了 🐾';
      case TaskType.cat_world_interact:
        return '她的小世界又溫暖了一點 🏡';
    }
  }

  /// 取得全部任務完成時的回饋
  String getAllCompletedMessage() {
    return '今天的陪伴完成了，你們又更有默契了 ✨';
  }

  /// 取得卡片標題
  String getCardTitle() {
    return '今天陪她的小事';
  }

  /// 取得卡片副標
  String getCardSubtitle() {
    return '完成一點點陪伴，累積你們的默契';
  }

  /// 取得空的時候顯示的文字
  String getEmptyMessage() {
    return '今天還沒有小事要做，稍等一下我幫你準備 🐾';
  }

  /// 取得全部完成後顯示的文字
  String getAllDoneMessage() {
    return '今天的陪伴完成了，你們更有默契了，明天再一起更懂她 💕';
  }

  /// 取得默契獎勵文字（不用 exp）
  String getBondRewardText(int bondScore) {
    return '默契 +$bondScore';
  }
}
