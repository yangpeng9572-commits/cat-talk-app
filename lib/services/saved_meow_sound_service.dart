import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_meow_sound.dart';

/// 已儲存喵聲服務
/// 
/// 使用 SharedPreferences 持久化儲存使用者保留的常用喵聲
class SavedMeowSoundService {
  static final SavedMeowSoundService _instance = SavedMeowSoundService._internal();
  factory SavedMeowSoundService() => _instance;
  SavedMeowSoundService._internal();

  SharedPreferences? _prefs;
  static const String _storageKey = 'saved_meow_sounds';

  /// 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// 確保已初始化
  Future<SharedPreferences> _getPrefs() async {
    if (_prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
    return _prefs!;
  }

  /// 取得所有已儲存喵聲（由新到舊）
  Future<List<SavedMeowSound>> getAll() async {
    final prefs = await _getPrefs();
    final jsonStr = prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final sounds = jsonList
          .map((j) => SavedMeowSound.fromJson(j as Map<String, dynamic>))
          .toList();
      sounds.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return sounds;
    } catch (e) {
      return [];
    }
  }

  /// 依照貓咪 ID 取得已儲存喵聲
  Future<List<SavedMeowSound>> getByCatId(String catId) async {
    final all = await getAll();
    return all.where((s) => s.catId == catId).toList();
  }

  /// 新增儲存喵聲
  Future<void> add(SavedMeowSound sound) async {
    final all = await getAll();
    all.insert(0, sound);
    await _saveAll(all);
  }

  /// 刪除已儲存喵聲
  Future<void> delete(String id) async {
    final all = await getAll();
    all.removeWhere((s) => s.id == id);
    await _saveAll(all);
  }

  /// 更新已儲存喵聲的備註
  Future<void> updateNote(String id, String note) async {
    final all = await getAll();
    final idx = all.indexWhere((s) => s.id == id);
    if (idx >= 0) {
      final old = all[idx];
      all[idx] = SavedMeowSound(
        id: old.id,
        catId: old.catId,
        catName: old.catName,
        modeId: old.modeId,
        modeName: old.modeName,
        meowText: old.meowText,
        assetPath: old.assetPath,
        note: note,
        createdAt: old.createdAt,
      );
      await _saveAll(all);
    }
  }

  /// 內部儲存
  Future<void> _saveAll(List<SavedMeowSound> sounds) async {
    final prefs = await _getPrefs();
    final jsonList = sounds.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }
}
