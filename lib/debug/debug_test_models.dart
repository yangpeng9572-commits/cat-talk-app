/// Debug 驗收測試結果模型
/// 不依賴 Cat model，獨立存在

class DebugTestResult {
  /// 測試項目名稱
  final String name;

  /// 是否通過
  final bool passed;

  /// 測試訊息
  final String message;

  /// 執行時間（毫秒）
  final int durationMs;

  /// 建立時間
  final DateTime createdAt;

  const DebugTestResult({
    required this.name,
    required this.passed,
    required this.message,
    required this.durationMs,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'passed': passed,
        'message': message,
        'durationMs': durationMs,
        'createdAt': createdAt.toIso8601String(),
      };

  @override
  String toString() =>
      '[$name] ${passed ? 'PASS' : 'FAIL'} — $message (${durationMs}ms)';
}
