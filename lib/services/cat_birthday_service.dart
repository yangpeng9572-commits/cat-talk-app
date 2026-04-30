import '../models/cat.dart';

/// 生日禮物建議
class GiftSuggestion {
  final String name;
  final String emoji;
  final String category;

  const GiftSuggestion({
    required this.name,
    required this.emoji,
    required this.category,
  });
}

/// 生日服務
class CatBirthdayService {
  /// 固定禮物清單
  static const List<GiftSuggestion> _giftSuggestions = [
    // 🎾 玩具
    GiftSuggestion(name: '逗貓棒', emoji: '🎾', category: '玩具'),
    GiftSuggestion(name: '鈴鐺球', emoji: '🔔', category: '玩具'),
    GiftSuggestion(name: '貓抓板', emoji: '📄', category: '玩具'),
    // 🍽 食物
    GiftSuggestion(name: '肉泥', emoji: '🍖', category: '食物'),
    GiftSuggestion(name: '主食罐', emoji: '🥫', category: '食物'),
    GiftSuggestion(name: '凍乾', emoji: '❄️', category: '食物'),
    // 🛏 舒適
    GiftSuggestion(name: '貓窩', emoji: '🛏', category: '舒適'),
    GiftSuggestion(name: '小毯子', emoji: '🧸', category: '舒適'),
    GiftSuggestion(name: '床', emoji: '🛌', category: '舒適'),
    // 🏡 空間
    GiftSuggestion(name: '貓跳台', emoji: '🏗', category: '空間'),
    GiftSuggestion(name: '窗邊坐墊', emoji: '🪟', category: '空間'),
    // 🎀 可愛
    GiftSuggestion(name: '生日帽', emoji: '🎀', category: '可愛'),
    GiftSuggestion(name: '領巾', emoji: '👔', category: '可愛'),
    GiftSuggestion(name: '拍照道具', emoji: '📷', category: '可愛'),
  ];

  /// 取得下一個生日日期
  /// - birthdayType=unknown 或 birthdayType=adoptionDay 且無 adoptionDate 時回傳 null
  DateTime? getNextBirthday(Cat cat) {
    if (cat.birthdayType == 'unknown') return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int? birthMonth;
    int? birthDay;
    int birthYear;

    if (cat.birthdayType == 'adoptionDay') {
      // adoptionDay 需要 adoptionDate，但 Cat 模型中沒有 adoptionDate
      // 這裡我們返回 null，讓調用方處理
      return null;
    } else {
      birthMonth = cat.birthMonth;
      birthDay = cat.birthDay;
    }

    if (birthMonth == null || birthDay == null) return null;

    // 處理 2/29 閏年問題
    if (birthMonth == 2 && birthDay == 29) {
      if (!_isLeapYear(now.year)) {
        // 非閏年當 2/28
        birthDay = 28;
      }
    }

    // 取得今年生日
    var thisYearBirthday = DateTime(now.year, birthMonth, birthDay);

    // 如果今年生日已過，回傳明年生日
    if (thisYearBirthday.isBefore(today) || thisYearBirthday.isAtSameMomentAs(today)) {
      var nextBirthday = DateTime(now.year + 1, birthMonth, birthDay);
      // 處理閏年 2/29
      if (birthMonth == 2 && birthDay == 28) {
        // 原本是 2/29，非閏年變 2/28
        if (_isLeapYear(now.year + 1)) {
          // 明年是閏年，但年齡計算時我們用 2/28
        }
      }
      return nextBirthday;
    }

    return thisYearBirthday;
  }

  /// 取得距離生日的天數
  /// - 跨年正確計算（12/31 + 1/1 = 1天）
  int? getDaysUntilBirthday(Cat cat) {
    if (cat.birthdayType == 'unknown') return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int? birthMonth;
    int? birthDay;

    if (cat.birthdayType == 'adoptionDay') {
      // adoptionDay - 需要 adoptionDate，但 Cat 沒有這個欄位
      // 如果需要支援 adoptionDay，請在 Cat 模型中新增 adoptionDate 欄位
      return null;
    } else {
      birthMonth = cat.birthMonth;
      birthDay = cat.birthDay;
    }

    if (birthMonth == null || birthDay == null) return null;

    // 處理 2/29 閏年問題
    if (birthMonth == 2 && birthDay == 29) {
      if (!_isLeapYear(now.year)) {
        birthDay = 28;
      }
    }

    // 取得今年生日
    final thisYearBirthday = DateTime(now.year, birthMonth, birthDay);

    // 如果今年生日已過，計算距離明年生日的天數
    if (thisYearBirthday.isBefore(today)) {
      final nextYearBirthday = DateTime(now.year + 1, birthMonth, birthDay);
      return nextYearBirthday.difference(today).inDays;
    }

    // 今年還沒到生日
    return thisYearBirthday.difference(today).inDays;
  }

