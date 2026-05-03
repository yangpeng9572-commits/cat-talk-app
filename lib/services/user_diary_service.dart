import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_diary_entry.dart';

/// 使用者日記服務
///
/// 使用 SharedPreferences 持久化儲存使用者撰寫的貓咪生活日記
/// - 第一階段（v1）：純文字記錄，日期 + 貓咪名稱 + 內容
/// - 第二階段（P3-4）：加入照片儲存（從 image_picker 取得路徑）
class UserDiaryService {
  static final UserDiaryService _instance = UserDiaryService._internal();
  factory UserDiaryService() => _instance;
  UserDiaryService._internal();

  SharedPreferences? _prefs;
  static const String _storageKey = 'user_diary_entries';

  /// 初始化
  Future<void> init(SharedPreferences prefs) async {
    _prefs = prefs;
  }

  /// 取得所有日記（由新到舊）
  List<UserDiaryEntry> getAll() {
    if (_prefs == null) return [];
    final jsonStr = _prefs!.getString(_storageKey);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final entries = jsonList
          .map((j) => UserDiaryEntry.fromJson(j as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (e) {
      return [];
    }
  }

  /// 依照貓咪 ID 取得日記（由新到舊）
  List<UserDiaryEntry> getByCatId(String catId) {
    return getAll().where((e) => e.catId == catId).toList();
  }

  /// 依照日期取得日記（catId + date 當天）
  List<UserDiaryEntry> getByCatIdAndDate(String catId, DateTime date) {
    return getByCatId(catId).where((e) =>
        e.date.year == date.year &&
        e.date.month == date.month &&
        e.date.day == date.day).toList();
  }

  /// 新增日記（支援 P3-4 照片、P3-4 Phase 2 標籤）
  Future<void> addEntry({
    required String catId,
    required String catName,
    required DateTime date,
    required String content,
    String? photoPath, // P3-4: 可選照片路徑
    List<String>? tags, // P3-4 Phase 2: 可選標籤
  }) async {
    if (_prefs == null) return;
    final entry = UserDiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      catId: catId,
      catName: catName,
      date: date,
      content: content,
      photoPath: photoPath, // P3-4: 照片路徑
      tags: tags ?? const [], // P3-4 Phase 2: 標籤
      createdAt: DateTime.now(),
    );
    final all = getAll();
    all.insert(0, entry);
    await _saveAll(all);
  }

  /// 刪除日記
  Future<void> deleteEntry(String id) async {
    if (_prefs == null) return;
    final all = getAll();
    all.removeWhere((e) => e.id == id);
    await _saveAll(all);
  }

  /// 儲存全部
  Future<void> _saveAll(List<UserDiaryEntry> entries) async {
    if (_prefs == null) return;
    final jsonList = entries.map((e) => e.toJson()).toList();
    await _prefs!.setString(_storageKey, jsonEncode(jsonList));
  }
}
