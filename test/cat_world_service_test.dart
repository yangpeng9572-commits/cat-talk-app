import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_talk/services/cat_world_service.dart';
import 'package:cat_talk/data/cat_world_items.dart';
import 'package:cat_talk/models/shop_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CatWorldService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = CatWorldService();
  });

  group('CatWorldService 測試', () {
    test('免費物件預設已解鎖', () async {
      final catId = 'test_cat_free';
      final items = await service.getItems(catId);
      final freeItems = items.where((i) => i.unlockType.name == 'free').toList();

      expect(freeItems.isNotEmpty, true);
      for (final item in freeItems) {
        expect(item.isUnlocked, true, reason: '${item.name} 應該已解鎖');
      }
    });

    test('初始小房間預設裝備', () async {
      final catId = 'test_cat_init';
      await service.initializeNewCat(catId);

      final equippedRoom = await service.getEquippedRoomTheme(catId);
      expect(equippedRoom, 'room_default');
    });

    test('基本粉色卡預設裝備', () async {
      final catId = 'test_cat_init2';
      await service.initializeNewCat(catId);

      final equippedShare = await service.getEquippedShareTemplate(catId);
      expect(equippedShare, 'share_basic_pink');
    });

    test('可解鎖商品', () async {
      final catId = 'test_cat_unlock';
      final catId2 = 'test_cat_unlock2';

      // 第一次解鎖
      final result1 = await service.unlockItem(catId, 'room_milk_tea_afternoon');
      expect(result1, UnlockResult.success);

      // 再次解鎖
      final result2 = await service.unlockItem(catId, 'room_milk_tea_afternoon');
      expect(result2, UnlockResult.alreadyUnlocked);

      // 確認已解鎖
      final isUnlocked = await service.isItemUnlocked(catId, 'room_milk_tea_afternoon');
      expect(isUnlocked, true);

      // 不同貓咪不受影響
      final isUnlocked2 = await service.isItemUnlocked(catId2, 'room_milk_tea_afternoon');
      expect(isUnlocked2, false);
    });

    test('未解鎖商品不可裝備', () async {
      final catId = 'test_cat_equip_locked';

      final result = await service.equipItem(catId, 'room_pink_cuddle');
      expect(result, EquipResult.notUnlocked);
    });

    test('房間同時只能裝備一個', () async {
      final catId = 'test_cat_room_equip';

      // 先解鎖兩個房間
      await service.unlockItem(catId, 'room_milk_tea_afternoon');
      await service.unlockItem(catId, 'room_pink_cuddle');

      // 裝備第一個
      await service.equipItem(catId, 'room_milk_tea_afternoon');
      expect(await service.getEquippedRoomTheme(catId), 'room_milk_tea_afternoon');

      // 裝備第二個，會替換掉第一個
      await service.equipItem(catId, 'room_pink_cuddle');
      expect(await service.getEquippedRoomTheme(catId), 'room_pink_cuddle');
    });

    test('家具可裝備多個', () async {
      final catId = 'test_cat_furniture_multi';

      // 解鎖多個家具
      await service.unlockItem(catId, 'furniture_cat_bed_butter');
      await service.unlockItem(catId, 'furniture_cat_bed_cloud');

      // 裝備多個
      await service.equipItem(catId, 'furniture_cat_bed_butter');
      await service.equipItem(catId, 'furniture_cat_bed_cloud');

      final equipped = await service.getEquippedFurniture(catId);
      expect(equipped.contains('furniture_cat_bed_butter'), true);
      expect(equipped.contains('furniture_cat_bed_cloud'), true);
    });

    test('無配件與其他配件不可同時裝備', () async {
      final catId = 'test_cat_accessory';

      // 先解鎖配件
      await service.unlockItem(catId, 'accessory_milk_tea_bow');

      // 先選無配件
      await service.equipItem(catId, 'accessory_none');
      var equipped = await service.getEquippedAccessories(catId);
      expect(equipped, contains('accessory_none'));

      // 再選其他配件，會替換
      await service.equipItem(catId, 'accessory_milk_tea_bow');
      equipped = await service.getEquippedAccessories(catId);
      expect(equipped.contains('accessory_none'), false, reason: '選其他配件後應移除無配件');
      expect(equipped.contains('accessory_milk_tea_bow'), true);

      // 再選無配件，會替換其他配件
      await service.equipItem(catId, 'accessory_none');
      equipped = await service.getEquippedAccessories(catId);
      expect(equipped.contains('accessory_none'), true);
      expect(equipped.contains('accessory_milk_tea_bow'), false, reason: '選無配件後應移除其他配件');
    });

    test('分享卡同時只能裝備一個', () async {
      final catId = 'test_cat_share_equip';

      // 解鎖多個分享卡
      await service.unlockItem(catId, 'share_milk_tea_diary');
      await service.unlockItem(catId, 'share_pink_cuddle');

      // 裝備第一個
      await service.equipItem(catId, 'share_milk_tea_diary');
      expect(await service.getEquippedShareTemplate(catId), 'share_milk_tea_diary');

      // 裝備第二個，會替換掉第一個
      await service.equipItem(catId, 'share_pink_cuddle');
      expect(await service.getEquippedShareTemplate(catId), 'share_pink_cuddle');
    });

    test('每隻貓配置分開保存', () async {
      final cat1 = 'cat_1';
      final cat2 = 'cat_2';

      // cat1 裝備
      await service.unlockItem(cat1, 'room_milk_tea_afternoon');
      await service.equipItem(cat1, 'room_milk_tea_afternoon');

      // cat2 不應有 cat1 的裝備
      expect(await service.getEquippedRoomTheme(cat1), 'room_milk_tea_afternoon');
      expect(await service.getEquippedRoomTheme(cat2), null);
    });

    test('App 重開後狀態仍可讀取', () async {
      final catId = 'test_cat_persist';

      // 解鎖並裝備
      await service.unlockItem(catId, 'room_forest_window');
      await service.equipItem(catId, 'room_forest_window');

      // 模擬重開（清空記憶體但保持磁碟狀態）
      SharedPreferences.setMockInitialValues({
        'cat_world_unlocked_$catId': ['room_forest_window'],
        'cat_world_equipped_room_$catId': 'room_forest_window',
      });

      // 重新建立 service
      final service2 = CatWorldService();

      // 驗證狀態
      final isUnlocked = await service2.isItemUnlocked(catId, 'room_forest_window');
      expect(isUnlocked, true);

      final equipped = await service2.getEquippedRoomTheme(catId);
      expect(equipped, 'room_forest_window');
    });

    test('getItemsByCategory 正常', () async {
      final catId = 'test_cat_by_category';

      final roomItems = await service.getItemsByCategory(catId, ShopItemCategory.roomTheme);
      expect(roomItems.every((i) => i.category == ShopItemCategory.roomTheme), true);

      final accessoryItems = await service.getItemsByCategory(catId, ShopItemCategory.accessory);
      expect(accessoryItems.every((i) => i.category == ShopItemCategory.accessory), true);
    });

    test('itemNotFound 情況', () async {
      final catId = 'test_cat_not_found';

      final unlockResult = await service.unlockItem(catId, 'non_existent_item');
      expect(unlockResult, UnlockResult.itemNotFound);

      final equipResult = await service.equipItem(catId, 'non_existent_item');
      expect(equipResult, EquipResult.itemNotFound);
    });
  });
}
