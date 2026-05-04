import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_meow_sound.dart';
import '../services/meow_sound_mode_service.dart';
import '../services/saved_meow_sound_service.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';

/// 喵一下 Bottom Sheet
/// 
/// 使用方式：
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   isDismissible: true,
///   enableDrag: true,
///   builder: (_) => MeowOnceSheet(catId: catId, catName: catName),
/// );
/// ```
class MeowOnceSheet extends StatefulWidget {
  final String? catId;
  final String? catName;

  const MeowOnceSheet({
    super.key,
    this.catId,
    this.catName,
  });

  @override
  State<MeowOnceSheet> createState() => _MeowOnceSheetState();
}

class _MeowOnceSheetState extends State<MeowOnceSheet> {
  final MeowSoundModeService _modeService = MeowSoundModeService();
  final SavedMeowSoundService _savedService = SavedMeowSoundService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  int _currentModeIndex = 0;
  bool _isPlaying = false;
  bool _showSaved = false;
  List<SavedMeowSound> _savedSounds = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedSounds();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedSounds() async {
    final prefs = await SharedPreferences.getInstance();
    await _savedService.init(prefs);
    final sounds = await _savedService.getAll();
    if (mounted) setState(() => _savedSounds = sounds);
  }

  MeowSoundMode get _currentMode => MeowSoundModeService.modes[_currentModeIndex];
  String get _currentMeowText => MeowSoundModeService.meowTexts[_currentModeIndex];

  Future<void> _playSound() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() => _isPlaying = true);

    try {
      await _audioPlayer.play(AssetSource(_currentMode.assetPath.replaceFirst('assets/', '')));
    } catch (e) {
      // 音效檔不存在時顯示友善提示，不閃退
      if (mounted) {
        setState(() => _isPlaying = false);
        TopToastService.info(
          context,
          message: '這個喵聲還沒放進來，之後可以替換成真的喵聲 🐾',
        );
      }
    }
  }

  Future<void> _nextMode() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
    }
    setState(() {
      _currentModeIndex = (_currentModeIndex + 1) % _modeService.modes.length;
      _isPlaying = false;
      _noteController.clear();
    });
  }

  Future<void> _saveSound() async {
    final note = _noteController.text.trim();
    final sound = SavedMeowSound(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      catId: widget.catId ?? 'unknown',
      catName: widget.catName ?? '未知貓咪',
      modeId: _currentMode.id,
      modeName: _currentMode.name,
      meowText: _currentMeowText,
      assetPath: _currentMode.assetPath,
      note: note.isEmpty ? null : note,
      createdAt: DateTime.now(),
    );
    await _savedService.add(sound);
    await _loadSavedSounds();
    if (mounted) {
      TopToastService.success(
        context,
        message: '已保留這個喵聲 💕',
      );
    }
  }

  Future<void> _deleteSound(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除這個喵聲？'),
        content: const Text('刪除後無法恢復'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _savedService.delete(id);
      await _loadSavedSounds();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 拖動條
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 標題
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('喵一下', style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold,
                        color: Color(0xFF6B4B4B),
                      )),
                      TextButton(
                        onPressed: () => setState(() => _showSaved = !_showSaved),
                        child: Text(_showSaved ? '返回' : '常用喵聲'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (!_showSaved) ...[
                    // === 喵一下主模式 ===

                    // 喵語文字
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: KawaiiTheme.primaryPink.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _currentMeowText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 模式名稱
                    Text(
                      '模式 ${_currentMode.id}/15：${_currentMode.name}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),

                    // 播放 / 下一個按鈕
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _playSound,
                          icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: Colors.white),
                          label: Text(_isPlaying ? '停止' : '播放 🎵'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: KawaiiTheme.primaryPink,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: _nextMode,
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('下一個'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: KawaiiTheme.primaryPink,
                            side: BorderSide(color: KawaiiTheme.primaryPink),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 備註欄
                    TextField(
                      controller: _noteController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: '備註，例如：奶茶聽到會抬頭',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: KawaiiTheme.primaryPink, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 保留 / 不保留
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('不保留'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveSound,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: KawaiiTheme.primaryPink,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('保留 💕'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // === 常用喵聲列表 ===

                    if (_savedSounds.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            const Text('🐾', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text('還沒有保留的喵聲，試著喵一下吧',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    else
                      ..._savedSounds.map((sound) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(sound.modeName,
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                    onPressed: () => _deleteSound(sound.id),
                                    padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(sound.meowText, style: const TextStyle(fontSize: 14)),
                              if (sound.note != null && sound.note!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text('📝 ${sound.note}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                              const SizedBox(height: 4),
                              Text(
                                '${sound.catName} · ${sound.createdAt.month}/${sound.createdAt.day}',
                                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                            ],
                          ),
                        ),
                      )),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
