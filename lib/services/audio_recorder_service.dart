import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// 錄音服務
/// 處理麥克風權限、錄音、與 fallback
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  
  bool _isRecording = false;
  String? _currentRecordingPath;
  DateTime? _recordingStartTime;

  // 錄音限制
  static const int minDurationMs = 1000;   // 最少 1 秒
  static const int maxDurationMs = 10000;  // 最多 10 秒

  // 麥克風狀態
  bool get isRecording => _isRecording;
  bool get hasPermission => _hasPermission;

  bool _hasPermission = false;

  /// 檢查並請求麥克風權限
  Future<bool> checkAndRequestPermission() async {
    try {
      // 檢查麥克風狀態
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        _hasPermission = true;
        return true;
      }

      if (status.isDenied) {
        // 請求權限
        final result = await Permission.microphone.request();
        _hasPermission = result.isGranted;
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        // 使用者拒絕了權限，且選擇「不再詢問」
        _hasPermission = false;
        return false;
      }

      _hasPermission = false;
      return false;
    } catch (e) {
      debugPrint('權限檢查失敗: $e');
      _hasPermission = false;
      return false;
    }
  }

  /// 開啟麥克風設定頁面（當權限永久拒絕時）
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// 開始錄音
  /// 回傳 true 表示成功開始錄音
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      // 檢查權限
      if (!await checkAndRequestPermission()) {
        debugPrint('沒有麥克風權限');
        return false;
      }

      // 檢查是否可以在此平台錄音
      if (!await _recorder.hasPermission()) {
        debugPrint('錄音器沒有權限');
        return false;
      }

      // 取得儲存路徑
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/cat_meow_$timestamp.m4a';

      // 開始錄音
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStartTime = DateTime.now();

      debugPrint('開始錄音: $_currentRecordingPath');
      return true;
    } catch (e) {
      debugPrint('開始錄音失敗: $e');
      _isRecording = false;
      return false;
    }
  }

  /// 停止錄音並取得錄音檔案路徑
  /// 回傳 null 表示錄音時間太短或失敗
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) {
      return null;
    }

    try {
      // 停止錄音
      await _recorder.stop();
      _isRecording = false;

      // 檢查錄音時長
      final duration = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
      
      if (duration < minDurationMs) {
        debugPrint('錄音太短: ${duration}ms');
        // 刪除太短的錄音檔
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        return RecordingResult.tooShort;
      }

      debugPrint('錄音完成: ${duration}ms, 路徑: $_currentRecordingPath');
      
      return RecordingResult.success(
        _currentRecordingPath!,
        duration,
      );
    } catch (e) {
      debugPrint('停止錄音失敗: $e');
      _isRecording = false;
      return RecordingResult.failed;
    }
  }

  /// 取消錄音（不放進分析）
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stop();
      _isRecording = false;

      // 刪除錄音檔
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('取消錄音失敗: $e');
      _isRecording = false;
    }
  }

  /// 取得錄音時長（毫秒）
  int get recordingDurationMs {
    if (_recordingStartTime == null) return 0;
    return DateTime.now().difference(_recordingStartTime!).inMilliseconds;
  }

  /// 是否超過最大錄音時長
  bool get isMaxDurationReached {
    return recordingDurationMs >= maxDurationMs;
  }

  /// 釋放資源
  Future<void> dispose() async {
    await cancelRecording();
    _recorder.dispose();
  }
}

/// 錄音結果
class RecordingResult {
  final String? path;
  final int? durationMs;
  final RecordingStatus status;

  RecordingResult._({
    this.path,
    this.durationMs,
    required this.status,
  });

  /// 錄音太短（少於 1 秒）
  static final RecordingResult tooShort = RecordingResult._(status: RecordingStatus.tooShort);

  /// 錄音失敗
  static final RecordingResult failed = RecordingResult._(status: RecordingStatus.failed);

  /// 錄音成功
  factory RecordingResult.success(String path, int durationMs) {
    return RecordingResult._(
      path: path,
      durationMs: durationMs,
      status: RecordingStatus.success,
    );
  }

  bool get isSuccess => status == RecordingStatus.success;
  bool get isTooShort => status == RecordingStatus.tooShort;
  bool get isFailed => status == RecordingStatus.failed;
}

enum RecordingStatus {
  success,
  tooShort,
  failed,
}
