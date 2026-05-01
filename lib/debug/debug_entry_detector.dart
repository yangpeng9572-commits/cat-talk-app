import 'package:flutter/foundation.dart';

/// Debug 入口偵測器
/// 負責長按 / 點擊計數邏輯，5 次後觸發 callback
/// 不直接操作 UI，純邏輯

class DebugEntryDetector {
  /// 觸發門檻（預設 5 次）
  final int triggerThreshold;

  /// 計數器
  int _tapCount = 0;

  /// 計數歸零計時器（超過 2 秒未點擊則歸零）
  DateTime? _lastTapTime;

  /// 是否已觸發（防止重複觸發）
  bool _hasTriggered = false;

  /// 觸發 callback
  VoidCallback? onTriggered;

  DebugEntryDetector({
    this.triggerThreshold = 5,
    this.onTriggered,
  });

  /// 紀錄一次點擊 / 長按
  /// 返回是否已觸發
  bool recordTap() {
    final now = DateTime.now();

    // 如果距離上次點擊超過 2 秒，歸零計數
    if (_lastTapTime != null) {
      final diff = now.difference(_lastTapTime!).inMilliseconds;
      if (diff > 2000) {
        _tapCount = 0;
      }
    }

    _lastTapTime = now;
    _tapCount++;

    if (_hasTriggered) {
      // 已觸發過，不重複
      return false;
    }

    if (_tapCount >= triggerThreshold) {
      _hasTriggered = true;
      debugPrint('[DebugEntry] Triggered after $_tapCount taps');
      onTriggered?.call();
      return true;
    }

    debugPrint('[DebugEntry] Tap $_tapCount / $triggerThreshold');
    return false;
  }

  /// 重置計數器（手動呼叫）
  void reset() {
    _tapCount = 0;
    _hasTriggered = false;
    _lastTapTime = null;
    debugPrint('[DebugEntry] Reset');
  }

  /// 目前計數
  int get currentCount => _tapCount;

  /// 是否已觸發
  bool get hasTriggered => _hasTriggered;
}
