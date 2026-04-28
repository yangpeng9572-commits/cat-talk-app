import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 錄音播放服務
/// 處理錄音檔案的播放
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPath;

  AudioPlayer get player => _player;
  bool get isPlaying => _isPlaying;
  String? get currentPath => _currentPath;

  /// 播放錄音檔案
  Future<bool> play(String path) async {
    try {
      _currentPath = path;
      await _player.play(DeviceFileSource(path));
      _isPlaying = true;
      return true;
    } catch (e) {
      debugPrint('播放失敗: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// 停止播放
  Future<void> stop() async {
    try {
      await _player.stop();
      _isPlaying = false;
      _currentPath = null;
    } catch (e) {
      debugPrint('停止播放失敗: $e');
    }
  }

  /// 暫停播放
  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
    } catch (e) {
      debugPrint('暫停播放失敗: $e');
    }
  }

  /// 恢復播放
  Future<void> resume() async {
    try {
      await _player.resume();
      _isPlaying = true;
    } catch (e) {
      debugPrint('恢復播放失敗: $e');
    }
  }

  /// 釋放資源
  Future<void> dispose() async {
    await _player.dispose();
  }
}
