import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/daily_cat_report.dart';
import '../models/cat.dart';
import '../models/translation_result.dart';
import '../models/bond.dart';
import '../models/user_diary_entry.dart';
import '../services/daily_report_service.dart';
import '../services/cat_service.dart';
import '../services/cat_diary_service.dart';
import '../services/bond_service.dart';
import '../services/share_card_service.dart';
import '../services/translation_history_service.dart';
import '../services/personality_analysis_service.dart';
import '../services/user_diary_service.dart';
import '../widgets/share_card_widget.dart';
import '../theme/kawaii_theme.dart';
import '../services/top_toast_service.dart';
import 'personality_card_page.dart';

/// 每日貓咪報告頁面
class DailyReportPage extends StatefulWidget {
  final String? preselectedCatId;

  const DailyReportPage({super.key, this.preselectedCatId});

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  final DailyReportService _reportService = DailyReportService();
  final CatDiaryService _diaryService = CatDiaryService();
  final ShareCardService _shareService = ShareCardService();
  final UserDiaryService _userDiaryService = UserDiaryService();
  
  String? _selectedCatId;
  late List<Cat> _cats;
  DailyCatReport? _report;
  Bond? _currentBond;
  CatDiary? _currentDiary;
  Cat? _currentCat;
  List<UserDiaryEntry> _userDiaryEntries = [];
  
