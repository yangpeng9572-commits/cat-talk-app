import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/cat_world_items.dart';
import '../models/shop_item.dart';
import '../services/cat_world_service.dart';
import '../services/cat_service.dart';
import '../services/bond_service.dart';
import '../theme/kawaii_theme.dart';

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
  List<ShopItem> _displayItems = [];
  bool _isLoading = true;

  // 分類標籤
  static const List<String> _tabLabels = [
    '房間',
    '家具',
    '配件',
    '動畫',
    '分享卡',
    '限定',
  ];

  // Tab 對應的分類
  static const List<ShopItemCategory> _categories = [
    ShopItemCategory.roomTheme,
    ShopItemCategory.furniture,
    ShopItemCategory.accessory,
    ShopItemCategory.emotionAnimation,
    ShopItemCategory.shareTemplate,
    ShopItemCategory.seasonalBundle,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

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

    await _loadItemsByTab(0);
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
      _loadItemsByTab(_tabController.index);
    }
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 14),
        ),
        backgroundColor: KawaiiTheme.primaryPink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
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
      // streak 解鎖需要連續天數，這裡暫時用默契值判斷
      return _currentBondScore >= (item.requiredStreakDays ?? 0) * 5;
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
                color: const Color(0xFFFFE4E1).withValues(alpha: 180),
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
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return TabBarView(
      controller: _tabController,
      children: _categories.map((category) => _buildItemList()).toList(),
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

          // 按鈕
          _buildActionButton(item),
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
