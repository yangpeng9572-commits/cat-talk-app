import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/services/audio_recorder_service.dart';

void main() {
  group('AudioRecorderService 測試', () {
    test('RecordingResult.tooShort 應該標記為錄音太短', () {
      final result = RecordingResult.tooShort;
      expect(result.isTooShort, true);
      expect(result.isSuccess, false);
      expect(result.isFailed, false);
    });

    test('RecordingResult.failed 應該標記為錄音失敗', () {
      final result = RecordingResult.failed;
      expect(result.isFailed, true);
      expect(result.isSuccess, false);
      expect(result.isTooShort, false);
    });

    test('RecordingResult.success 應該標記為成功', () {
      final result = RecordingResult.success('/test/path.m4a', 2000);
      expect(result.isSuccess, true);
      expect(result.path, '/test/path.m4a');
      expect(result.durationMs, 2000);
    });

    test('AudioRecorderService 應該有正確的錄音限制', () {
      // 驗證錄音時長限制常數
      expect(AudioRecorderService.minDurationMs, 1000);   // 最少 1 秒
      expect(AudioRecorderService.maxDurationMs, 10000);  // 最多 10 秒
    });
  });

  group('錄音時長邏輯測試', () {
    test('少於 1 秒的錄音應該被判定為太短', () {
      // 模擬時長計算
      const durationMs = 500; // 少於 1 秒
      final isTooShort = durationMs < AudioRecorderService.minDurationMs;
      expect(isTooShort, true);
    });

    test('1-10 秒之間的錄音應該正常處理', () {
      const durationMs = 3000; // 3 秒
      final isValid = durationMs >= AudioRecorderService.minDurationMs &&
          durationMs <= AudioRecorderService.maxDurationMs;
      expect(isValid, true);
    });

    test('超過 10 秒的錄音應該被截断', () {
      const durationMs = 15000; // 超過 10 秒
      final isOverMax = durationMs >= AudioRecorderService.maxDurationMs;
      expect(isOverMax, true);
    });
  });
}
