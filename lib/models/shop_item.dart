/// 商店物品分類
enum ShopItemCategory {
  roomTheme,      // 房間主題
  furniture,      // 家具
  accessory,      // 配件
  emotionAnimation, // 情緒動畫
  shareTemplate,  // 分享卡模板
  seasonalBundle, // 季節限定套組
}

/// 商店物品解鎖類型
enum ShopUnlockType {
  free,      // 免費
  bond,      // 默契值解鎖
  streak,    // 連續陪伴解鎖
  paid,      // 即將開放（付費）
  bundle,    // 套組
  limited,   // 限定
}

/// 商店物品模型
/// 用於未來房間主題、家具、配件、動畫、分享卡等
class ShopItem {
  final String id;
  final String name;
  final ShopItemCategory category;
  final String description;
  final String priceLabel;
  final ShopUnlockType unlockType;
  final int? requiredBondScore;
  final int? requiredStreakDays;
  final bool isUnlocked;
  final bool isEquipped;
  final String? previewImageAsset;
  final List<String> tags;
  final DateTime createdAt;

  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.priceLabel,
    required this.unlockType,
    this.requiredBondScore,
    this.requiredStreakDays,
    this.isUnlocked = false,
    this.isEquipped = false,
    this.previewImageAsset,
    this.tags = const [],
    required this.createdAt,
  });

  /// 從 JSON 建立
  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ShopItemCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ShopItemCategory.roomTheme,
      ),
      description: json['description'] as String,
      priceLabel: json['priceLabel'] as String,
      unlockType: ShopUnlockType.values.firstWhere(
        (e) => e.name == json['unlockType'],
        orElse: () => ShopUnlockType.free,
      ),
      requiredBondScore: json['requiredBondScore'] as int?,
      requiredStreakDays: json['requiredStreakDays'] as int?,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      isEquipped: json['isEquipped'] as bool? ?? false,
      previewImageAsset: json['previewImageAsset'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 轉換為 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'description': description,
      'priceLabel': priceLabel,
      'unlockType': unlockType.name,
      'requiredBondScore': requiredBondScore,
      'requiredStreakDays': requiredStreakDays,
      'isUnlocked': isUnlocked,
      'isEquipped': isEquipped,
      'previewImageAsset': previewImageAsset,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// 複製並更新指定欄位
  ShopItem copyWith({
    String? id,
    String? name,
    ShopItemCategory? category,
    String? description,
    String? priceLabel,
    ShopUnlockType? unlockType,
    int? requiredBondScore,
    int? requiredStreakDays,
    bool? isUnlocked,
    bool? isEquipped,
    String? previewImageAsset,
    List<String>? tags,
    DateTime? createdAt,
  }) {
    return ShopItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      priceLabel: priceLabel ?? this.priceLabel,
      unlockType: unlockType ?? this.unlockType,
      requiredBondScore: requiredBondScore ?? this.requiredBondScore,
      requiredStreakDays: requiredStreakDays ?? this.requiredStreakDays,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isEquipped: isEquipped ?? this.isEquipped,
      previewImageAsset: previewImageAsset ?? this.previewImageAsset,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 分類標籤（中文）
  String get categoryLabel {
    switch (category) {
      case ShopItemCategory.roomTheme:
        return '房間';
      case ShopItemCategory.furniture:
        return '家具';
      case ShopItemCategory.accessory:
        return '配件';
      case ShopItemCategory.emotionAnimation:
        return '動畫';
      case ShopItemCategory.shareTemplate:
        return '分享卡';
      case ShopItemCategory.seasonalBundle:
        return '限定';
    }
  }

  /// 解鎖方式標籤（中文）
  String get unlockLabel {
    switch (unlockType) {
      case ShopUnlockType.free:
        return '免費';
      case ShopUnlockType.bond:
        return '默契解鎖';
      case ShopUnlockType.streak:
        return '連續陪伴解鎖';
      case ShopUnlockType.paid:
        return '即將開放';
      case ShopUnlockType.bundle:
        return '套組';
      case ShopUnlockType.limited:
        return '限定';
    }
  }
}
