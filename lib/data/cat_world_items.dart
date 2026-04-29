import '../models/shop_item.dart';

/// 她的小世界 - 商品資料庫
/// 包含房間主題、家具、配件、動畫、分享卡、季節套組
class CatWorldItems {
  CatWorldItems._();

  // ==================== 免費初始內容 ====================

  /// 初始小房間
  static final ShopItem _defaultRoom = ShopItem(
    id: 'room_default',
    name: '初始小房間',
    category: ShopItemCategory.roomTheme,
    description: '她的小角落，從今天開始慢慢變溫暖。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  // 免費家具
  static final ShopItem _basicFoodBowl = ShopItem(
    id: 'furniture_food_bowl_basic',
    name: '基本食碗',
    category: ShopItemCategory.furniture,
    description: '吃飯時間到！',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _basicWaterBowl = ShopItem(
    id: 'furniture_water_bowl_basic',
    name: '基本水碗',
    category: ShopItemCategory.furniture,
    description: '隨時都有乾淨的水喝。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _smallRug = ShopItem(
    id: 'furniture_rug_small',
    name: '小地毯',
    category: ShopItemCategory.furniture,
    description: '軟軟的，踩起來很舒服。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _cardboardBox = ShopItem(
    id: 'furniture_cardboard_box',
    name: '紙箱',
    category: ShopItemCategory.furniture,
    description: '貓咪的最愛，鑽進去就不想出來。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  // 免費配件
  static final ShopItem _noAccessory = ShopItem(
    id: 'accessory_none',
    name: '無配件',
    category: ShopItemCategory.accessory,
    description: '自然就是最美的樣子。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _basicBellCollar = ShopItem(
    id: 'accessory_bell_collar_basic',
    name: '小鈴鐺項圈',
    category: ShopItemCategory.accessory,
    description: '走起路來叮叮噹噹的，很可愛。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  // 免費動畫
  static final ShopItem _blinkAnimation = ShopItem(
    id: 'animation_blink',
    name: '眨眼',
    category: ShopItemCategory.emotionAnimation,
    description: '對你眨眨眼，代表信任。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _tailWagAnimation = ShopItem(
    id: 'animation_tail_wag',
    name: '尾巴輕動',
    category: ShopItemCategory.emotionAnimation,
    description: '悠閒地搖搖尾巴。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _smallJumpAnimation = ShopItem(
    id: 'animation_small_jump',
    name: '小跳一下',
    category: ShopItemCategory.emotionAnimation,
    description: '突然跳一下，很活潑。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  // 免費分享卡
  static final ShopItem _basicPinkCard = ShopItem(
    id: 'share_basic_pink',
    name: '基本粉色卡',
    category: ShopItemCategory.shareTemplate,
    description: '簡單可愛的粉色分享卡。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 房間主題 ====================

  static final ShopItem _milkTeaAfternoonRoom = ShopItem(
    id: 'room_milk_tea_afternoon',
    name: '奶茶午後房',
    category: ShopItemCategory.roomTheme,
    description: '午後的陽光剛剛好，她可以懶懶地躺一整天。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _pinkCuddleRoom = ShopItem(
    id: 'room_pink_cuddle',
    name: '粉紅撒嬌房',
    category: ShopItemCategory.roomTheme,
    description: '給今天想撒嬌的她，一個粉粉的小世界。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 50,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _starrySleepRoom = ShopItem(
    id: 'room_starry_sleep',
    name: '星空安睡房',
    category: ShopItemCategory.roomTheme,
    description: '夜晚安靜下來，她也想被溫柔陪著。',
    priceLabel: '連續陪伴解鎖',
    unlockType: ShopUnlockType.streak,
    requiredStreakDays: 7,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _forestWindowRoom = ShopItem(
    id: 'room_forest_window',
    name: '森林窗邊房',
    category: ShopItemCategory.roomTheme,
    description: '窗外有微風，她在安全的小角落觀察世界。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 70,
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _birthdayPartyRoom = ShopItem(
    id: 'room_birthday_party',
    name: '生日派對房',
    category: ShopItemCategory.roomTheme,
    description: '今天是她的小派對，房間也要有儀式感。',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 家具 - 貓窩 ====================

  static final ShopItem _butterCatBed = ShopItem(
    id: 'furniture_cat_bed_butter',
    name: '奶油圓形貓窩',
    category: ShopItemCategory.furniture,
    description: '圓圓的像奶油一樣，躺起來很舒服。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['貓窩', '奶油色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _cloudCatBed = ShopItem(
    id: 'furniture_cat_bed_cloud',
    name: '雲朵貓窩',
    category: ShopItemCategory.furniture,
    description: '像雲朵一樣軟軟的，做夢都會笑。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 40,
    tags: ['貓窩', '白色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _strawberryCatBed = ShopItem(
    id: 'furniture_cat_bed_strawberry',
    name: '草莓貓窩',
    category: ShopItemCategory.furniture,
    description: '粉紅草莓造型，看了好想咬一口。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 50,
    tags: ['貓窩', '粉色', '草莓'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _moonCatBed = ShopItem(
    id: 'furniture_cat_bed_moon',
    name: '月亮貓窩',
    category: ShopItemCategory.furniture,
    description: '躺在月亮上做夢，聽起來很浪漫。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 60,
    tags: ['貓窩', '月亮', '夜晚'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _cardboardCatBed = ShopItem(
    id: 'furniture_cat_bed_cardboard',
    name: '紙箱貓窩',
    category: ShopItemCategory.furniture,
    description: '紙箱永遠是貓咪的最愛。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    tags: ['貓窩', '紙箱'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _wickerCatBed = ShopItem(
    id: 'furniture_cat_bed_wicker',
    name: '藤編貓窩',
    category: ShopItemCategory.furniture,
    description: '自然風格的藤編設計，很有質感。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 35,
    tags: ['貓窩', '藤編', '自然'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _tentCatBed = ShopItem(
    id: 'furniture_cat_bed_tent',
    name: '小帳篷貓窩',
    category: ShopItemCategory.furniture,
    description: '有自己的小帳篷，隱私感滿滿。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 45,
    tags: ['貓窩', '帳篷'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 家具 - 食物區 ====================

  static final ShopItem _ceramicFoodBowl = ShopItem(
    id: 'furniture_ceramic_food_bowl',
    name: '陶瓷食碗',
    category: ShopItemCategory.furniture,
    description: '有質感的陶瓷碗，吃飯也要美美的。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['食物區', '陶瓷', '粉色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _heartWaterBowl = ShopItem(
    id: 'furniture_heart_water_bowl',
    name: '愛心水碗',
    category: ShopItemCategory.furniture,
    description: '愛心造型，看到就想喝水。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['食物區', '愛心', '粉色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _milkTeaPlacemat = ShopItem(
    id: 'furniture_milk_tea_placemat',
    name: '奶茶色餐墊',
    category: ShopItemCategory.furniture,
    description: '和家裡的奶茶色裝潢很配。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['食物區', '奶茶色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _fishPlate = ShopItem(
    id: 'furniture_fish_plate',
    name: '小魚餐盤',
    category: ShopItemCategory.furniture,
    description: '小魚造型，貓咪看了胃口大開。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['食物區', '小魚', '可愛'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _pinkDoubleBowl = ShopItem(
    id: 'furniture_pink_double_bowl',
    name: '粉色雙碗架',
    category: ShopItemCategory.furniture,
    description: '一邊放食物一邊放水，很方便。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['食物區', '雙碗', '粉色'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 家具 - 玩具 ====================

  static final ShopItem _catFeather = ShopItem(
    id: 'furniture_cat_feather',
    name: '逗貓棒',
    category: ShopItemCategory.furniture,
    description: '羽毛晃啊晃，她會瘋狂跳躍。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    tags: ['玩具', '逗貓棒'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _yarnBall = ShopItem(
    id: 'furniture_yarn_ball',
    name: '毛球球',
    category: ShopItemCategory.furniture,
    description: '滾來滾去的，她可以玩一整個下午。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 10,
    tags: ['玩具', '毛線球'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _mouseToy = ShopItem(
    id: 'furniture_mouse_toy',
    name: '小老鼠玩具',
    category: ShopItemCategory.furniture,
    description: '小老鼠會發出逼逼聲，很逼真。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['玩具', '老鼠'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _fishPillow = ShopItem(
    id: 'furniture_fish_pillow',
    name: '魚魚抱枕',
    category: ShopItemCategory.furniture,
    description: '魚造型抱枕，可以咬可以抱。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['玩具', '抱枕', '小魚'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _butterflyToy = ShopItem(
    id: 'furniture_butterfly_toy',
    name: '蝴蝶玩具',
    category: ShopItemCategory.furniture,
    description: '蝴蝶翩翩飛，她會追著跑。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['玩具', '蝴蝶'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _bellBall = ShopItem(
    id: 'furniture_bell_ball',
    name: '鈴鐺球',
    category: ShopItemCategory.furniture,
    description: '滾動時會叮叮響，很有趣。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['玩具', '鈴鐺', '球'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _paperBag = ShopItem(
    id: 'furniture_paper_bag',
    name: '紙袋',
    category: ShopItemCategory.furniture,
    description: '紙袋窸窸窣窣的聲音，她最喜歡了。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    tags: ['玩具', '紙袋'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _largeCardboardBox = ShopItem(
    id: 'furniture_large_cardboard_box',
    name: '大紙箱',
    category: ShopItemCategory.furniture,
    description: '大一點的紙箱，可以整隻鑽進去。',
    priceLabel: '免費',
    unlockType: ShopUnlockType.free,
    isUnlocked: true,
    tags: ['玩具', '紙箱'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 家具 - 休息 ====================

  static final ShopItem _smallSofa = ShopItem(
    id: 'furniture_small_sofa',
    name: '小沙發',
    category: ShopItemCategory.furniture,
    description: '迷你小沙發，她也可以當貴婦。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 50,
    tags: ['休息', '沙發'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _throwPillow = ShopItem(
    id: 'furniture_throw_pillow',
    name: '靠枕',
    category: ShopItemCategory.furniture,
    description: '軟軟的靠枕，躺起來更舒服。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['休息', '靠枕'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _smallBlanket = ShopItem(
    id: 'furniture_small_blanket',
    name: '小毯子',
    category: ShopItemCategory.furniture,
    description: '冬天窩在小毯子裡很溫暖。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['休息', '毯子'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _windowCushion = ShopItem(
    id: 'furniture_window_cushion',
    name: '窗邊坐墊',
    category: ShopItemCategory.furniture,
    description: '放在窗邊，看風景的最佳位置。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['休息', '窗邊', '坐墊'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _warmMat = ShopItem(
    id: 'furniture_warm_mat',
    name: '暖暖地墊',
    category: ShopItemCategory.furniture,
    description: '保暖效果很好，冬天再也不冷。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['休息', '保暖', '地墊'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _smallTable = ShopItem(
    id: 'furniture_small_table',
    name: '小桌子',
    category: ShopItemCategory.furniture,
    description: '可以放一些小玩具或零食。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['裝飾', '桌子'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 家具 - 裝飾 ====================

  static final ShopItem _starLightString = ShopItem(
    id: 'furniture_star_light_string',
    name: '星星燈串',
    category: ShopItemCategory.furniture,
    description: '夜晚亮起來，房間超有氣氛。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 40,
    tags: ['裝飾', '燈串', '星星'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _heartWallSticker = ShopItem(
    id: 'furniture_heart_wall_sticker',
    name: '愛心牆貼',
    category: ShopItemCategory.furniture,
    description: '粉粉的愛心，讓房間更溫馨。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['裝飾', '牆貼', '愛心'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _photoFrame = ShopItem(
    id: 'furniture_photo_frame',
    name: '相框',
    category: ShopItemCategory.furniture,
    description: '可以放她的照片或你們的合照。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['裝飾', '相框'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _fishWallArt = ShopItem(
    id: 'furniture_fish_wall_art',
    name: '小魚掛畫',
    category: ShopItemCategory.furniture,
    description: '可愛的小魚掛畫，很有療癒感。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['裝飾', '掛畫', '小魚'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _catPawRug = ShopItem(
    id: 'furniture_cat_paw_rug',
    name: '貓爪地毯',
    category: ShopItemCategory.furniture,
    description: '肉球踩上去一定很舒服。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['裝飾', '地毯', '貓爪'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _curtain = ShopItem(
    id: 'furniture_curtain',
    name: '窗簾',
    category: ShopItemCategory.furniture,
    description: '奶茶色的窗簾，很溫柔的感覺。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 35,
    tags: ['裝飾', '窗簾'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _nightLight = ShopItem(
    id: 'furniture_night_light',
    name: '小夜燈',
    category: ShopItemCategory.furniture,
    description: '夜晚提供柔和的光線，她不會害怕。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['裝飾', '夜燈'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _wallClock = ShopItem(
    id: 'furniture_wall_clock',
    name: '時鐘',
    category: ShopItemCategory.furniture,
    description: '可愛造型的時鐘，貓咪也會看時間嗎？',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['裝飾', '時鐘'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 配件 ====================

  static final ShopItem _milkTeaBow = ShopItem(
    id: 'accessory_milk_tea_bow',
    name: '奶茶色蝴蝶結',
    category: ShopItemCategory.accessory,
    description: '奶茶色的蝴蝶結，優雅又可愛。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['配件', '蝴蝶結', '奶茶色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _pinkScarf = ShopItem(
    id: 'accessory_pink_scarf',
    name: '粉色小圍巾',
    category: ShopItemCategory.accessory,
    description: '冬天的小圍巾，保暖又時尚。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 25,
    tags: ['配件', '圍巾', '粉色'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _starHairClip = ShopItem(
    id: 'accessory_star_hair_clip',
    name: '小星星髮夾',
    category: ShopItemCategory.accessory,
    description: '閃亮亮的小星星，拍照很上鏡。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 15,
    tags: ['配件', '髮夾', '星星'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _fishTag = ShopItem(
    id: 'accessory_fish_tag',
    name: '小魚吊牌',
    category: ShopItemCategory.accessory,
    description: '小魚造型吊牌，搖搖晃晃很可愛。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 20,
    tags: ['配件', '吊牌', '小魚'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _cloudBib = ShopItem(
    id: 'accessory_cloud_bib',
    name: '雲朵圍兜',
    category: ShopItemCategory.accessory,
    description: '吃飯的時候可以戴，防止弄髒衣服。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['配件', '圍兜', '雲朵'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _strawberryBowTie = ShopItem(
    id: 'accessory_strawberry_bow_tie',
    name: '草莓小領巾',
    category: ShopItemCategory.accessory,
    description: '草莓造型的領巾，看了好想吃。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 35,
    tags: ['配件', '領巾', '草莓'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _birthdayHat = ShopItem(
    id: 'accessory_birthday_hat',
    name: '生日小帽',
    category: ShopItemCategory.accessory,
    description: '生日派對必備的小帽子。',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['配件', '生日', '帽子'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _christmasScarf = ShopItem(
    id: 'accessory_christmas_scarf',
    name: '聖誕紅圍巾',
    category: ShopItemCategory.accessory,
    description: '聖誕節氣氛滿滿的紅色圍巾。',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['配件', '聖誕', '圍巾'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _sakuraHairAccessory = ShopItem(
    id: 'accessory_sakura_hair',
    name: '櫻花髮飾',
    category: ShopItemCategory.accessory,
    description: '春天感的櫻花髮飾，很有儀式感。',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['配件', '櫻花', '春天'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 動畫 ====================

  static final ShopItem _cuddleAnimation = ShopItem(
    id: 'animation_cuddle',
    name: '撒嬌動畫',
    category: ShopItemCategory.emotionAnimation,
    description: '她會滾過來撒嬌要摸摸。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 40,
    tags: ['動畫', '撒嬌'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _happyAnimation = ShopItem(
    id: 'animation_happy',
    name: '開心動畫',
    category: ShopItemCategory.emotionAnimation,
    description: '尾巴豎高高，她現在很開心。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 35,
    tags: ['動畫', '開心'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _eatingAnimation = ShopItem(
    id: 'animation_eating',
    name: '吃飯動畫',
    category: ShopItemCategory.emotionAnimation,
    description: '埋頭苦幹的吃飯畫面，很療癒。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['動畫', '吃飯'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _sleepingAnimation = ShopItem(
    id: 'animation_sleeping',
    name: '睡覺動畫',
    category: ShopItemCategory.emotionAnimation,
    description: '睡成一坨，毛茸茸的超可愛。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 45,
    tags: ['動畫', '睡覺'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _boxSurpriseAnimation = ShopItem(
    id: 'animation_box_surprise',
    name: '紙箱驚喜動畫',
    category: ShopItemCategory.emotionAnimation,
    description: '突然發現紙箱的驚喜表情。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 50,
    tags: ['動畫', '紙箱', '驚喜'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 分享卡模板 ====================

  static final ShopItem _milkTeaDiaryTemplate = ShopItem(
    id: 'share_milk_tea_diary',
    name: '奶茶日記模板',
    category: ShopItemCategory.shareTemplate,
    description: '奶茶色系的每日日記分享卡。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 30,
    tags: ['分享卡', '奶茶色', '日記'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _pinkCuddleTemplate = ShopItem(
    id: 'share_pink_cuddle',
    name: '粉紅撒嬌模板',
    category: ShopItemCategory.shareTemplate,
    description: '粉紅色的撒嬌風格分享卡。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 50,
    tags: ['分享卡', '粉色', '撒嬌'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _starryNightTemplate = ShopItem(
    id: 'share_starry_night',
    name: '星空晚安模板',
    category: ShopItemCategory.shareTemplate,
    description: '夜晚星空感的晚安分享卡。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 60,
    tags: ['分享卡', '星空', '晚安'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _cuteComicTemplate = ShopItem(
    id: 'share_cute_comic',
    name: '可愛漫畫模板',
    category: ShopItemCategory.shareTemplate,
    description: '漫畫風格的有趣分享卡。',
    priceLabel: '默契解鎖',
    unlockType: ShopUnlockType.bond,
    requiredBondScore: 40,
    tags: ['分享卡', '漫畫', '可愛'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _birthdayPartyTemplate = ShopItem(
    id: 'share_birthday_party',
    name: '生日派對模板',
    category: ShopItemCategory.shareTemplate,
    description: '生日派對風格的慶祝分享卡。',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['分享卡', '生日', '派對'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 季節限定套組 ====================

  static final ShopItem _springSakuraSet = ShopItem(
    id: 'bundle_spring_sakura',
    name: '春日櫻花套組',
    category: ShopItemCategory.seasonalBundle,
    description: '🌸 包含：櫻花髮飾、粉色小窩、奶茶地毯',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['套組', '春天', '櫻花'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _summerWindowSet = ShopItem(
    id: 'bundle_summer_window',
    name: '夏日窗邊套組',
    category: ShopItemCategory.seasonalBundle,
    description: '☀️ 包含：窗邊坐墊、小夜燈、星星燈串',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['套組', '夏天', '窗邊'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _halloweenSet = ShopItem(
    id: 'bundle_halloween',
    name: '萬聖節小搗蛋套組',
    category: ShopItemCategory.seasonalBundle,
    description: '🎃 包含：南瓜小窩、巫師帽配件、小老鼠玩具',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['套組', '萬聖節', '南瓜'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _christmasSet = ShopItem(
    id: 'bundle_christmas',
    name: '聖誕暖暖套組',
    category: ShopItemCategory.seasonalBundle,
    description: '🎄 包含：聖誕紅圍巾、暖暖地墊、小襖子',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['套組', '聖誕', '冬天'],
    createdAt: DateTime(2026, 4, 1),
  );

  static final ShopItem _birthdaySet = ShopItem(
    id: 'bundle_birthday',
    name: '生日派對套組',
    category: ShopItemCategory.seasonalBundle,
    description: '🎂 包含：生日小帽、派對房、氣球玩具',
    priceLabel: '限定',
    unlockType: ShopUnlockType.limited,
    tags: ['套組', '生日', '派對'],
    createdAt: DateTime(2026, 4, 1),
  );

  // ==================== 靜態列表 ====================

  /// 所有商品
  static List<ShopItem> get allItems => [
        // 免費
        _defaultRoom,
        _basicFoodBowl,
        _basicWaterBowl,
        _smallRug,
        _cardboardBox,
        _noAccessory,
        _basicBellCollar,
        _blinkAnimation,
        _tailWagAnimation,
        _smallJumpAnimation,
        _basicPinkCard,
        _catFeather,
        _paperBag,
        _largeCardboardBox,
        _cardboardCatBed,
        // 房間主題
        _milkTeaAfternoonRoom,
        _pinkCuddleRoom,
        _starrySleepRoom,
        _forestWindowRoom,
        _birthdayPartyRoom,
        // 貓窩
        _butterCatBed,
        _cloudCatBed,
        _strawberryCatBed,
        _moonCatBed,
        _wickerCatBed,
        _tentCatBed,
        // 食物區
        _ceramicFoodBowl,
        _heartWaterBowl,
        _milkTeaPlacemat,
        _fishPlate,
        _pinkDoubleBowl,
        // 玩具
        _yarnBall,
        _mouseToy,
        _fishPillow,
        _butterflyToy,
        _bellBall,
        // 休息
        _smallSofa,
        _throwPillow,
        _smallBlanket,
        _windowCushion,
        _warmMat,
        _smallTable,
        // 裝飾
        _starLightString,
        _heartWallSticker,
        _photoFrame,
        _fishWallArt,
        _catPawRug,
        _curtain,
        _nightLight,
        _wallClock,
        // 配件
        _milkTeaBow,
        _pinkScarf,
        _starHairClip,
        _fishTag,
        _cloudBib,
        _strawberryBowTie,
        _birthdayHat,
        _christmasScarf,
        _sakuraHairAccessory,
        // 動畫
        _cuddleAnimation,
        _happyAnimation,
        _eatingAnimation,
        _sleepingAnimation,
        _boxSurpriseAnimation,
        // 分享卡
        _milkTeaDiaryTemplate,
        _pinkCuddleTemplate,
        _starryNightTemplate,
        _cuteComicTemplate,
        _birthdayPartyTemplate,
        // 季節套組
        _springSakuraSet,
        _summerWindowSet,
        _halloweenSet,
        _christmasSet,
        _birthdaySet,
      ];

  /// 免費商品
  static List<ShopItem> get freeItems =>
      allItems.where((i) => i.unlockType == ShopUnlockType.free).toList();

  /// 房間主題
  static List<ShopItem> get roomThemes =>
      allItems.where((i) => i.category == ShopItemCategory.roomTheme).toList();

  /// 家具（不含食物區、玩具、休息、裝飾）
  static List<ShopItem> get furnitureItems => allItems
      .where((i) =>
          i.category == ShopItemCategory.furniture &&
          i.id.contains('bed') ||
          i.id.contains('sofa') ||
          i.id.contains('pillow') ||
          i.id.contains('blanket') ||
          i.id.contains('cushion') ||
          i.id.contains('mat') ||
          i.id.contains('table'))
      .toList();

  /// 食物區家具
  static List<ShopItem> get foodAreaItems => allItems
      .where((i) =>
          i.category == ShopItemCategory.furniture &&
          (i.id.contains('bowl') ||
              i.id.contains('placemat') ||
              i.id.contains('plate')))
      .toList();

  /// 玩具家具
  static List<ShopItem> get toyItems => allItems
      .where((i) =>
          i.category == ShopItemCategory.furniture &&
          (i.id.contains('feather') ||
              i.id.contains('yarn') ||
              i.id.contains('mouse') ||
              i.id.contains('pillow') ||
              i.id.contains('butterfly') ||
              i.id.contains('bell') ||
              i.id.contains('paper') ||
              i.id.contains('cardboard') ||
              i.id.contains('box')))
      .toList();

  /// 裝飾家具
  static List<ShopItem> get decorItems => allItems
      .where((i) =>
          i.category == ShopItemCategory.furniture &&
          (i.id.contains('light') ||
              i.id.contains('sticker') ||
              i.id.contains('frame') ||
              i.id.contains('art') ||
              i.id.contains('rug') ||
              i.id.contains('curtain') ||
              i.id.contains('clock')))
      .toList();

  /// 配件
  static List<ShopItem> get accessoryItems =>
      allItems.where((i) => i.category == ShopItemCategory.accessory).toList();

  /// 動畫
  static List<ShopItem> get animationItems =>
      allItems.where((i) => i.category == ShopItemCategory.emotionAnimation).toList();

  /// 分享卡模板
  static List<ShopItem> get shareTemplateItems =>
      allItems.where((i) => i.category == ShopItemCategory.shareTemplate).toList();

  /// 季節限定套組
  static List<ShopItem> get seasonalBundleItems =>
      allItems.where((i) => i.category == ShopItemCategory.seasonalBundle).toList();
}
