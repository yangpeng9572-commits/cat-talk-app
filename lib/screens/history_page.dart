import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart'; // P3-4: 照片功能
import 'package:table_calendar/table_calendar.dart'; // P3-5: 日曆視圖
import 'dart:io'; // P3-4: 照片檔案路徑
import '../models/translation_result.dart';
import '../models/cat.dart';
import '../models/user_diary_entry.dart';
import '../services/translation_history_service.dart';
import '../services/cat_service.dart';
import '../services/user_diary_service.dart';
import '../widgets/emotion_card.dart';
import '../widgets/top_toast.dart';
import '../theme/kawaii_theme.dart';

/// 記錄頁（生活日記 MVP）
/// 
/// P1-4：第一階段將記錄頁改成日常生活日記
/// - 翻譯記錄（原有功能）
/// - 使用者自行記錄的生活日記（新功能）
/// 
/// 未来扩展方向：
/// - 第二阶段：照片 + 标签 + 时间轴
/// - 第三阶段：日历视图
/// 
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  final TranslationHistoryService _historyService = TranslationHistoryService();
  final UserDiaryService _diaryService = UserDiaryService();
  late CatService _catService;
  late TabController _tabController;
  final ImagePicker _imagePicker = ImagePicker(); // P3-4: 照片選擇器

  // 貓咪資料快取
  Map<String, Cat> _catsMap = {};

  // P3-5: 日曆視圖模式切換（false = 清單，true = 日曆）
  bool _diaryViewMode = false;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await _historyService.init(prefs);
    await _diaryService.init(prefs);
    _catService = CatService(prefs);
    _loadCats();
    if (!mounted) return;
    setState(() {});
  }

  void _loadCats() {
    final cats = _catService.getAllCats();
    _catsMap = { for (var c in cats) c.id: c };
  }

  Cat? _getCatById(String catId) => _catsMap[catId];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        title: const Text('生活記錄'),
        backgroundColor: Colors.transparent,
        foregroundColor: KawaiiTheme.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: KawaiiTheme.primaryPink,
          unselectedLabelColor: KawaiiTheme.textSecondary,
          indicatorColor: KawaiiTheme.primaryPink,
          tabs: [
            Tab(text: '翻譯'),
            Tab(text: '日記'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDiaryDialog(),
            tooltip: '寫日記',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTranslationTab(),
          _buildDiaryTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDiaryDialog(),
        backgroundColor: KawaiiTheme.primaryPink,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  /// 翻譯記錄 tab
  Widget _buildTranslationTab() {
    if (_historyService.count == 0) {
      return _buildTranslationEmptyState();
    }

    final history = _historyService.getAll();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final result = history[index];
        return _buildHistoryCard(result);
      },
    );
  }

  /// 日記 tab
  Widget _buildDiaryTab() {
    final entries = _diaryService.getAll();
    if (entries.isEmpty) {
      return Column(
        children: [
          _buildDiaryViewToggle(),
          Expanded(child: _buildDiaryEmptyState()),
        ],
      );
    }

    return Column(
      children: [
        _buildDiaryViewToggle(),
        Expanded(
          child: _diaryViewMode
              ? _buildCalendarView(entries)
              : _buildDiaryListView(entries),
        ),
      ],
    );
  }

  /// P3-5: 日曆/清單視圖切換按鈕
  Widget _buildDiaryViewToggle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _buildToggleChip(
            label: '清單',
            icon: Icons.list_alt,
            isSelected: !_diaryViewMode,
            onTap: () => setState(() {
              _diaryViewMode = false;
              _selectedDay = null;
            }),
          ),
          const SizedBox(width: 8),
          _buildToggleChip(
            label: '日曆',
            icon: Icons.calendar_month,
            isSelected: _diaryViewMode,
            onTap: () => setState(() => _diaryViewMode = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? KawaiiTheme.primaryPink.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? KawaiiTheme.primaryPink : KawaiiTheme.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? KawaiiTheme.primaryPink : KawaiiTheme.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? KawaiiTheme.primaryPink : KawaiiTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// P3-5: 日記清單視圖（原有邏輯）
  Widget _buildDiaryListView(List<UserDiaryEntry> entries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildDiaryCard(entry);
      },
    );
  }

  /// P3-5: 日曆視圖
  Widget _buildCalendarView(List<UserDiaryEntry> entries) {
    // 建立日期 → 条目列表 的映射
    final eventsByDay = <DateTime, List<UserDiaryEntry>>{};
    for (final entry in entries) {
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      eventsByDay.putIfAbsent(day, () => []).add(entry);
    }

    List<UserDiaryEntry> getEventsForDay(DateTime day) {
      return eventsByDay[DateTime(day.year, day.month, day.day)] ?? [];
    }

    return Column(
      children: [
        TableCalendar<UserDiaryEntry>(
          firstDay: DateTime(2020),
          lastDay: DateTime.now(),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: getEventsForDay,
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            leftChevronIcon: const Icon(Icons.chevron_left, color: KawaiiTheme.textPrimary),
            rightChevronIcon: const Icon(Icons.chevron_right, color: KawaiiTheme.textPrimary),
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: KawaiiTheme.primaryPink.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: const BoxDecoration(
              color: KawaiiTheme.primaryPink,
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: KawaiiTheme.primaryPink,
              shape: BoxShape.circle,
            ),
            markersMaxCount: 3,
            outsideDaysVisible: false,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(height: 1),
        Expanded(
          child: _selectedDay == null
              ? _buildCalendarHint()
              : _buildDayEntries(getEventsForDay(_selectedDay!)),
        ),
      ],
    );
  }

  /// P3-5: 日曆選中日期後顯示該日日記
  Widget _buildDayEntries(List<UserDiaryEntry> entries) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '📅 ${_formatDate(_selectedDay!)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '这天还没有日记',
              style: TextStyle(
                fontSize: 14,
                color: KawaiiTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) => _buildDiaryCard(entries[index]),
    );
  }

  /// P3-5: 日曆提示文字
  Widget _buildCalendarHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '👆 點選日期查看日記',
          style: TextStyle(
            fontSize: 14,
            color: KawaiiTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  /// 翻譯記錄空狀態
  Widget _buildTranslationEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '😺',
              style: TextStyle(fontSize: 60),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '還沒有翻譯記錄\n去首頁長按翻譯按鈕開始吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  /// 日記空狀態
  Widget _buildDiaryEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Text(
              '📔',
              style: TextStyle(fontSize: 60),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '還沒有寫日記\n記錄今天和貓咪的特別時光吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showAddDiaryDialog(),
            icon: const Icon(Icons.edit),
            label: const Text('寫下第一篇'),
            style: ElevatedButton.styleFrom(
              backgroundColor: KawaiiTheme.primaryPink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 翻譯記錄卡片
  Widget _buildHistoryCard(TranslationResult result) {
    final cat = _getCatById(result.catId);
    final hasCorrection = result.userFeedback != null && !result.userFeedback!.isCorrect;
    final isCorrect = result.userFeedback?.isCorrect ?? false;

    return GestureDetector(
      onTap: () => _showDetailSheet(result),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
          border: Border.all(
            color: hasCorrection
                ? KawaiiTheme.primaryPink.withValues(alpha: 0.5)
                : KawaiiTheme.divider,
            width: hasCorrection ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一列：貓咪名稱 + 時間
            Row(
              children: [
                // 貓咪頭像
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KawaiiTheme.softPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, color: KawaiiTheme.primaryPink, size: 20),
                ),
                const SizedBox(width: 12),
                // 貓咪名稱
                Text(
                  cat?.name ?? '未知',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 時間
                Text(
                  _formatTime(result.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: KawaiiTheme.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 第二列：情緒 + 翻譯文字
            Row(
              children: [
                // 情緒 Emoji
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(result.emotionType.colorValue).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(result.emotionType.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        result.emotionType.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(result.emotionType.colorValue),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 修正標籤
                if (hasCorrection)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: KawaiiTheme.coral,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '已修正',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else if (isCorrect)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✓ 正確',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 第三列：翻譯文字
            Text(
              result.humanText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // 第四列：信心值
            Row(
              children: [
                const Text(
                  '💪',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '信心度',
                  style: TextStyle(
                    fontSize: 12,
                    color: KawaiiTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: KawaiiTheme.divider,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: result.confidence,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(result.confidence),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(result.confidence * 100).round()}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(result.confidence),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 日記卡片
  Widget _buildDiaryCard(UserDiaryEntry entry) {
    final cat = _getCatById(entry.catId);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('刪除日記？'),
            content: const Text('這個動作無法撤銷。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('刪除'),
              ),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (direction) {
        _diaryService.deleteEntry(entry.id);
        setState(() {});
        TopToast.success(context, message: '已刪除日記');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
          border: Border.all(color: KawaiiTheme.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 第一列：貓咪名稱 + 日期
            Row(
              children: [
                // 貓咪頭像
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KawaiiTheme.softPink,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.pets, color: KawaiiTheme.primaryPink, size: 20),
                ),
                const SizedBox(width: 12),
                // 貓咪名稱
                Text(
                  cat?.name ?? entry.catName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // 日期
                Text(
                  _formatDate(entry.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: KawaiiTheme.textSecondary,
                  ),
                ),
              ],
            ),

            // P3-4: 照片顯示
            if (entry.photoPath != null && entry.photoPath!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(entry.photoPath!),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 180,
                      color: KawaiiTheme.softPink.withValues(alpha: 0.3),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: KawaiiTheme.textSecondary,
                        size: 48,
                      ),
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // 日記內容
            Text(
              entry.content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
              ),
            ),

            // P3-4 Phase 2: 標籤顯示
            if (entry.tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: entry.tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: KawaiiTheme.primaryPink.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KawaiiTheme.primaryPink,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 新增日記對話框（P3-4: 支援照片）
  Future<void> _showAddDiaryDialog() async {
    final cats = _catService.getAllCats();
    if (cats.isEmpty) {
      TopToast.warning(context, message: '請先新增貓咪再寫日記');
      return;
    }

    final selectedCat = cats.first;
    final controller = TextEditingController();
    DateTime selectedDate = DateTime.now();
    String? selectedPhotoPath; // P3-4: 選中的照片路徑
    final List<String> _selectedTags = []; // P3-4 Phase 2: 選中的標籤

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 標題列
                    Row(
                      children: [
                        const Text(
                          '寫日記',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 選擇貓咪
                    const Text(
                      '選擇貓咪',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: cats.map((cat) {
                        final isSelected = cat.id == selectedCat.id;
                        return ChoiceChip(
                          label: Text(cat.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() {});
                            }
                          },
                          selectedColor: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? KawaiiTheme.primaryPink : KawaiiTheme.textPrimary,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // 選擇日期
                    const Text(
                      '日期',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setSheetState(() => selectedDate = date);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: KawaiiTheme.divider),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.calendar_today, size: 18),
                            const SizedBox(width: 8),
                            Text(_formatDate(selectedDate)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // P3-4: 照片選擇
                    const Text(
                      '照片（選填）',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedPhotoPath != null && selectedPhotoPath!.isNotEmpty)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(selectedPhotoPath!),
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setSheetState(() => selectedPhotoPath = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          _buildPhotoButton(
                            icon: Icons.camera_alt,
                            label: '拍照',
                            onTap: () async {
                              final photo = await _imagePicker.pickImage(
                                source: ImageSource.camera,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (photo != null) {
                                setSheetState(() => selectedPhotoPath = photo.path);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          _buildPhotoButton(
                            icon: Icons.photo_library,
                            label: '相簿',
                            onTap: () async {
                              final photo = await _imagePicker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1024,
                                maxHeight: 1024,
                                imageQuality: 85,
                              );
                              if (photo != null) {
                                setSheetState(() => selectedPhotoPath = photo.path);
                              }
                            },
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),

                    // P3-4 Phase 2: 標籤選擇
                    const Text(
                      '標籤（選填）',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (context, setTagState) {
                        final availableTags = ['🐾 日常', '🍽️ 吃飯', '😴 睡覺', '🧘 伸展', '💕 陪伴', '🏠 在家', '🌞 早晨', '🌙 夜晚'];
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableTags.map((tag) {
                            final isSelected = _selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              onSelected: (selected) {
                                setTagState(() {
                                  if (selected) {
                                    _selectedTags.add(tag);
                                  } else {
                                    _selectedTags.remove(tag);
                                  }
                                });
                              },
                              selectedColor: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
                              checkmarkColor: KawaiiTheme.primaryPink,
                              labelStyle: TextStyle(
                                color: isSelected ? KawaiiTheme.primaryPink : KawaiiTheme.textPrimary,
                                fontSize: 13,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // 日記內容輸入
                    const Text(
                      '內容',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: KawaiiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: controller,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: '記錄今天和貓咪的特別時光...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: KawaiiTheme.divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: KawaiiTheme.primaryPink, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 儲存按鈕
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final content = controller.text.trim();
                          if (content.isEmpty) {
                            TopToast.warning(context, message: '請輸入內容');
                            return;
                          }
                          await _diaryService.addEntry(
                            catId: selectedCat.id,
                            catName: selectedCat.name,
                            date: selectedDate,
                            content: content,
                            photoPath: selectedPhotoPath, // P3-4: 照片路徑
                            tags: _selectedTags, // P3-4 Phase 2: 標籤
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          setState(() {});
                          TopToast.success(context, message: '已儲存日記 🐱');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: KawaiiTheme.primaryPink,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '儲存',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// P3-4: 照片按鈕Widget
  Widget _buildPhotoButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: KawaiiTheme.softPink.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KawaiiTheme.primaryPink.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: KawaiiTheme.primaryPink, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: KawaiiTheme.primaryPink,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(TranslationResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => EmotionCard(
        result: result,
        onFeedback: (feedback) {
          Navigator.pop(context);
          // 更新歷史記錄
          _historyService.updateWithFeedback(result, feedback);
          setState(() {});
          // 顯示感謝
          TopToast.success(context, message: '謝謝修正，之後會更懂牠 🐱');
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return '剛剛';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分鐘前';
    if (diff.inHours < 24) return '${diff.inHours}小時前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    if (dateOnly == today) return '今天';
    if (dateOnly == today.subtract(const Duration(days: 1))) return '昨天';
    return '${date.month}月${date.day}日';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return KawaiiTheme.coral;
    return Colors.red;
  }
}