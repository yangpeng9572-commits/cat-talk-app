import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/review_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReviewService 測試', () {
    late ReviewService reviewService;

    setUp(() async {
      // 重置 SharedPreferences
      SharedPreferences.setMockInitialValues({});
      // 重置單例
      ReviewService.resetInstanceForTesting();
      reviewService = ReviewService();
    });

    tearDown(() async {
      // 清理
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      ReviewService.resetInstanceForTesting();
    });

    group('1. 未滿 3 天不顯示', () {
      test('剛開始使用，不顯示', () async {
        // 設定今天為第一天
        final now = DateTime.now();
        final today = '${now.year}-${now.month}-${now.day}';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', today);

        // 互動次數夠多
        await prefs.setInt('successful_interaction_count', 10);

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });

      test('滿 3 天後，且互動次數夠，顯示', () async {
        // 直接測試日期計算邏輯（使用 zero-padded 格式）
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        // 使用 zero-padded 格式以確保 DateTime.parse 能正確解析
        final dateStr = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', dateStr);
        await prefs.setInt('successful_interaction_count', 10);

        // 驗證 shouldShowReviewPrompt 的關鍵邏輯
        final firstOpen = DateTime.tryParse(dateStr);
        expect(firstOpen, isNotNull);
        
        final daysSince = DateTime.now().difference(firstOpen!).inDays;
        expect(daysSince >= 3, true); // 核心假設
        
        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, true);
      });
    });

    group('2. 互動次數不足不顯示', () {
      test('使用超過 3 天，但互動次數只有 4 次，不顯示', () async {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final dateStr = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', dateStr);
        await prefs.setInt('successful_interaction_count', 4);

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });

      test('使用超過 3 天，且互動次數 5 次，顯示', () async {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final dateStr = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', dateStr);
        await prefs.setInt('successful_interaction_count', 5);

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, true);
      });
    });

    group('3. 同一天不重複顯示', () {
      test('今天已經顯示過，不顯示', () async {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final dateStr = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
        final today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', dateStr);
        await prefs.setInt('successful_interaction_count', 10);
        await prefs.setString('last_review_prompt_date', today);

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });
    });

    group('4. 選擇不要再提醒後不顯示', () {
      test('已停用，不顯示', () async {
        final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
        final dateStr = '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('app_first_open_date', dateStr);
        await prefs.setInt('successful_interaction_count', 10);
        await prefs.setBool('review_prompt_disabled', true);

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });
    });

    group('5. recordSuccessfulInteraction 正常運作', () {
      test('每次呼叫互動次數 +1', () async {
        await reviewService.recordSuccessfulInteraction();
        await reviewService.recordSuccessfulInteraction();
        await reviewService.recordSuccessfulInteraction();

        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('successful_interaction_count');
        expect(count, 3);
      });
    });

    group('6. disableReviewPromptForever 正常運作', () {
      test('呼叫後停用', () async {
        await reviewService.disableReviewPromptForever();

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });
    });

    group('7. 內部回饋保存', () {
      test('可以保存回饋', () async {
        await reviewService.saveUserFeedback('她的肚子叫是因為餓了，不是生氣');
        await reviewService.saveUserFeedback('今天翻譯結果蠻準的');

        final feedbacks = await reviewService.getUserFeedbackList();
        expect(feedbacks.length, 2);
        expect(feedbacks[0], contains('她的肚子叫是因為餓了'));
        expect(feedbacks[1], contains('今天翻譯結果蠻準的'));
      });

      test('回饋超過 20 筆只保留最近 20 筆', () async {
        for (int i = 0; i < 25; i++) {
          await reviewService.saveUserFeedback('回饋內容 $i');
        }

        final feedbacks = await reviewService.getUserFeedbackList();
        expect(feedbacks.length, 20);
        expect(feedbacks.last, contains('回饋內容 24'));
      });
    });

    group('8. markStoreReviewRequested', () {
      test('標記後不再顯示', () async {
        await reviewService.markStoreReviewRequested();

        final result = await reviewService.shouldShowReviewPrompt();
        expect(result, false);
      });
    });

    group('9. 統計功能', () {
      test('getStats 回傳正確統計', () async {
        await reviewService.recordSuccessfulInteraction();
        await reviewService.recordSuccessfulInteraction();
        await reviewService.recordSuccessfulInteraction();
        await reviewService.saveUserFeedback('測試回饋');

        final stats = await reviewService.getStats();
        expect(stats['successful_interactions'], 3);
        expect(stats['feedback_count'], 1);
        expect(stats['review_disabled'], 0);
        expect(stats['store_review_requested'], 0);
      });
    });
  });
}
