import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 評價引導服務
/// 情感分流版：不打擾使用者，引導滿意用戶前往商店評價
class ReviewService {
  static ReviewService? _instance;
  factory ReviewService() => _instance ??= ReviewService._internal();
  ReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  // Storage keys
  static const String _appFirstOpenDateKey = 'app_first_open_date';
  static const String _successfulInteractionCountKey = 'successful_interaction_count';
  static const String _lastReviewPromptDateKey = 'last_review_prompt_date';
  static const String _reviewPromptDisabledKey = 'review_prompt_disabled';
  static const String _hasRequestedStoreReviewKey = 'has_requested_store_review';
  static const String _userFeedbackKey = 'user_feedback';

  /// 重置單例（只用於測試）
  @visibleForTesting
  static void resetInstanceForTesting() {
    _instance = null;
  }

  /// 檢查是否應該顯示評價提示
  Future<bool> shouldShowReviewPrompt() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 使用者選擇「不要再提醒」→ 不顯示
    if (prefs.getBool(_reviewPromptDisabledKey) == true) return false;

    // 2. 已經請求過商店評價 → 不顯示
    if (prefs.getBool(_hasRequestedStoreReviewKey) == true) return false;

    // 3. 使用未滿 3 天 → 不顯示
    final firstOpenDate = prefs.getString(_appFirstOpenDateKey);
    if (firstOpenDate == null) {
      // 第一次記錄
      final now = DateTime.now();
      await prefs.setString(
        _appFirstOpenDateKey,
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
      );
      return false;
    }

    final firstOpen = DateTime.tryParse(firstOpenDate);
    if (firstOpen == null) return false;

    final daysSinceFirstOpen = DateTime.now().difference(firstOpen).inDays;
    if (daysSinceFirstOpen < 3) return false;

    // 4. 今天已經顯示過 → 不顯示
    final lastPromptDate = prefs.getString(_lastReviewPromptDateKey);
    if (lastPromptDate != null) {
      final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      if (lastPromptDate == today) return false;
    }

    // 5. 互動次數不足（需滿 5 次成功互動）→ 不顯示
    final interactionCount = prefs.getInt(_successfulInteractionCountKey) ?? 0;
    if (interactionCount < 5) return false;

    return true;
  }

  /// 記錄一次成功互動（翻譯/日記/任務/默契提升）
  Future<void> recordSuccessfulInteraction() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_successfulInteractionCountKey) ?? 0;
    await prefs.setInt(_successfulInteractionCountKey, count + 1);
  }

  /// 顯示評價提示（第一層情緒分流）
  /// 返回是否顯示成功
  Future<bool> showReviewPrompt() async {
    if (!await shouldShowReviewPrompt()) return false;

    // 記錄這次提示日期
    final prefs = await SharedPreferences.getInstance();
    final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
    await prefs.setString(_lastReviewPromptDateKey, today);

    return true;
  }

  /// 使用者選擇「不要再提醒」→ 永久停用
  Future<void> disableReviewPromptForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewPromptDisabledKey, true);
  }

  /// 標記已請求過商店評價
  Future<void> markStoreReviewRequested() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasRequestedStoreReviewKey, true);
  }

  /// 嘗試開啟商店評價頁面
  Future<bool> openStoreReview() async {
    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
        await markStoreReviewRequested();
        return true;
      }
      // 如果不行，嘗試直接開啟商店頁面
      await _inAppReview.openStoreListing();
      await markStoreReviewRequested();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 儲存內部回饋
  Future<void> saveUserFeedback(String feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final timestamp = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // 讀取現有回饋
    final existingFeedback = prefs.getStringList(_userFeedbackKey) ?? [];

    // 加入新回饋（格式：timestamp|feedback）
    existingFeedback.add('$timestamp|$feedback');

    // 只保留最近 20 筆
    if (existingFeedback.length > 20) {
      existingFeedback.removeRange(0, existingFeedback.length - 20);
    }

    await prefs.setStringList(_userFeedbackKey, existingFeedback);
  }

  /// 取得所有內部回饋（除錯用）
  Future<List<String>> getUserFeedbackList() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_userFeedbackKey) ?? [];
  }

  /// 取得使用者滿意度計數（除錯用）
  Future<Map<String, int>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'successful_interactions': prefs.getInt(_successfulInteractionCountKey) ?? 0,
      'review_disabled': (prefs.getBool(_reviewPromptDisabledKey) ?? false) ? 1 : 0,
      'store_review_requested': (prefs.getBool(_hasRequestedStoreReviewKey) ?? false) ? 1 : 0,
      'feedback_count': (prefs.getStringList(_userFeedbackKey) ?? []).length,
    };
  }
}
