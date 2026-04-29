import 'package:shared_preferences/shared_preferences.dart';
import '../data/cat_world_items.dart';
import '../models/shop_item.dart';

/// 解鎖/操作結果
enum UnlockResult {
  success,
  alreadyUnlocked,
  itemNotFound,
}

/// 裝備結果
enum EquipResult {
  success,
  notUnlocked,
  itemNotFound,
}

/// 她的小世界服務
/// 處理商品解鎖、裝備、每隻貓的配置保存
class CatWorldService {
  static final CatWorldService _instance = CatWorldService._internal();
  factory CatWorldService() => _instance;
  CatWorldService._internal();

  /// 取得保存 Key
  String _unlockedKey(String catId) => 'cat_world_unlocked_$catId';
  String _equippedRoomKey(String catId) => 'cat_world_equipped_room_$catId';
  String _equippedFurnitureKey(String catId) => 'cat_world_equipped_furniture_$catId';
  String _equippedAccessoriesKey(String catId) => 'cat_world_equipped_accessories_$catId';
  String _equippedAnimationsKey(String catId) => 'cat_world_equipped_animations_$catId';
  String _equippedShareTemplateKey(String catId) => 'cat_world_equipped_share_template_$catId';

  /// 取得該貓的所有商品（含解鎖狀態）
  Future<List<ShopItem>> getItems(String catId) async {
    final unlockedIds = await _getUnlockedIds(catId);
    return CatWorldItems.allItems.map((item) {
      return item.copyWith(isUnlocked: unlockedIds.contains(item.id) || item.unlockType == ShopUnlockType.free);
    }).toList();
  }

  /// 依分類取得商品
  Future<List<ShopItem>> getItemsByCategory(String catId, ShopItemCategory category) async {
    final items = await getItems(catId);
    return items.where((i) => i.category == category).toList();
  }

  /// 取得已解鎖商品
  Future<List<ShopItem>> getUnlockedItems(String catId) async {
    final items = await getItems(catId);
    return items.where((i) => i.isUnlocked).toList();
  }

  /// 檢查商品是否已解鎖
  Future<bool> isItemUnlocked(String catId, String itemId) async {
    final item = CatWorldItems.allItems.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return false;
    if (item.unlockType == ShopUnlockType.free) return true;
    final unlockedIds = await _getUnlockedIds(catId);
    return unlockedIds.contains(itemId);
  }

  /// 解鎖商品
  Future<UnlockResult> unlockItem(String catId, String itemId) async {
    final item = CatWorldItems.allItems.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return UnlockResult.itemNotFound;
    if (item.unlockType == ShopUnlockType.free) return UnlockResult.alreadyUnlocked;

    final isAlreadyUnlocked = await isItemUnlocked(catId, itemId);
    if (isAlreadyUnlocked) return UnlockResult.alreadyUnlocked;

    final prefs = await SharedPreferences.getInstance();
    final unlockedIds = await _getUnlockedIds(catId);
    unlockedIds.add(itemId);
    await prefs.setStringList(_unlockedKey(catId), unlockedIds.toList());
    return UnlockResult.success;
  }