  // Key for share card screenshot
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final prefs = await SharedPreferences.getInstance();
    await BondService().init(prefs);
    await _userDiaryService.init(prefs);
    final catService = CatService(prefs);
    _cats = catService.getAllCats();
    if (mounted) {
      setState(() {
        _selectedCatId = widget.preselectedCatId ?? (_cats.isNotEmpty ? _cats.first.id : null);
        _loadReport();
      });
    }
  }

  void _loadReport() {
    if (_selectedCatId != null) {
      final report = _reportService.getTodayReport(_selectedCatId!);
      final bond = BondService().getBond(_selectedCatId!);
      
      // Get cat
      final cats = _cats;
      final cat = cats.firstWhere(
        (c) => c.id == _selectedCatId,
        orElse: () => cats.first,
      );
      
      // Generate diary if report is not empty
      CatDiary? diary;
      if (!report.isEmpty) {
        diary = _diaryService.generateDiary(
          catName: cat.name,
          dominantEmotion: report.dominantEmotion,
          totalTranslations: report.totalTranslations,
          emotionCounts: report.emotionCounts,
          averageConfidence: report.averageConfidence,
          bondScore: bond?.bondScore ?? 0,
          taskCompleted: false,
        );
      }
      
      // Load user diary entries
      final userEntries = _userDiaryService.getByCatId(_selectedCatId!);
      
      setState(() {
        _report = report;
        _currentBond = bond;
        _currentDiary = diary;
        _currentCat = cat;
        _userDiaryEntries = userEntries;
      });
    }
  }

  void _onCatChanged(String catId) {
    setState(() {
      _selectedCatId = catId;
    });
    _loadReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '記錄',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '🐱 記錄你與貓咪的日常',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          // 貓咪選擇器
          if (_cats.length > 1)
            PopupMenuButton<String>(
              icon: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.orange,
                child: Icon(Icons.pets, color: Colors.white, size: 20),
              ),
              onSelected: _onCatChanged,
              itemBuilder: (context) => _cats.map((cat) {
                return PopupMenuItem<String>(
                  value: cat.id,
                  child: Row(
                    children: [
                      if (cat.id == _selectedCatId)
                        const Icon(Icons.check, color: Colors.orange, size: 18)
                      else
                        const SizedBox(width: 18),
                      const SizedBox(width: 8),
                      Text(cat.name),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _report == null
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _buildReportContent(_report!),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDiaryDialog,
        backgroundColor: KawaiiTheme.primaryPink,
        icon: const Icon(Icons.edit, color: Colors.white),
        label: const Text('寫日記', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /// 空狀態
  Widget _buildEmptyState() {
    final cat = _cats.firstWhere((c) => c.id == _selectedCatId);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 使用者日記區塊（始終顯示）=====
          _buildUserDiarySection(cat),
          const SizedBox(height: 24),
          // 其餘空狀態引導內容...
          const SizedBox(height: 40),
          // 裝飾圖
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '😺',
                style: TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            '今天還沒有和 ${cat.name} 的互動記錄',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '試著幫牠拍照、寫日記，\n或去小世界互動吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '💡 小提示',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '去首頁試試「姿勢拍照」或\n「陪牠小事」互動吧！',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 報告內容
  Widget _buildReportContent(DailyCatReport report) {
    final cat = _currentCat ?? _cats.firstWhere(
      (c) => c.id == report.catId,
      orElse: () => _cats.first,
    );

    // 取得默契值
    final bondScore = _currentBond?.bondScore ?? 0;
    final bondLevel = _currentBond?.levelName ?? '剛認識';
    
    // 產生日記（如果還沒有）
    final diary = _currentDiary ?? _diaryService.generateDiary(
      catName: cat.name,
      dominantEmotion: report.dominantEmotion,
      totalTranslations: report.totalTranslations,
      emotionCounts: report.emotionCounts,
      averageConfidence: report.averageConfidence,
      bondScore: bondScore,
      taskCompleted: false,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== 使用者日記區塊（始終顯示）=====
          _buildUserDiarySection(cat),
          const SizedBox(height: 16),

          // ===== 貓咪日記卡片（情感主角）=====
          _buildDiaryCard(diary),
          const SizedBox(height: 16),

          // ===== 今日心情 headline =====
          _buildCatInfoCard(cat, report),
          const SizedBox(height: 16),

          // ===== 今日翻譯次數 =====
          _buildSummaryCard(report),
          const SizedBox(height: 16),

          // ===== 情緒分布 =====
          _buildEmotionDistributionCard(report),
          const SizedBox(height: 16),

          // ===== 建議行動 =====
          _buildSuggestionCard(report),
          const SizedBox(height: 16),

          // ===== 安全提醒（如果需要）=====
          if (report.warningLevel != WarningLevel.normal)
            _buildWarningCard(report),
          const SizedBox(height: 16),

          // ===== 7天個性分析卡入口 =====
          _buildPersonalityCardEntry(),
          const SizedBox(height: 16),

          // ===== 歷史按鈕 =====
          _buildHistoryButton(),
        ],
      ),
    );
  }

  /// 貓咪日記卡片（情感主角）
  Widget _buildDiaryCard(CatDiary diary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            KawaiiTheme.softPink.withValues(alpha: 0.8),
            KawaiiTheme.peach.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Row(
            children: [
              const Icon(Icons.auto_stories, color: KawaiiTheme.primaryPink, size: 24),
              const SizedBox(width: 12),
              Text(
                diary.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: KawaiiTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 日記內容
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(KawaiiTheme.radiusMedium),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 日記文字（每行單獨顯示）
                ...diary.diaryText.split('\n').map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🌸 ', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Text(
                          line,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: KawaiiTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // 心情短句
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, color: KawaiiTheme.coral, size: 16),
                const SizedBox(width: 8),
                Text(
                  diary.moodSentence,
                  style: const TextStyle(
                    fontSize: 13,
                    color: KawaiiTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // 分享按鈕
          Center(
            child: _buildShareButton(),
          ),
        ],
      ),
    );
  }

  /// 新增日記對話框
  Future<void> _showAddDiaryDialog() async {
    if (_selectedCatId == null) return;
    final cat = _cats.firstWhere((c) => c.id == _selectedCatId);
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('寫日記'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '記錄和${cat.name}的一天...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: KawaiiTheme.primaryPink),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('儲存', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true && controller.text.trim().isNotEmpty) {
      await _userDiaryService.addEntry(
        catId: cat.id,
        catName: cat.name,
        date: DateTime.now(),
        content: controller.text.trim(),
      );
      final entries = _userDiaryService.getByCatId(_selectedCatId!);
      if (!mounted) return;
      setState(() => _userDiaryEntries = entries);
      TopToastService.success(context, message: '已記錄下來了 💕');
    }
    controller.dispose();
  }

  /// 使用者日記區塊
  Widget _buildUserDiarySection(Cat cat) {
    if (_userDiaryEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.book_outlined, size: 32, color: Color(0xFFBDBDBD)),
            const SizedBox(height: 8),
            Text('還沒有和${cat.name}的日記', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('生活日記', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._userDiaryEntries.take(3).map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE4E1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${e.date.month}/${e.date.day}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(e.content, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        )),
      ],
    );
  }

  /// 貓咪頭像元件（與 home_page / summer_window_page 一致的顯示邏輯）
  Widget _buildCatAvatar(
    String? avatarPath, {
    double radius = 24,
    double iconSize = 24,
    Color backgroundColor = const Color(0xFFFFE0B2),
    Color iconColor = const Color(0xFFFF8A65),
  }) {
    final hasValidPath = avatarPath != null &&
        avatarPath.isNotEmpty &&
        !avatarPath.startsWith('content://') &&
        File(avatarPath).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: hasValidPath ? FileImage(File(avatarPath)) : null,
      child: hasValidPath
          ? null
          : Icon(
              Icons.pets,
              color: iconColor,
              size: iconSize,
            ),
    );
  }

  /// 貓咪資訊卡片
  Widget _buildCatInfoCard(Cat cat, DailyCatReport report) {
    return Column(
      children: [
        // 一句話摘要（最顯眼）
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(report.dominantEmotion?.colorValue ?? 0xFFFF8C00),
                Color(report.dominantEmotion?.colorValue ?? 0xFFFF6B00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Text(
                report.headlineText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (report.dominantEmotion != null) ...[
                    Text(
                      report.dominantEmotion!.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      report.dominantEmotion!.label,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        // 貓咪資訊（橘色底，白色內容）
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF8C00), Color(0xFFFF6B00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Row(
            children: [
              // 貓咪頭像
              _buildCatAvatar(
                cat.avatarPath,
                radius: 30,
                iconSize: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                iconColor: Colors.white,
              ),
              const SizedBox(width: 16),
              // 資訊
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cat.breed,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              // 日期
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(report.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 今日總結卡片
  Widget _buildSummaryCard(DailyCatReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('📊', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text(
                '今日總結',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.summaryText,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// 情緒分布卡片
  Widget _buildEmotionDistributionCard(DailyCatReport report) {
    final sortedEmotions = report.emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💝', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text(
                '情緒分布',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '共 ${report.totalTranslations} 次翻譯',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // 主要情緒
          if (report.dominantEmotion != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(report.dominantEmotion!.colorValue).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(report.dominantEmotion!.colorValue).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    report.dominantEmotion!.emoji,
                    style: const TextStyle(fontSize: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '主要情緒：${report.dominantEmotion!.label}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(report.dominantEmotion!.colorValue),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${report.emotionCounts[report.dominantEmotion]} 次（${((report.emotionCounts[report.dominantEmotion]! / report.totalTranslations) * 100).round()}%）',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          // 其他情緒列表
          ...sortedEmotions
              .where((e) => e.key != report.dominantEmotion)
              .take(4)
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(entry.key.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          entry.key.label,
                          style: const TextStyle(fontSize: 14),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${entry.value}次',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
        ],
      ),
    );
  }

  /// 建議行動卡片
  Widget _buildSuggestionCard(DailyCatReport report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('💡', style: TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 12),
              const Text(
                '建議行動',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            report.suggestedAction,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 警示卡片
  Widget _buildWarningCard(DailyCatReport report) {
    final level = report.warningLevel;
    final color = level == WarningLevel.notice ? Colors.orange : Colors.red;
    final bgColor = level == WarningLevel.notice ? Colors.orange.shade50 : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(
            level.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${level.label}提醒',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '這只是行為與聲音推測，若牠持續異常，建議諮詢獸醫。',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 信心值卡片
  Widget _buildConfidenceCard(DailyCatReport report) {
    final percent = (report.averageConfidence * 100).round();
    final color = percent >= 70 ? Colors.green : (percent >= 50 ? Colors.orange : Colors.red);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.psychology,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '平均翻譯信心度',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$percent%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (percent < 50)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '需要學習',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 查看歷史按鈕
  Widget _buildHistoryButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: const BorderSide(color: Colors.orange),
        ),
        onPressed: () {
          // TODO: 導航到歷史頁面
          Navigator.pop(context);
        },
        icon: const Icon(Icons.history, color: Colors.orange),
        label: const Text(
          '查看翻譯歷史',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 7天個性分析卡入口
  Widget _buildPersonalityCardEntry() {
    return FutureBuilder<bool>(
      future: _hasEnoughDataForPersonality(),
      builder: (context, snapshot) {
        final hasData = snapshot.data ?? false;
        if (!hasData) {
          // 資料不足，顯示空狀態提示
          return Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: KawaiiTheme.primaryPink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '再記錄幾天',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: KawaiiTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        '我就能更了解她 🐾',
                        style: TextStyle(
                          fontSize: 12,
                          color: KawaiiTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // 有足夠資料，顯示入口按鈕
        return Container(
          margin: const EdgeInsets.only(top: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => _openPersonalityCard(),
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text(
                '查看她的 7 天小檔案',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _hasEnoughDataForPersonality() async {
    if (_selectedCatId == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final historyService = TranslationHistoryService();
    await historyService.init(prefs);
    final translations = historyService.getByCatIdWithinDays(_selectedCatId!, 7);
    return translations.length >= 3;
  }

  void _openPersonalityCard() {
    if (_selectedCatId == null) return;
    final cat = _cats.firstWhere(
      (c) => c.id == _selectedCatId,
      orElse: () => _cats.first,
    );
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonalityCardPage(
          catId: _selectedCatId!,
          cat: cat,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(date.year, date.month, date.day);

    if (targetDay == today) {
      return '今天';
    } else if (targetDay == today.subtract(const Duration(days: 1))) {
      return '昨天';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  /// 分享按鈕
  Widget _buildShareButton() {
    final hasDiary = _currentDiary != null;
    final hasCat = _currentCat != null;
    
    return GestureDetector(
      onTap: hasDiary ? () => _showShareMenu() : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: hasDiary ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
          boxShadow: [
            BoxShadow(
              color: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.share, 
              color: hasDiary ? KawaiiTheme.primaryPink : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              hasDiary ? '分享今天的小日記' : '今天還沒有小日記可以分享 🐾',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: hasDiary ? KawaiiTheme.primaryPink : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顯示分享選單
  void _showShareMenu() {
    if (_currentDiary == null || _currentCat == null) {
      TopToastService.info(context, message: '今天還沒有小日記可以分享 🐾');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '分享今天的小日記 🐾',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: KawaiiTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            
            // 分享可愛卡片（IG/FB/LINE）
            _ShareOption(
              icon: Icons.image,
              title: '分享可愛卡片',
              subtitle: 'IG / FB / LINE',
              color: KawaiiTheme.coral,
              onTap: () {
                Navigator.pop(context);
                _shareCardImage();
              },
            ),
            const SizedBox(height: 12),
            
            // 分享到 Threads
            _ShareOption(
              icon: Icons.article,
              title: '分享到 Threads',
              subtitle: '脆鳥專用文案',
              color: Colors.black87,
              onTap: () {
                Navigator.pop(context);
                _shareToThreads();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 分享卡片圖片（IG/FB/LINE）
  Future<void> _shareCardImage() async {
    if (_currentDiary == null || _currentCat == null) return;

    // Show loading
    if (!mounted) return;
    TopToastService.show(context, message: '產生分享卡片中...', backgroundColor: KawaiiTheme.primaryPink);

    // Get top speech (from latest translation if available)
    final topSpeech = _report?.totalTranslations != null && _report!.totalTranslations > 0
        ? '今天也很想跟你說說話 💕'
        : _currentDiary!.moodSentence;

    // Get emotion sentence
    final emotion = _report?.dominantEmotion;
    final emotionSentence = _getEmotionSentence(emotion);

    // Build share card widget wrapped in RepaintBoundary
    final shareWidget = RepaintBoundary(
      key: _shareCardKey,
      child: ShareCardWidget(
        catName: _currentCat!.name,
        diaryTitle: _currentDiary!.title,
        emotionSentence: emotionSentence,
        topSpeech: topSpeech,
        bondScore: _currentBond?.bondScore ?? 0,
        bondLevel: _currentBond?.levelName ?? '剛認識',
      ),
    );

    try {
      // Use the global key to capture the widget
      final imageBytes = await _shareService.generateShareCardImage(
        catName: _currentCat!.name,
        diaryText: _currentDiary!.diaryText,
        emotion: _report?.dominantEmotion,
        topSpeech: topSpeech,
        bondScore: _currentBond?.bondScore ?? 0,
        repaintBoundaryKey: _shareCardKey,
      );

      if (!mounted) return;

      if (imageBytes == null) {
        _showShareError();
        return;
      }

      // Save to temp file and share
      final filePath = await _shareService.saveShareCardImage(
        catName: _currentCat!.name,
        diaryText: _currentDiary!.diaryText,
        emotion: _report?.dominantEmotion,
        topSpeech: topSpeech,
        bondScore: _currentBond?.bondScore ?? 0,
        repaintBoundaryKey: _shareCardKey,
      );

      if (!mounted) return;

      if (filePath != null) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: '${_currentCat!.name} 今天的小日記 🐱 #喵心語 #貓咪日記',
        );
      } else {
        _showShareError();
      }
    } catch (e) {
      if (!mounted) return;
      _showShareError();
    }
  }

  /// 分享到 Threads
  Future<void> _shareToThreads() async {
    if (_currentDiary == null || _currentCat == null) return;

    // Get speech to share
    final speech = _report?.totalTranslations != null && _report!.totalTranslations > 0
        ? '今天也很想跟你說說話 💕'
        : _currentDiary!.moodSentence;

    // Generate Threads caption
    final caption = _shareService.generateThreadsCaption(
      catName: _currentCat!.name,
      speech: speech,
      emotion: _report?.dominantEmotion,
    );

    // Share via system share
    await Share.share(caption);
  }

  /// 顯示分享錯誤
  void _showShareError() {
    if (!mounted) return;
    TopToastService.error(context, message: '分享失敗了，請再試一次 🐾');
  }

  /// 取得情緒句
  String _getEmotionSentence(EmotionType? emotion) {
    if (emotion == null) {
      return 'Today she is special';
    }
    const sentences = {
      EmotionType.affectionate: 'Today she wanted to cuddle all day',
      EmotionType.hungry: 'Today she kept reminding about food',
      EmotionType.playful: 'Today she really wanted to play',
      EmotionType.attention: 'Today she wanted attention',
      EmotionType.anxious: 'Today she seemed a bit worried',
      EmotionType.angry: 'Today she did not want to be disturbed',
      EmotionType.uncomfortable: 'Today she felt a bit uncomfortable',
      EmotionType.greeting: 'Today she was greeting me',
      EmotionType.other: 'Today she had her own little mood',
    };
    return sentences[emotion] ?? 'Today she is special';
  }
}

/// 分享選項 widget
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 18),
          ],
        ),
      ),
    );
  }
}
