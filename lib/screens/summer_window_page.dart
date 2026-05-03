import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/cat_service.dart';
import '../services/seasonal_event_service.dart';
import '../services/bond_service.dart';

/// 夏日窗邊活動頁 ☀️
class SummerWindowPage extends StatefulWidget {
  const SummerWindowPage({super.key});

  @override
  State<SummerWindowPage> createState() => _SummerWindowPageState();
}

class _SummerWindowPageState extends State<SummerWindowPage> {
  final SeasonalEventService _eventService = SeasonalEventService();
  final BondService _bondService = BondService();

  String? _currentCatId;
  bool _isLoading = true;
  int _interactionCount = 0;
  static const int _maxInteractions = 3;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    final cats = catService.getAllCats();
    if (cats.isNotEmpty) {
      _currentCatId = cats.first.id;
    }
    setState(() => _isLoading = false);
  }

  void _interact() {
    if (_interactionCount >= _maxInteractions) return;
    setState(() => _interactionCount++);

    // 模擬互動增加好感度
    if (_currentCatId != null) {
      _bondService.addBond(_currentCatId!, 'summer_window');
    }

    TopToast.show(context, message: '和貓咪一起享受涼涼的風～ 🐱💨', backgroundColor: const Color(0xFF87CEEB));
  }

  @override
  Widget build(BuildContext context) {
    final event = _eventService.getCurrentEvent();
    final themeColor = event != null ? Color(event.themeColor) : const Color(0xFF87CEEB);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: themeColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          event?.name ?? '夏日窗邊 ☀️',
          style: TextStyle(
            color: themeColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: themeColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // 場景視覺
                  _buildSceneVisual(themeColor),
                  const SizedBox(height: 24),

                  // 活動說明
                  _buildEventInfo(event, themeColor),
                  const SizedBox(height: 24),

                  // 互動按鈕
                  _buildInteractionButton(themeColor),
                  const SizedBox(height: 16),

                  // 互動進度
                  _buildInteractionProgress(themeColor),
                  const SizedBox(height: 24),

                  // 活動商品
                  if (event != null) _buildEventItems(event, themeColor),
                ],
              ),
            ),
    );
  }

  Widget _buildSceneVisual(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // 窗戶 + 太陽 + 貓咪
          Stack(
            alignment: Alignment.center,
            children: [
              // 窗戶
              Container(
                width: 140,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.brown.shade300, width: 3),
                ),
                child: Column(
                  children: [
                    // 窗戶分隔線
                    Container(
                      height: 47,
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.brown.shade300, width: 2),
                        ),
                      ),
                    ),
                    Container(
                      height: 47,
                    ),
                  ],
                ),
              ),
              // 太陽
              Positioned(
                top: 0,
                right: 20,
                child: Text('☀️', style: TextStyle(fontSize: 28, color: themeColor)),
              ),
              // 貓咪
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🐱', style: TextStyle(fontSize: 36)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🌬️ 涼爽的風吹進窗戶\n和她一起享受夏日的悠閒時光',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B4B4B),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventInfo(SeasonalEvent? event, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(event?.icon ?? '☀️', style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                event?.name ?? '夏日窗邊 ☀️',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            event?.description ?? '夏天的午後，和她一起吹涼涼的風',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF9B8B8B),
              height: 1.5,
            ),
          ),
          if (event != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.remainingText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: themeColor,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInteractionButton(Color themeColor) {
    final isMaxed = _interactionCount >= _maxInteractions;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isMaxed ? Colors.grey : themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: isMaxed ? null : _interact,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isMaxed ? '✅ 今日已完成' : '🌬️ 一起吹涼風'),
            if (!isMaxed) ...[
              const SizedBox(width: 8),
              Text(
                isMaxed ? '' : '$_interactionCount/$_maxInteractions',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionProgress(Color themeColor) {
    return Row(
      children: List.generate(_maxInteractions, (i) {
        final isCompleted = i < _interactionCount;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i > 0 ? 4 : 0, right: i < _maxInteractions - 1 ? 4 : 0),
            height: 8,
            decoration: BoxDecoration(
              color: isCompleted ? themeColor : themeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEventItems(SeasonalEvent event, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🏠 活動限定商品',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6B4B4B),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: event.unlockableItemIds.map<Widget>((itemId) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _getItemDisplayName(itemId),
                  style: TextStyle(
                    fontSize: 12,
                    color: themeColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getItemDisplayName(String itemId) {
    final names = {
      'room_summer_窗邊房': '🏠 窗邊房',
      'furniture_summer_涼墊': '🛋️ 涼墊',
      'furniture_summer_小風扇': '🌀 小風扇',
      'accessory_summer_曬太陽墨镜': '🕶️ 曬太陽墨镜',
      'share_summer_夏日卡': '💌 夏日卡',
    };
    return names[itemId] ?? itemId;
  }
}
