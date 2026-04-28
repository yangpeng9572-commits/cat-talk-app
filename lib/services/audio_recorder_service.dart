import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

/// 錄音服務
/// 處理麥克風權限、錄音、與 fallback
class AudioRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
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

  /// 初始化錄音器
  Future<void> initialize() async {
    try {
      await _recorder.openRecorder();
    } catch (e) {
      debugPrint('初始化錄音器失敗: $e');
    }
  }

  /// 檢查並請求麥克風權限
  Future<bool> checkAndRequestPermission() async {
    try {
      final status = await Permission.microphone.status;
      
      if (status.isGranted) {
        _hasPermission = true;
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.microphone.request();
        _hasPermission = result.isGranted;
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
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

  /// 開啟麥克風設定頁面
  Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// 開始錄音
  Future<bool> startRecording() async {
    if (_isRecording) return false;

    try {
      if (!await checkAndRequestPermission()) {
        debugPrint('沒有麥克風權限');
        return false;
      }

      await initialize();

      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/cat_meow_$timestamp.aac';

      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
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
  Future<RecordingResult?> stopRecording() async {
    if (!_isRecording || _currentRecordingPath == null) {
      return null;
    }

    try {
      await _recorder.stopRecorder();
      _isRecording = false;

      final duration = DateTime.now().difference(_recordingStartTime!).inMilliseconds;
      
      if (duration < minDurationMs) {
        debugPrint('錄音太短: ${duration}ms');
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

  /// 取消錄音
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _recorder.stopRecorder();
      _isRecording = false;

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
    await _recorder.closeRecorder();
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

  static final RecordingResult tooShort = RecordingResult._(status: RecordingStatus.tooShort);
  static final RecordingResult failed = RecordingResult._(status: RecordingStatus.failed);

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
