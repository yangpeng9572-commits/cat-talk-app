/// 季節活動服務
class SeasonalEventService {
  static final SeasonalEventService _instance = SeasonalEventService._internal();
  factory SeasonalEventService() => _instance;
  SeasonalEventService._internal();

  /// 取得目前進行的活動（無則回傳 null）
  SeasonalEvent? getCurrentEvent() {
    final now = DateTime.now();

    for (final event in _allEvents) {
      if (now.isAfter(event.startDate) && now.isBefore(event.endDate)) {
        return event;
      }
    }
    return null;
  }

  /// 取得所有活動（不論是否在期間內）
  List<SeasonalEvent> getAllEvents() => List.unmodifiable(_allEvents);

  /// 檢查是否在活動期間
  bool isInEvent(SeasonalEvent event) {
    final now = DateTime.now();
    return now.isAfter(event.startDate) && now.isBefore(event.endDate);
  }

  /// 取得活動限定的解鎖商品 ID 列表
  List<String> getEventItemIds(SeasonalEvent event) => event.unlockableItemIds;

  // ===== 活動定義 =====
  static final List<SeasonalEvent> _allEvents = [
    // 春日櫻花活動（3-4月）
    SeasonalEvent(
      id: 'spring_sakura_2026',
      name: '春日櫻花 🌸',
      description: '春天來了，和她一起看櫻花吧',
      themeColor: 0xFFFFB7C5,
      icon: '🌸',
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 4, 30),
      unlockableItemIds: [
        'room_sakura_櫻花房',
        'furniture_sakura_貓窩',
        'furniture_sakura_地墊',
        'accessory_sakura_項圈',
        'share_sakura_櫻花卡',
      ],
    ),
    // 夏日窗邊活動（5-8月）
    SeasonalEvent(
      id: 'summer_window_2026',
      name: '夏日窗邊 ☀️',
      description: '夏天的午後，和她一起吹涼涼的風',
      themeColor: 0xFF87CEEB,
      icon: '☀️',
      startDate: DateTime(2026, 5, 1),
      endDate: DateTime(2026, 8, 31),
      unlockableItemIds: [
        'room_summer_窗邊房',
        'furniture_summer_涼墊',
        'furniture_summer_小風扇',
        'accessory_summer_曬太陽墨镜',
        'share_summer_夏日卡',
      ],
    ),
    // 萬聖節小搗蛋（10月）
    SeasonalEvent(
      id: 'halloween_2026',
      name: '萬聖節小搗蛋 🎃',
      description: '不给糖就捣蛋！一起度过可爱的万圣节吧',
      themeColor: 0xFFFF9800,
      icon: '🎃',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      unlockableItemIds: [
        'room_halloween_南瓜房',
        'furniture_halloween_糖果籃',
        'furniture_halloween_蜘蛛網',
        'accessory_halloween_巫婆帽',
        'share_halloween_萬聖節卡',
      ],
    ),
    // 聖誕暖暖（12月）
    SeasonalEvent(
      id: 'christmas_2025',
      name: '聖誕暖暖 🎄',
      description: '聖誕節，和她一起溫暖過冬',
      themeColor: 0xFFE53935,
      icon: '🎄',
      startDate: DateTime(2025, 12, 1),
      endDate: DateTime(2026, 1, 7),
      unlockableItemIds: [
        'room_christmas_聖誕房',
        'furniture_christmas_聖誕樹',
        'furniture_christmas_襪子',
        'accessory_christmas_聖誕項圈',
        'share_christmas_聖誕卡',
      ],
    ),
    // 生日派對（貓咪生日，固定日期）
    SeasonalEvent(
      id: 'birthday_party',
      name: '生日派對 🎂',
      description: '今天是她的大日子！一起慶祝吧 🎉',
      themeColor: 0xFFFF8FAB,
      icon: '🎂',
      startDate: DateTime(2026, 1, 1),
      endDate: DateTime(2027, 12, 31), // 全年都可紀念
      unlockableItemIds: [
        'room_birthday_派對房',
        'furniture_birthday_蛋糕',
        'furniture_birthday_氣球',
        'accessory_birthday_生日帽',
        'share_birthday_生日卡',
      ],
    ),
  ];
}

/// 季節活動資料
class SeasonalEvent {
  final String id;
  final String name;
  final String description;
  final int themeColor; // 活動主題色（HEX）
  final String icon;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> unlockableItemIds; // 可透過活動解鎖的商品 ID

  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.themeColor,
    required this.icon,
    required this.startDate,
    required this.endDate,
    required this.unlockableItemIds,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  Duration get remainingTime {
    final now = DateTime.now();
    if (!isActive) return Duration.zero;
    return endDate.difference(now);
  }

  String get remainingText {
    final remaining = remainingTime;
    if (remaining.inDays > 0) {
      return '還剩 ${remaining.inDays} 天';
    } else if (remaining.inHours > 0) {
      return '還剩 ${remaining.inHours} 小時';
    } else {
      return '即將結束';
    }
  }
}