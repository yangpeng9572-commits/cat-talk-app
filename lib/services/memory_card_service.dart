import 'package:shared_preferences/shared_preferences.dart';

/// 回憶卡片稀有度
enum MemoryCardRarity {
  common,     // 一般
  rare,       // 稀有
  epic,       // 史詩
}

/// 回憶卡片類型
enum MemoryCardType {
  firstFeed,        // 第一次餵她
  firstPlay,        // 第一次陪她玩
  firstPet,         // 第一次摸摸她
  firstTalk,        // 第一次跟她說話
  firstUnlockFurniture,  // 第一次解鎖家具
  firstChangeRoom,  // 第一次換房間
  firstShareDiary,  // 第一次分享小日記
  firstWeekAnalysis, // 第一次完成 7 天分析
  firstBirthday,    // 第一次陪她過生日
}

/// 回憶卡片資料
class MemoryCard {
  final String id;
  final String catId;
  final String title;
  final String description;
  final MemoryCardType type;
  final DateTime? unlockedAt;
  final String icon;
  final MemoryCardRarity rarity;

  MemoryCard({
    required this.id,
    required this.catId,
    required this.title,
    required this.description,
    required this.type,
    this.unlockedAt,
    required this.icon,
    required this.rarity,
  });

  bool get isUnlocked => unlockedAt != null;

  String get rarityLabel {
    switch (rarity) {
      case MemoryCardRarity.common:
        return '';
      case MemoryCardRarity.rare:
        return '✨ 稀有';
      case MemoryCardRarity.epic:
        return '💎 史詩';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'catId': catId,
      'title': title,
      'description': description,
      'type': type.index,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'icon': icon,
      'rarity': rarity.index,
    };
  }

  factory MemoryCard.fromJson(Map<String, dynamic> json) {
    return MemoryCard(
      id: json['id'] as String,
      catId: json['catId'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: MemoryCardType.values[json['type'] as int],
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      icon: json['icon'] as String,
      rarity: MemoryCardRarity.values[json['rarity'] as int],
    );
  }

  MemoryCard copyWith({
    String? id,
    String? catId,
    String? title,
    String? description,
    MemoryCardType? type,
    DateTime? unlockedAt,
    String? icon,
    MemoryCardRarity? rarity,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      catId: catId ?? this.catId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      icon: icon ?? this.icon,
      rarity: rarity ?? this.rarity,
    );
  }
}

/// 回憶卡服務
class MemoryCardService {
  static final MemoryCardService _instance = MemoryCardService._internal();
  factory MemoryCardService() => _instance;
  MemoryCardService._internal();

  static const String _cardsKeyPrefix = 'memory_cards_';

  /// 取得某隻貓的所有回憶卡
  Future<List<MemoryCard>> getMemoryCards(String catId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cardsKeyPrefix + catId;
    final cardsJson = prefs.getStringList(key) ?? [];

    if (cardsJson.isEmpty) {
      // 初始化預設卡片（全部未解鎖）
      return _allCardDefinitions(catId);
    }

    return cardsJson.map((json) {
      final params = Uri.splitQueryString(json);
      return MemoryCard(
        id: params['id'] ?? '',
        catId: params['catId'] ?? catId,
        title: params['title'] ?? '',
        description: params['description'] ?? '',
        type: MemoryCardType.values[int.parse(params['type'] ?? '0')],
        unlockedAt: params['unlockedAt'] != null && params['unlockedAt']!.isNotEmpty
            ? DateTime.parse(params['unlockedAt']!)
            : null,
        icon: params['icon'] ?? '',
        rarity: MemoryCardRarity.values[int.parse(params['rarity'] ?? '0')],
      );
    }).toList();
  }

