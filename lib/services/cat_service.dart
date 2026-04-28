import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';

/// 貓咪服務
/// 管理貓咪的 CRUD 操作
class CatService {
  static const _catsKey = 'cats';
  
  final SharedPreferences _prefs;
  
  CatService(this._prefs);
  
  /// 取得所有貓咪
  List<Cat> getAllCats() {
    final catsJson = _prefs.getString(_catsKey);
    if (catsJson == null || catsJson.isEmpty) {
      return [];
    }
    
    try {
      final List<dynamic> catsList = catsJson as List<dynamic>;
      return catsList.map((json) => Cat.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 根據 ID 取得貓咪
  Cat? getCatById(String id) {
    final cats = getAllCats();
    try {
      return cats.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
  
  /// 新增貓咪
  Future<void> addCat(Cat cat) async {
    final cats = getAllCats();
    cats.add(cat);
    await _saveCats(cats);
  }
  
  /// 更新貓咪
  Future<void> updateCat(Cat cat) async {
    final cats = getAllCats();
    final index = cats.indexWhere((c) => c.id == cat.id);
    if (index != -1) {
      cats[index] = cat;
      await _saveCats(cats);
    }
  }
  
  /// 刪除貓咪
  Future<void> deleteCat(String id) async {
    final cats = getAllCats();
    cats.removeWhere((cat) => cat.id == id);
    await _saveCats(cats);
  }
  
  /// 儲存貓咪列表
  Future<void> _saveCats(List<Cat> cats) async {
    final catsJson = cats.map((cat) => cat.toJson()).toList();
    await _prefs.setString(_catsKey, jsonEncode(catsJson));
  }
  
  /// 取得貓咪數量
  int getCatCount() {
    return getAllCats().length;
  }
}
