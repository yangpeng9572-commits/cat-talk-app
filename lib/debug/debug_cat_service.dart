import 'package:flutter/foundation.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';

/// Debug 專用貓咪 Service
/// 職責：
/// 1. 新增測試貓（[DEBUG] prefix）
/// 2. 清除測試資料（只刪 [DEBUG] 開頭的貓）
/// 不修改 Cat model，不碰正式 CatService 邏輯
class DebugCatService {
  static const String debugPrefix = '[DEBUG]';

  final CatService _catService;

  DebugCatService(this._catService);

  /// 新增一隻測試貓
  /// name = [DEBUG]測試貓
  /// birthdayType = unknown
  /// 不填照片、不填生日
  ///
  /// 回傳新增後的 Cat
  Future<Cat> addDebugCat() async {
    final cat = Cat(
      id: 'debug_${DateTime.now().millisecondsSinceEpoch}',
      name: '$debugPrefix 測試貓',
      birthdayType: 'unknown',
      gender: 'female',
      ageStage: 'adult',
      breed: '',
      age: 2.0,
    );

    await _catService.addCat(cat);
    debugPrint('[DebugCatService] 新增測試貓: ${cat.name} (${cat.id})');
    return cat;
  }

  /// 取得目前 debug 測試貓數量
  int getDebugCatCount() {
    return _catService
        .getAllCats()
        .where((c) => c.name.startsWith(debugPrefix))
        .length;
  }

  /// 清除所有 [DEBUG] 測試資料
  /// 回傳刪除數量
  Future<int> clearDebugCats() async {
    final allCats = _catService.getAllCats();
    final debugCats =
        allCats.where((c) => c.name.startsWith(debugPrefix)).toList();

    for (final cat in debugCats) {
      await _catService.deleteCat(cat.id);
      debugPrint('[DebugCatService] 刪除測試貓: ${cat.name} (${cat.id})');
    }

    return debugCats.length;
  }

  /// 驗證新增後數量是否 +1
  /// 回傳 true = 通過
  Future<bool> verifyCatCountIncreased(int beforeCount) async {
    final after = _catService.getCatCount();
    return after == beforeCount + 1;
  }
}