  List<MemoryCard> _allCardDefinitions(String catId) {
    return [
      MemoryCard(
        id: 'first_feed',
        catId: catId,
        title: '第一次餵她',
        description: '她好像安心了一點 🍽',
        type: MemoryCardType.firstFeed,
        icon: '🍽',
        rarity: MemoryCardRarity.common,
      ),
      MemoryCard(
        id: 'first_play',
        catId: catId,
        title: '第一次陪她玩',
        description: '她今天玩得很開心 🎾',
        type: MemoryCardType.firstPlay,
        icon: '🎾',
        rarity: MemoryCardRarity.common,
      ),
      MemoryCard(
        id: 'first_pet',
        catId: catId,
        title: '第一次摸摸她',
        description: '她好像更放鬆了 💕',
        type: MemoryCardType.firstPet,
        icon: '💕',
        rarity: MemoryCardRarity.common,
      ),
      MemoryCard(
        id: 'first_talk',
        catId: catId,
        title: '第一次跟她說話',
        description: '她有聽到你的聲音了 🐾',
        type: MemoryCardType.firstTalk,
        icon: '🗣',
        rarity: MemoryCardRarity.common,
      ),
      MemoryCard(
        id: 'first_unlock_furniture',
        catId: catId,
        title: '第一次解鎖家具',
        description: '她的小世界多了一點東西 🏠',
        type: MemoryCardType.firstUnlockFurniture,
        icon: '🪑',
        rarity: MemoryCardRarity.rare,
      ),
      MemoryCard(
        id: 'first_change_room',
        catId: catId,
        title: '第一次換房間',
        description: '她的小世界煥然一新 🌈',
        type: MemoryCardType.firstChangeRoom,
        icon: '🏠',
        rarity: MemoryCardRarity.rare,
      ),
      MemoryCard(
        id: 'first_share_diary',
        catId: catId,
        title: '第一次分享小日記',
        description: '想把她的故事說給世界聽 📖',
        type: MemoryCardType.firstShareDiary,
        icon: '📱',
        rarity: MemoryCardRarity.rare,
      ),
      MemoryCard(
        id: 'first_week_analysis',
        catId: catId,
        title: '第一次完成 7 天分析',
        description: '更了解她了，這是個重要的開始 💖',
        type: MemoryCardType.firstWeekAnalysis,
        icon: '📊',
        rarity: MemoryCardRarity.epic,
      ),
      MemoryCard(
        id: 'first_birthday',
        catId: catId,
        title: '第一次陪她過生日 🎉',
        description: '今天是她特別的一天，也被你記住了。',
        type: MemoryCardType.firstBirthday,
        icon: '🎂',
        rarity: MemoryCardRarity.rare,
      ),
    ];
  }

  /// 解鎖回憶卡
  Future<bool> unlockMemoryCard(String catId, MemoryCardType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cardsKeyPrefix + catId;
    final cards = await getMemoryCards(catId);

    // 找對應的卡片
    final cardIndex = cards.indexWhere((c) => c.type == type);
    if (cardIndex == -1) return false;

    // 已解鎖的不重複解鎖
    if (cards[cardIndex].isUnlocked) return false;

    // 更新卡片
    cards[cardIndex] = cards[cardIndex].copyWith(
      unlockedAt: DateTime.now(),
    );

    // 儲存
    await prefs.setStringList(
      key,
      cards.map((c) => _cardToString(c)).toList(),
    );

    return true;
  }

  /// 檢查是否已解鎖（依 ID）
  Future<bool> isUnlocked(String catId, String cardId) async {
    final cards = await getMemoryCards(catId);
    final card = cards.where((c) => c.id == cardId).firstOrNull;
    return card?.isUnlocked ?? false;
  }

  /// 檢查是否已解鎖（依類型）
  Future<bool> isTypeUnlocked(String catId, MemoryCardType type) async {
    final cards = await getMemoryCards(catId);
    final card = cards.where((c) => c.type == type).firstOrNull;
    return card?.isUnlocked ?? false;
  }

  String _cardToString(MemoryCard card) {
    return 'id=${Uri.encodeComponent(card.id)}'
        '&catId=${Uri.encodeComponent(card.catId)}'
        '&title=${Uri.encodeComponent(card.title)}'
        '&description=${Uri.encodeComponent(card.description)}'
        '&type=${card.type.index}'
        '&unlockedAt=${Uri.encodeComponent(card.unlockedAt?.toIso8601String() ?? '')}'
        '&icon=${Uri.encodeComponent(card.icon)}'
        '&rarity=${card.rarity.index}';
  }
}