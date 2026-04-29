import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/models/shop_item.dart';

void main() {
  group('ShopItem 模型測試', () {
    test('ShopItem 可正常建立', () {
      final item = ShopItem(
        id: 'test_001',
        name: '測試家具',
        category: ShopItemCategory.furniture,
        description: '這是一個測試用的家具',
        priceLabel: '免費',
        unlockType: ShopUnlockType.free,
        createdAt: DateTime(2026, 4, 29),
      );

      expect(item.id, 'test_001');
      expect(item.name, '測試家具');
      expect(item.category, ShopItemCategory.furniture);
      expect(item.description, '這是一個測試用的家具');
      expect(item.priceLabel, '免費');
      expect(item.unlockType, ShopUnlockType.free);
      expect(item.isUnlocked, false);
      expect(item.isEquipped, false);
    });

    test('toJson/fromJson 正常', () {
      final item = ShopItem(
        id: 'test_002',
        name: '測試配件',
        category: ShopItemCategory.accessory,
        description: '這是一個測試用的配件',
        priceLabel: '100 默契',
        unlockType: ShopUnlockType.bond,
        requiredBondScore: 50,
        isUnlocked: true,
        isEquipped: false,
        tags: ['可愛', '粉色'],
        createdAt: DateTime(2026, 4, 29),
      );

      final json = item.toJson();
      final restored = ShopItem.fromJson(json);

      expect(restored.id, item.id);
      expect(restored.name, item.name);
      expect(restored.category, item.category);
      expect(restored.description, item.description);
      expect(restored.priceLabel, item.priceLabel);
      expect(restored.unlockType, item.unlockType);
      expect(restored.requiredBondScore, item.requiredBondScore);
      expect(restored.isUnlocked, item.isUnlocked);
      expect(restored.isEquipped, item.isEquipped);
      expect(restored.tags, item.tags);
    });

    test('copyWith 正常', () {
      final item = ShopItem(
        id: 'test_003',
        name: '原始名稱',
        category: ShopItemCategory.roomTheme,
        description: '原始描述',
        priceLabel: '免費',
        unlockType: ShopUnlockType.free,
        isUnlocked: false,
        isEquipped: false,
        createdAt: DateTime(2026, 4, 29),
      );

      final updated = item.copyWith(
        name: '新名稱',
        isUnlocked: true,
        isEquipped: true,
      );

      expect(updated.id, item.id); // 不變
      expect(updated.name, '新名稱'); // 更新
      expect(updated.category, item.category); // 不變
      expect(updated.isUnlocked, true); // 更新
      expect(updated.isEquipped, true); // 更新
      expect(updated.description, item.description); // 不變
    });

    test('categoryLabel 正確', () {
      expect(
        ShopItem(
          id: 't1',
          name: 't1',
          category: ShopItemCategory.roomTheme,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '房間',
      );

      expect(
        ShopItem(
          id: 't2',
          name: 't2',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '家具',
      );

      expect(
        ShopItem(
          id: 't3',
          name: 't3',
          category: ShopItemCategory.accessory,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '配件',
      );

      expect(
        ShopItem(
          id: 't4',
          name: 't4',
          category: ShopItemCategory.emotionAnimation,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '動畫',
      );

      expect(
        ShopItem(
          id: 't5',
          name: 't5',
          category: ShopItemCategory.shareTemplate,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '分享卡',
      );

      expect(
        ShopItem(
          id: 't6',
          name: 't6',
          category: ShopItemCategory.seasonalBundle,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).categoryLabel,
        '限定',
      );
    });

    test('unlockLabel 正確', () {
      expect(
        ShopItem(
          id: 't1',
          name: 't1',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.free,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '免費',
      );

      expect(
        ShopItem(
          id: 't2',
          name: 't2',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.bond,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '默契解鎖',
      );

      expect(
        ShopItem(
          id: 't3',
          name: 't3',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.streak,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '連續陪伴解鎖',
      );

      expect(
        ShopItem(
          id: 't4',
          name: 't4',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.paid,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '即將開放',
      );

      expect(
        ShopItem(
          id: 't5',
          name: 't5',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.bundle,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '套組',
      );

      expect(
        ShopItem(
          id: 't6',
          name: 't6',
          category: ShopItemCategory.furniture,
          description: '',
          priceLabel: '',
          unlockType: ShopUnlockType.limited,
          createdAt: DateTime.now(),
        ).unlockLabel,
        '限定',
      );
    });
  });
}