  /// 裝備商品
  Future<EquipResult> equipItem(String catId, String itemId) async {
    final item = CatWorldItems.allItems.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return EquipResult.itemNotFound;

    // 檢查是否已解鎖
    final isUnlocked = await isItemUnlocked(catId, itemId);
    if (!isUnlocked) return EquipResult.notUnlocked;

    final prefs = await SharedPreferences.getInstance();

    switch (item.category) {
      case ShopItemCategory.roomTheme:
        // 房間只能裝備一個
        await prefs.setString(_equippedRoomKey(catId), itemId);
        break;

      case ShopItemCategory.furniture:
        // 家具可裝備多個
        final equipped = prefs.getStringList(_equippedFurnitureKey(catId)) ?? [];
        if (!equipped.contains(itemId)) {
          equipped.add(itemId);
          await prefs.setStringList(_equippedFurnitureKey(catId), equipped);
        }
        break;

      case ShopItemCategory.accessory:
        // 配件：無配件和其他配件不可同時裝備
        final equipped = prefs.getStringList(_equippedAccessoriesKey(catId)) ?? [];
        if (itemId == 'accessory_none') {
          // 選無配件，清空其他配件
          await prefs.setStringList(_equippedAccessoriesKey(catId), [itemId]);
        } else {
          // 選其他配件，移除無配件
          equipped.remove('accessory_none');
          if (!equipped.contains(itemId)) {
            equipped.add(itemId);
          }
          await prefs.setStringList(_equippedAccessoriesKey(catId), equipped);
        }
        break;

      case ShopItemCategory.emotionAnimation:
        // 動畫可裝備多個
        final equipped = prefs.getStringList(_equippedAnimationsKey(catId)) ?? [];
        if (!equipped.contains(itemId)) {
          equipped.add(itemId);
          await prefs.setStringList(_equippedAnimationsKey(catId), equipped);
        }
        break;

      case ShopItemCategory.shareTemplate:
        // 分享卡只能裝備一個
        await prefs.setString(_equippedShareTemplateKey(catId), itemId);
        break;

      case ShopItemCategory.seasonalBundle:
        // 套組不支援直接裝備
        break;
    }

    return EquipResult.success;
  }

  /// 卸除商品
  Future<void> unequipItem(String catId, String itemId) async {
    final prefs = await SharedPreferences.getInstance();
    final item = CatWorldItems.allItems.where((i) => i.id == itemId).firstOrNull;
    if (item == null) return;

    switch (item.category) {
      case ShopItemCategory.roomTheme:
        await prefs.remove(_equippedRoomKey(catId));
        break;
      case ShopItemCategory.furniture:
        final equipped = prefs.getStringList(_equippedFurnitureKey(catId)) ?? [];
        equipped.remove(itemId);
        await prefs.setStringList(_equippedFurnitureKey(catId), equipped);
        break;
      case ShopItemCategory.accessory:
        final equipped = prefs.getStringList(_equippedAccessoriesKey(catId)) ?? [];
        equipped.remove(itemId);
        await prefs.setStringList(_equippedAccessoriesKey(catId), equipped);
        break;
      case ShopItemCategory.emotionAnimation:
        final equipped = prefs.getStringList(_equippedAnimationsKey(catId)) ?? [];
        equipped.remove(itemId);
        await prefs.setStringList(_equippedAnimationsKey(catId), equipped);
        break;
      case ShopItemCategory.shareTemplate:
        await prefs.remove(_equippedShareTemplateKey(catId));
        break;
      case ShopItemCategory.seasonalBundle:
        break;
    }
  }

  /// 取得已裝備的房間主題
  Future<String?> getEquippedRoomTheme(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_equippedRoomKey(catId));
  }

  /// 取得已裝備的家具
  Future<List<String>> getEquippedFurniture(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_equippedFurnitureKey(catId)) ?? [];
  }

  /// 取得已裝備的配件
  Future<List<String>> getEquippedAccessories(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_equippedAccessoriesKey(catId)) ?? [];
  }

  /// 取得已裝備的動畫
  Future<List<String>> getEquippedAnimations(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_equippedAnimationsKey(catId)) ?? [];
  }

  /// 取得已裝備的分享卡模板
  Future<String?> getEquippedShareTemplate(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_equippedShareTemplateKey(catId));
  }

  /// 初始化新貓咪的預設配置
  Future<void> initializeNewCat(String catId) async {
    final prefs = await SharedPreferences.getInstance();

    // 如果已有配置，不覆蓋
    if (prefs.containsKey(_equippedRoomKey(catId))) return;

    // 初始小房間自動裝備
    await prefs.setString(_equippedRoomKey(catId), 'room_default');

    // 基本粉色卡自動裝備
    await prefs.setString(_equippedShareTemplateKey(catId), 'share_basic_pink');

    // 無配件自動裝備
    await prefs.setStringList(_equippedAccessoriesKey(catId), ['accessory_none']);
  }

  /// 取得已解鎖的 ID 列表
  Future<Set<String>> _getUnlockedIds(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_unlockedKey(catId));
    return list?.toSet() ?? {};
  }
}
