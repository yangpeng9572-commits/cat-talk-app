import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/data/cat_world_items.dart';
import 'package:cat_talk/models/shop_item.dart';

void main() {
  group('CatWorldItems 商品資料庫測試', () {
    test('allItems 不為空', () {
      expect(CatWorldItems.allItems.isNotEmpty, true);
    });

    test('id 全部唯一', () {
      final ids = CatWorldItems.allItems.map((i) => i.id).toSet();
      expect(ids.length, CatWorldItems.allItems.length);
    });

    test('freeItems 都 isUnlocked = true', () {
      for (final item in CatWorldItems.freeItems) {
        expect(item.isUnlocked, true, reason: '${item.name} 應該是已解鎖');
      }
    });

    test('非 free 物件預設未解鎖', () {
      final nonFreeItems = CatWorldItems.allItems
          .where((i) => i.unlockType != ShopUnlockType.free)
          .toList();
      for (final item in nonFreeItems) {
        expect(item.isUnlocked, false, reason: '${item.name} 應該是未解鎖');
      }
    });

    test('每個分類都有資料', () {
      expect(CatWorldItems.roomThemes.isNotEmpty, true, reason: '房間主題應該有資料');
      expect(CatWorldItems.accessoryItems.isNotEmpty, true, reason: '配件應該有資料');
      expect(CatWorldItems.animationItems.isNotEmpty, true, reason: '動畫應該有資料');
      expect(CatWorldItems.shareTemplateItems.isNotEmpty, true, reason: '分享卡應該有資料');
      expect(CatWorldItems.seasonalBundleItems.isNotEmpty, true, reason: '季節套組應該有資料');
    });

    test('房間主題至少 6 個含初始小房間', () {
      expect(CatWorldItems.roomThemes.length, greaterThanOrEqualTo(6));
      expect(
        CatWorldItems.roomThemes.any((i) => i.id == 'room_default'),
        true,
        reason: '應該包含初始小房間',
      );
    });

    test('家具至少 30 個', () {
      final allFurniture = [
        ...CatWorldItems.furnitureItems,
        ...CatWorldItems.foodAreaItems,
        ...CatWorldItems.toyItems,
        ...CatWorldItems.decorItems,
      ];
      // 排除重複
      final uniqueIds = allFurniture.map((i) => i.id).toSet();
      expect(uniqueIds.length, greaterThanOrEqualTo(30),
          reason: '家具應該至少30個，實際: ${uniqueIds.length}');
    });

    test('配件至少 10 個', () {
      expect(CatWorldItems.accessoryItems.length, greaterThanOrEqualTo(10),
          reason: '配件應該至少10個，實際: ${CatWorldItems.accessoryItems.length}');
    });

    test('動畫至少 8 個', () {
      expect(CatWorldItems.animationItems.length, greaterThanOrEqualTo(8),
          reason: '動畫應該至少8個，實際: ${CatWorldItems.animationItems.length}');
    });

    test('分享卡至少 6 個', () {
      expect(CatWorldItems.shareTemplateItems.length, greaterThanOrEqualTo(6),
          reason: '分享卡應該至少6個，實際: ${CatWorldItems.shareTemplateItems.length}');
    });

    test('季節套組至少 5 個', () {
      expect(CatWorldItems.seasonalBundleItems.length, greaterThanOrEqualTo(5),
          reason: '季節套組應該至少5個，實際: ${CatWorldItems.seasonalBundleItems.length}');
    });

    test('priceLabel 不包含金額數字', () {
      final invalidItems = CatWorldItems.allItems
          .where((i) => RegExp(r'\d+[元$]').hasMatch(i.priceLabel))
          .toList();
      expect(invalidItems.isEmpty, true,
          reason: 'priceLabel 不應包含金額，發現: ${invalidItems.map((i) => i.priceLabel)}');
    });
  });
}