  /// 是否今天是生日
  bool isBirthdayToday(Cat cat) {
    if (cat.birthdayType == 'unknown') return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int? birthMonth;
    int? birthDay;

    if (cat.birthdayType == 'adoptionDay') {
      return false;
    } else {
      birthMonth = cat.birthMonth;
      birthDay = cat.birthDay;
    }

    if (birthMonth == null || birthDay == null) return false;

    // 處理 2/29 閏年問題
    if (birthMonth == 2 && birthDay == 29) {
      if (!_isLeapYear(now.year)) {
        birthDay = 28;
      }
    }

    final birthdayThisYear = DateTime(now.year, birthMonth, birthDay);
    return birthdayThisYear.isAtSameMomentAs(today);
  }

  /// 是否明天是生日
  bool isBirthdayTomorrow(Cat cat) {
    if (cat.birthdayType == 'unknown') return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    int? birthMonth;
    int? birthDay;

    if (cat.birthdayType == 'adoptionDay') {
      return false;
    } else {
      birthMonth = cat.birthMonth;
      birthDay = cat.birthDay;
    }

    if (birthMonth == null || birthDay == null) return false;

    // 處理 2/29 閏年問題
    if (birthMonth == 2 && birthDay == 29) {
      if (!_isLeapYear(now.year)) {
        birthDay = 28;
      }
    }

    final birthdayThisYear = DateTime(now.year, birthMonth, birthDay);

    // 如果今年的明天是生日
    if (birthdayThisYear.isAtSameMomentAs(tomorrow)) return true;

    // 如果今年的生日已過，檢查明年的明天
    if (birthdayThisYear.isBefore(today)) {
      final nextYearBirthday = DateTime(now.year + 1, birthMonth, birthDay);
      return nextYearBirthday.isAtSameMomentAs(tomorrow);
    }

    return false;
  }

  /// 取得年齡
  /// - birthdayType=exact 可計算年齡
  /// - birthdayType=monthDayOnly 回傳 null
  int? getAge(Cat cat) {
    if (cat.birthdayType != 'exact') return null;

    if (cat.birthYear == null || cat.birthMonth == null || cat.birthDay == null) {
      return null;
    }

    final now = DateTime.now();
    int age = now.year - cat.birthYear!;

    // 檢查生日是否已過
    final birthdayThisYear = DateTime(
      now.year,
      cat.birthMonth!,
      cat.birthDay!,
    );

    // 處理閏年 2/29 的情況
    var actualBirthdayThisYear = birthdayThisYear;
    if (cat.birthMonth == 2 && cat.birthDay == 29) {
      if (!_isLeapYear(now.year)) {
        // 非閏年，生日當 2/28
        actualBirthdayThisYear = DateTime(now.year, 2, 28);
      }
    }

    if (now.isBefore(actualBirthdayThisYear)) {
      age--;
    }

    return age;
  }

  /// 取得生日訊息
  String getBirthdayMessage(Cat cat) {
    final daysUntil = getDaysUntilBirthday(cat);
    if (daysUntil == null) return '';

    if (daysUntil == 0) {
      return '今天是 ${cat.name} 的生日！🎉';
    } else if (daysUntil == 1) {
      return '明天是 ${cat.name} 的生日 🎂';
    } else {
      return '${cat.name} 生日還有 $daysUntil 天 🎂';
    }
  }

  /// 取得禮物建議
  List<GiftSuggestion> getGiftSuggestions(Cat cat) {
    return _giftSuggestions;
  }

  /// 取得分享文字
  String getShareText(Cat cat) {
    return '今天是 ${cat.name} 的生日 🎂 她又長大了一點，也被更多愛包圍了 🐱💕';
  }

  /// 判斷是否為閏年
  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}
