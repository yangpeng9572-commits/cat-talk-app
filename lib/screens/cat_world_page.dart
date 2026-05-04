import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cat_world_items.dart';
import '../models/cat.dart';
import '../models/daily_task.dart';
import '../models/shop_item.dart';
import '../services/cat_world_service.dart';
import '../services/cat_service.dart';
import '../services/bond_service.dart';
import '../services/streak_service.dart';
import '../services/memory_card_service.dart';
import '../services/seasonal_event_service.dart';
import '../services/cat_birthday_service.dart';
import '../services/daily_task_service.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';
import 'memory_cards_page.dart';
import 'summer_window_page.dart';

/// 她的小世界 🏡 - 商店頁面
class CatWorldPage extends StatefulWidget {
  const CatWorldPage({super.key});

  @override
  State<CatWorldPage> createState() => _CatWorldPageState();
}

class _CatWorldPageState extends State<CatWorldPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CatWorldService _catWorldService = CatWorldService();

  String? _currentCatId;
  int _currentBondScore = 0;
  int _currentStreakDays = 0;
  List<ShopItem> _displayItems = [];
  bool _isLoading = true;

  // 已裝備狀態
  String? _equippedRoomId;
  List<String> _equippedFurnitureIds = [];
  List<String> _equippedAccessoryIds = [];
  List<String> _equippedAnimationIds = [];

  // 今日互動狀態
  int _todayInteractions = 0;
  int _todayBondFromRoom = 0;
  bool _surpriseShownToday = false;

  // 生日服務
  final CatBirthdayService _birthdayService = CatBirthdayService();
  Cat? _birthdayCatToday;

  static const int _maxDailyInteractions = 5;
  static const int _maxDailyBondFromRoom = 3;
  static const int _bondPerInteraction = 1;

  // 分類標籤（已隱藏 分享卡/動畫 tab — P2-1）
  static const List<String> _tabLabels = [
    '房間',
    '家具',
    '配件',
    '限定',
  ];

  // Tab 對應的分類
  static const List<ShopItemCategory> _categories = [
    ShopItemCategory.roomTheme,
    ShopItemCategory.furniture,
    ShopItemCategory.accessory,
    ShopItemCategory.seasonalBundle,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initTaskService();
    _loadData();
  }

  Future<void> _initTaskService() async {
    final prefs = await SharedPreferences.getInstance();
    _taskService = DailyTaskService(prefs);
  }

  late DailyTaskService _taskService;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    final bondService = BondService()..init(prefs);

    final cats = catService.getAllCats();
    if (cats.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final currentCat = cats.first;
    _currentCatId = currentCat.id;

    // 初始化新貓的配置
    await _catWorldService.initializeNewCat(_currentCatId!);

    // 取得默契值
    final bond = bondService.getBond(_currentCatId!);
    _currentBondScore = bond.bondScore;

    // 取得連續天數
    final streakService = StreakService(prefs);
    final streak = streakService.getStreak();
    _currentStreakDays = streak.currentStreak;

    // 載入已裝備狀態
    await _loadEquippedState();

    // 載入今日互動狀態
    await _loadTodayInteractionState(prefs);

    // 檢查今天是否有貓生日
    _birthdayCatToday = null;
    for (final cat in cats) {
      if (cat.birthdayType != 'unknown' && _birthdayService.isBirthdayToday(cat)) {
        _birthdayCatToday = cat;
        break;
      }
    }

    await _loadItemsByTab(0);
  }

  Future<void> _loadEquippedState() async {
    if (_currentCatId == null) return;
    _equippedRoomId = await _catWorldService.getEquippedRoomTheme(_currentCatId!);
    _equippedFurnitureIds = await _catWorldService.getEquippedFurniture(_currentCatId!);
    _equippedAccessoryIds = await _catWorldService.getEquippedAccessories(_currentCatId!);
    _equippedAnimationIds = await _catWorldService.getEquippedAnimations(_currentCatId!);
  }

  Future<void> _loadTodayInteractionState(SharedPreferences prefs) async {
    if (_currentCatId == null) return;
    final today = _getTodayKey();
    _todayInteractions = prefs.getInt('cat_world_interact_today_$today') ?? 0;
    _todayBondFromRoom = prefs.getInt('cat_world_bond_room_$today') ?? 0;
    _surpriseShownToday = prefs.getBool('cat_world_surprise_shown_$today') ?? false;
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _loadItemsByTab(_tabController.index);
    }
  }

  Future<void> _loadItemsByTab(int index) async {
    if (_currentCatId == null) return;

    setState(() => _isLoading = true);

    final category = _categories[index];
    final items = await _catWorldService.getItemsByCategory(_currentCatId!, category);

    // 檢查是否已裝備
    final equippedRoom = await _catWorldService.getEquippedRoomTheme(_currentCatId!);
    final equippedFurniture = await _catWorldService.getEquippedFurniture(_currentCatId!);
    final equippedAccessories = await _catWorldService.getEquippedAccessories(_currentCatId!);
    final equippedAnimations = await _catWorldService.getEquippedAnimations(_currentCatId!);
    final equippedShareTemplate = await _catWorldService.getEquippedShareTemplate(_currentCatId!);

    final equippedItems = <String>{
      ...?equippedRoom != null ? [equippedRoom] : null,
      ...equippedFurniture,
      ...equippedAccessories,
      ...equippedAnimations,
      ...?equippedShareTemplate != null ? [equippedShareTemplate] : null,
    };

    final itemsWithEquipped = items.map((item) {
      return item.copyWith(isEquipped: equippedItems.contains(item.id));
    }).toList();

    setState(() {
      _displayItems = itemsWithEquipped;
      _isLoading = false;
    });
  }

  Future<void> _onUnlock(ShopItem item) async {
    if (_currentCatId == null) return;

    final result = await _catWorldService.unlockItem(_currentCatId!, item.id);
    if (!mounted) return;

    if (result == UnlockResult.success) {
      _showToast('她的小世界變溫暖了一點 🐾');
      // 更新每日任務進度（小世界互動）
      _taskService.updateTaskProgress(TaskType.cat_world_interact);
      _loadItemsByTab(_tabController.index);
    } else if (result == UnlockResult.alreadyUnlocked) {
      // 已解鎖，直接裝備
      _onEquip(item);
    }
  }

  Future<void> _onEquip(ShopItem item) async {
    if (_currentCatId == null) return;

    final result = await _catWorldService.equipItem(_currentCatId!, item.id);
    if (!mounted) return;

    if (result == EquipResult.success) {
      _showToast('她好像很喜歡這個新角落 💕');
      // 更新每日任務進度（小世界互動）
      _taskService.updateTaskProgress(TaskType.cat_world_interact);
      _loadItemsByTab(_tabController.index);
    }
  }

  void _showToast(String message) {
    TopToastService.show(context, message: message, backgroundColor: KawaiiTheme.primaryPink);
  }

  void _showPaidDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🏪',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              '正式商店即將開放',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4B4B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '先幫她預覽看看 🐾',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9B8B8B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('好'),
            ),
          ],
        ),
      ),
    );
  }

  bool _canUnlock(ShopItem item) {
    if (item.unlockType == ShopUnlockType.free) return true;
    if (item.unlockType == ShopUnlockType.bond) {
      return _currentBondScore >= (item.requiredBondScore ?? 0);
    }
    if (item.unlockType == ShopUnlockType.streak) {
      return _currentStreakDays >= (item.requiredStreakDays ?? 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9B8B8B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              '她的小世界 🏡',
              style: TextStyle(
                color: Color(0xFF6B4B4B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '幫她佈置一個更舒服的小角落',
              style: TextStyle(
                color: Color(0xFF9B8B8B),
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: KawaiiTheme.primaryPink,
          unselectedLabelColor: KawaiiTheme.textLight,
          indicatorColor: KawaiiTheme.primaryPink,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KawaiiTheme.primaryPink))
          : _currentCatId == null
              ? _buildNoCatState()
              : _buildContent(),
    );
  }

  Widget _buildNoCatState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E1).withValues(alpha: 180/255),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🐱', style: TextStyle(fontSize: 60)),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '先新增貓咪，我才能幫她佈置小世界 🐱',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B4B4B),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '一起去首頁新增她吧',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9B8B8B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('好的，帶我回去'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return NestedScrollView(
      headerSliverBuilder: (context, innerBoxIsScrolled) {
        return <Widget>[
          SliverToBoxAdapter(
            child: Column(
              children: [
                // 房間展示區
                _buildRoomSection(),
                // 活動卡片
                if (_birthdayCatToday != null) _buildBirthdayEventCard(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SummerWindowPage()),
                    );
                  },
                  child: _buildEventCard(),
                ),
                // Plus 入口卡片
                _buildPlusCard(),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ];
      },
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) => _buildItemList()).toList(),
      ),
    );
  }

  // ===== 生日活動卡片 =====
  Widget _buildBirthdayEventCard() {
    return GestureDetector(
      onTap: () {
        TopToastService.info(context, message: '生日派對功能即將開放 🐾');
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFE4E1), Color(0xFFFFF8F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFFFB6C1).withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('🎂', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '今天是她的小派對 🎂',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF8FAB),
                    ),
                  ),
                  if (_birthdayCatToday != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '祝 ${_birthdayCatToday!.name} 生日快樂！',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B8B8B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8FAB).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '活動中',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF8FAB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 季節活動卡片 =====
  Widget _buildEventCard() {
    final eventService = SeasonalEventService();
    final event = eventService.getCurrentEvent();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: event != null
            ? Color(event.themeColor).withValues(alpha: 0.15)
            : const Color(0xFFFFF8F5),
        borderRadius: BorderRadius.circular(16),
        border: event != null
            ? Border.all(
                color: Color(event.themeColor).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          Text(event?.icon ?? '🐾', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event?.name ?? '今天也是陪她的小日子 🐾',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: event != null
                        ? Color(event.themeColor)
                        : const Color(0xFF9B8B8B),
                  ),
                ),
                if (event != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    event.remainingText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9B8B8B),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (event != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color(event.themeColor).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '活動中',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B4B4B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===== Plus 入口卡片 =====
  Widget _buildPlusCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4E1), Color(0xFFFFF0F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFF8FAB).withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Text('✨', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '她的小世界 Plus',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF6B8A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '讓她的世界更完整一點 🌸',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF9B8B8B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Plus 內容預覽
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildPlusTag('🏠 每月限定房間'),
              _buildPlusTag('💎 專屬配件'),
              _buildPlusTag('✨ 特殊情緒動畫'),
              _buildPlusTag('📱 更多分享卡模板'),
              _buildPlusTag('📊 更細緻的 7 天分析'),
              _buildPlusTag('🏡 房間自訂保存'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPlusDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8FAB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                '看看 Plus 內容',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlusTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF6B4B4B),
        ),
      ),
    );
  }

  void _showPlusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Plus 內容即將開放 🐾',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4B4B),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '再等等，我正在為她準備更完整的小世界 🌸',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9B8B8B),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('好'),
            ),
          ],
        ),
      ),
    );
  }

  // ===== 房間展示區 =====
  Widget _buildRoomSection() {
    final roomBgColor = _getEquippedRoomColor();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: roomBgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 頂部：標題 + 小驚喜提示
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏠 她的小房間',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4B4B),
                ),
              ),
              Row(
                children: [
                  // 回憶收藏按鈕
                  GestureDetector(
                    onTap: () => _openMemoryCards(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Text('💎', style: TextStyle(fontSize: 12)),
                          SizedBox(width: 4),
                          Text(
                            '回憶收藏',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B4B4B)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '今日互動 ${_todayInteractions}/$_maxDailyInteractions',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9B8B8B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 房間內容區
          _buildRoomContent(),
          const SizedBox(height: 16),
          // 互動按鈕列
          _buildInteractionButtons(),
        ],
      ),
    );
  }

  Widget _buildRoomContent() {
    return SizedBox(
      height: 140,
      child: Stack(
        children: [
          // 窗戶
          Positioned(
            top: 8,
            right: 16,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.window, color: Color(0xFF9B8B8B), size: 22),
            ),
          ),
          // 地毯
          Positioned(
            bottom: 0,
            left: 10,
            right: 10,
            child: Container(
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          // 食碗（左下角）
          if (_equippedFurnitureIds.any((id) => id.contains('bowl')))
            Positioned(
              bottom: 10,
              left: 20,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: const Icon(Icons.pets, color: Color(0xFF9B8B8B), size: 12),
              ),
            ),
          // 貓咪 icon（中央）
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.pets, size: 50, color: Color(0xFFFF8FAB)),
                  // 配件裝飾
                  if (_equippedAccessoryIds.isNotEmpty &&
                      !_equippedAccessoryIds.contains('accessory_none'))
                    Positioned(
                      bottom: 40,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.star, color: Color(0xFFFFB800), size: 12),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // 動畫效果提示
          if (_equippedAnimationIds.isNotEmpty)
            Positioned(
              top: 8,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: const Text('💕', style: TextStyle(fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInteractionButtons() {
    final canInteract = _todayInteractions < _maxDailyInteractions;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInteractBtn('🍽', '餵她', canInteract, () => _onInteract('feed')),
        _buildInteractBtn('🎾', '陪她玩', canInteract, () => _onInteract('play')),
        _buildInteractBtn('💕', '摸摸她', canInteract, () => _onInteract('pet')),
        _buildInteractBtn('🗣', '跟她說話', canInteract, () => _onInteract('talk')),
      ],
    );
  }

  Widget _buildInteractBtn(String emoji, String label, bool enabled, VoidCallback onPressed) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: TextStyle(fontSize: enabled ? 24 : 20)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled ? const Color(0xFF6B4B4B) : const Color(0xFF9B8B8B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onInteract(String type) async {
    if (_currentCatId == null) {
      _showToast('先新增貓咪，我才能幫她佈置小世界 🐱');
      return;
    }

    if (_todayInteractions >= _maxDailyInteractions) {
      _showToast('今天已經陪她很多了，明天再來看看她 💕');
      return;
    }

    // 互動提示
    String message;
    switch (type) {
      case 'feed':
        message = '她好像安心了一點 🍽';
        break;
      case 'play':
        message = '她今天玩得很開心 🎾';
        break;
      case 'pet':
        message = '她好像更放鬆了 💕';
        break;
      case 'talk':
        message = '她有聽到你的聲音了 🐾';
        break;
      default:
        message = '她知道你在陪她 💕';
    }

    // 小驚喜（10%機率，每天第一次互動）
    if (!_surpriseShownToday && _todayInteractions == 0 && DateTime.now().second % 10 == 0) {
      final surprises = [
        '今天她特別想靠近你 💕',
        '她今天在窗邊等你 ☀️',
      ];
      message = surprises[DateTime.now().millisecond % surprises.length];
      _surpriseShownToday = true;
    }

    // 加默契值
    final prefs = await SharedPreferences.getInstance();
    final bondService = BondService()..init(prefs);
    final memoryCardService = MemoryCardService();

    if (_todayBondFromRoom < _maxDailyBondFromRoom) {
      await bondService.addBond(_currentCatId!, BondService.eventActionTap);
      _todayBondFromRoom++;
      await prefs.setInt('cat_world_bond_room_${_getTodayKey()}', _todayBondFromRoom);
    }

    // 解鎖回憶卡
    final cardType = _getCardTypeFromInteraction(type);
    if (cardType != null) {
      final unlocked = await memoryCardService.unlockMemoryCard(_currentCatId!, cardType);
      if (unlocked) {
        _showToast('新的回憶被收藏起來了 💕');
      }
    }

    // 更新今日互動次數
    _todayInteractions++;
    await prefs.setInt('cat_world_interact_today_${_getTodayKey()}', _todayInteractions);
    if (_surpriseShownToday) {
      await prefs.setBool('cat_world_surprise_shown_${_getTodayKey()}', true);
    }

    _showToast(message);
    setState(() {});
  }

  Color _getEquippedRoomColor() {
    if (_equippedRoomId == null) return const Color(0xFFFFF0F5);
    if (_equippedRoomId!.contains('milk_tea')) return const Color(0xFFF5E6D3);
    if (_equippedRoomId!.contains('pink')) return const Color(0xFFFFE4E1);
    if (_equippedRoomId!.contains('starry')) return const Color(0xFFE8E0F0);
    if (_equippedRoomId!.contains('forest')) return const Color(0xFFE8F5E8);
    if (_equippedRoomId!.contains('birthday')) return const Color(0xFFFFF0E8);
    return const Color(0xFFFFF0F5);
  }

  MemoryCardType? _getCardTypeFromInteraction(String type) {
    switch (type) {
      case 'feed': return MemoryCardType.firstFeed;
      case 'play': return MemoryCardType.firstPlay;
      case 'pet': return MemoryCardType.firstPet;
      case 'talk': return MemoryCardType.firstTalk;
      default: return null;
    }
  }

  void _openMemoryCards() {
    if (_currentCatId == null) {
      _showToast('先新增貓咪，我才能幫她佈置小世界 🐱');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MemoryCardsPage(catId: _currentCatId!),
      ),
    );
  }

  Widget _buildItemList() {
    if (_displayItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏠', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              '這個分類還沒有東西喔 🐾',
              style: TextStyle(
                fontSize: 14,
                color: KawaiiTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _displayItems.length,
      itemBuilder: (ctx, index) => _buildItemCard(_displayItems[index]),
    );
  }

  Widget _buildItemCard(ShopItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: item.isEquipped
            ? Border.all(color: KawaiiTheme.primaryPink.withValues(alpha: 0.5), width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 第一行：名稱 + 分類標籤
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6B4B4B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(item.category).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  item.categoryLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _getCategoryColor(item.category),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 描述
          Text(
            item.description,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9B8B8B),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 12),

          // 標籤
          if (item.tags.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: item.tags.map((tag) => _buildTag(tag)).toList(),
            ),

          const SizedBox(height: 12),

          // 狀態 / 解鎖條件
          _buildStatusRow(item),

          const SizedBox(height: 12),

          // 按鈕列（試放看看 + 主操作）
          Row(
            children: [
              // 試放看看按鈕
              Expanded(
                child: _buildPreviewBtn(() => _showPreviewDialog(item)),
              ),
              const SizedBox(width: 8),
              // 主操作按鈕
              Expanded(
                flex: 2,
                child: _buildActionButton(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF9B8B8B),
        ),
      ),
    );
  }

  Widget _buildStatusRow(ShopItem item) {
    if (item.isUnlocked) {
      return Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF6BBF6B)),
          const SizedBox(width: 4),
          Text(
            item.isEquipped ? '使用中' : '已擁有',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6BBF6B),
            ),
          ),
        ],
      );
    }

    // 未解鎖
    String conditionText = '';
    if (item.unlockType == ShopUnlockType.bond) {
      conditionText = '默契 ${item.requiredBondScore}% 解鎖';
    } else if (item.unlockType == ShopUnlockType.streak) {
      conditionText = '連續陪伴 ${item.requiredStreakDays} 天解鎖';
    } else if (item.unlockType == ShopUnlockType.paid) {
      conditionText = '即將開放';
    } else if (item.unlockType == ShopUnlockType.limited) {
      conditionText = '限定內容';
    }

    return Row(
      children: [
        const Icon(Icons.lock_outline, size: 16, color: Color(0xFF9B8B8B)),
        const SizedBox(width: 4),
        Text(
          conditionText,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF9B8B8B),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBtn(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF9B8B8B),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          '試放看看',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }


  // ===== 試放看看預覽 Dialog =====
  void _showPreviewDialog(ShopItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 商品名稱
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 商品描述
                  Text(
                    item.description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9B8B8B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // 小房間預覽區
                  _buildRoomPreview(item),
                  const SizedBox(height: 16),
                  // 預覽文案
                  Text(
                    item.isUnlocked
                        ? '她好像很喜歡這個角落 💕'
                        : '她好像很喜歡這個角落 💕\n解鎖後就可以放進她的小世界。',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF9B8B8B),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 按鈕列
                  _buildPreviewActionButtons(item, ctx, setDialogState),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ===== 預覽區按鈕列 =====
  Widget _buildPreviewActionButtons(
    ShopItem item,
    BuildContext dialogCtx,
    StateSetter setDialogState,
  ) {
    // 如果已裝備
    if (item.isEquipped) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF6BBF6B).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '使用中',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF6BBF6B),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B8B8B),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '關閉',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    // 如果已解鎖但未裝備
    if (item.isUnlocked) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_currentCatId == null) {
                  Navigator.pop(dialogCtx);
                  _showToast('先新增貓咪，我才能幫她佈置小世界 🐱');
                  return;
                }
                final result = await _catWorldService.equipItem(_currentCatId!, item.id);
                if (result == EquipResult.success) {
                  Navigator.pop(dialogCtx);
                  _showToast('她好像很喜歡這個新角落 💕');
                  _loadItemsByTab(_tabController.index);
                } else {
                  _showToast('這個小物件還不能放進去，先再看看 🐾');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text(
                '放進她的小世界',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B8B8B),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '先看看',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    // 未解鎖：顯示解鎖按鈕或條件未達
    if (item.unlockType == ShopUnlockType.paid || item.unlockType == ShopUnlockType.limited) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: () => Navigator.pop(dialogCtx),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF9B8B8B),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text(
            '先看看',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }

    // 條件達成可解鎖
    if (_canUnlock(item)) {
      final unlockLabel = item.unlockType == ShopUnlockType.bond
          ? '用默契解鎖'
          : '用連續陪伴解鎖';
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                if (_currentCatId == null) {
                  Navigator.pop(dialogCtx);
                  _showToast('先新增貓咪，我才能幫她佈置小世界 🐱');
                  return;
                }
                final result = await _catWorldService.unlockItem(_currentCatId!, item.id);
                if (!mounted) return;

                if (result == UnlockResult.success) {
                  _showToast('她的小世界變溫暖了一點 🐾');
                  // 解鎖成功，詢問是否放進去
                  final shouldEquip = await _showEquipPrompt(dialogCtx);
                  if (shouldEquip == true) {
                    final equipResult = await _catWorldService.equipItem(_currentCatId!, item.id);
                    if (mounted) {
                      if (equipResult == EquipResult.success) {
                        Navigator.pop(dialogCtx);
                        _showToast('她好像很喜歡這個新角落 💕');
                      } else {
                        _showToast('這個小物件還不能放進去，先再看看 🐾');
                      }
                    }
                  } else {
                    Navigator.pop(dialogCtx);
                  }
                  _loadItemsByTab(_tabController.index);
                } else {
                  Navigator.pop(dialogCtx);
                  _showToast('這個小物件暫時還不能解鎖，先再看看 🐾');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8FAB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: Text(
                unlockLabel,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogCtx),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF9B8B8B),
                side: const BorderSide(color: Color(0xFFE0E0E0)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                '先看看',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      );
    }

    // 條件未達
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF9B8B8B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '再陪她久一點',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF9B8B8B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF9B8B8B),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text(
              '先看看',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // ===== 解鎖後詢問是否放進去 =====
  Future<bool?> _showEquipPrompt(BuildContext dialogCtx) async {
    return showDialog<bool>(
      context: dialogCtx,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              '要現在放進她的小世界嗎？',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4B4B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.primaryPink,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('放進去'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF9B8B8B),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('先不要'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===== 小房間預覽 Widget =====
  Widget _buildRoomPreview(ShopItem item) {
    // 房間背景色根據分類變化
    final bgColor = _getRoomBgColor(item);

    return Container(
      width: 220,
      height: 200,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // 窗戶（右上角）
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.window,
                color: Color(0xFF9B8B8B),
                size: 24,
              ),
            ),
          ),
          // 小地毯（底部）
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              height: 16,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // 食碗（左下角）
          Positioned(
            bottom: 28,
            left: 30,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.pets,
                color: Color(0xFF9B8B8B),
                size: 14,
              ),
            ),
          ),
          // 貓咪 icon（中央）
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: const Center(
              child: Icon(
                Icons.pets,
                size: 56,
                color: Color(0xFFFF8FAB),
              ),
            ),
          ),
          // 分類特殊裝飾
          ..._buildCategoryDecorations(item),
        ],
      ),
    );
  }

  // ===== 取得房間背景色 =====
  Color _getRoomBgColor(ShopItem item) {
    switch (item.category) {
      case ShopItemCategory.roomTheme:
        // roomTheme 改變背景色
        if (item.id.contains('milk_tea')) return const Color(0xFFF5E6D3);
        if (item.id.contains('pink')) return const Color(0xFFFFE4E1);
        if (item.id.contains('starry')) return const Color(0xFFE8E0F0);
        if (item.id.contains('forest')) return const Color(0xFFE8F5E8);
        if (item.id.contains('birthday')) return const Color(0xFFFFF0E8);
        return const Color(0xFFFFF0F5);
      case ShopItemCategory.furniture:
        return const Color(0xFFFFF5F5);
      case ShopItemCategory.accessory:
        return const Color(0xFFFFFBE8);
      case ShopItemCategory.emotionAnimation:
        return const Color(0xFFFFE8F5);
      case ShopItemCategory.shareTemplate:
        return const Color(0xFFE8F5FF);
      case ShopItemCategory.seasonalBundle:
        return const Color(0xFFF5FFE8);
    }
  }

  // ===== 分類特殊裝飾 =====
  List<Widget> _buildCategoryDecorations(ShopItem item) {
    switch (item.category) {
      case ShopItemCategory.roomTheme:
        return [
          // 房間主題：頂部愛心裝飾
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite, color: Color(0xFFFF8FAB), size: 16),
            ),
          ),
        ];
      case ShopItemCategory.furniture:
        return [
          // 家具：左側小 icon
          Positioned(
            top: 50,
            left: 12,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chair, color: Color(0xFF8B5CF6), size: 18),
            ),
          ),
        ];
      case ShopItemCategory.accessory:
        return [
          // 配件：在貓咪旁顯示蝴蝶結
          Positioned(
            bottom: 50,
            right: 60,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.star, color: Color(0xFFFFB800), size: 14),
            ),
          ),
        ];
      case ShopItemCategory.emotionAnimation:
        return [
          // 動畫：愛心效果
          Positioned(
            top: 30,
            left: 30,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('💕', style: TextStyle(fontSize: 16)),
            ),
          ),
          Positioned(
            top: 50,
            right: 40,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('✨', style: TextStyle(fontSize: 14)),
            ),
          ),
        ];
      case ShopItemCategory.shareTemplate:
        return [
          // 分享卡：小卡片縮圖
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              width: 36,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFF8FAB), width: 1.5),
              ),
              child: const Icon(Icons.image, color: Color(0xFFFF8FAB), size: 16),
            ),
          ),
        ];
      case ShopItemCategory.seasonalBundle:
        return [
          // 季節套組：彩帶裝飾
          Positioned(
            top: 10,
            left: 50,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('🎀', style: TextStyle(fontSize: 14)),
            ),
          ),
          Positioned(
            top: 40,
            right: 14,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Text('🌸', style: TextStyle(fontSize: 14)),
            ),
          ),
        ];
    }
  }

  Widget _buildActionButton(ShopItem item) {
    if (item.isEquipped) {
      return _buildDisabledButton('使用中', const Color(0xFF6BBF6B));
    }

    if (item.isUnlocked) {
      return _buildActionBtn(
        '放進她的小世界',
        KawaiiTheme.primaryPink,
        () => _onEquip(item),
      );
    }

    if (item.unlockType == ShopUnlockType.paid) {
      return _buildActionBtn(
        '先看看',
        const Color(0xFF9B8B8B),
        _showPaidDialog,
      );
    }

    if (_canUnlock(item)) {
      return _buildActionBtn(
        '用默契解鎖',
        const Color(0xFFFF8FAB),
        () => _onUnlock(item),
      );
    }

    return _buildDisabledButton('還需要更多默契', const Color(0xFF9B8B8B));
  }

  Widget _buildActionBtn(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDisabledButton(String label, Color color) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color,
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(ShopItemCategory category) {
    switch (category) {
      case ShopItemCategory.roomTheme:
        return const Color(0xFFFF8FAB);
      case ShopItemCategory.furniture:
        return const Color(0xFF8B5CF6);
      case ShopItemCategory.accessory:
        return const Color(0xFFFFB800);
      case ShopItemCategory.emotionAnimation:
        return const Color(0xFF4ECDC4);
      case ShopItemCategory.shareTemplate:
        return const Color(0xFF6BBF6B);
      case ShopItemCategory.seasonalBundle:
        return const Color(0xFFFF6B6B);
    }
  }
}
