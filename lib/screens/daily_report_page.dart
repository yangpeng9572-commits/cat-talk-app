import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_cat_report.dart';
import '../models/cat.dart';
import '../models/translation_result.dart';
import '../models/bond.dart';
import '../services/daily_report_service.dart';
import '../services/cat_service.dart';
import '../services/cat_diary_service.dart';
import '../services/bond_service.dart';
import '../theme/kawaii_theme.dart';

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
  
  String? _selectedCatId;
  late List<Cat> _cats;
  DailyCatReport? _report;
  Bond? _currentBond;

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final prefs = await SharedPreferences.getInstance();
    await BondService().init(prefs);
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
      setState(() {
        _report = _reportService.getTodayReport(_selectedCatId!);
        _currentBond = BondService().getBond(_selectedCatId!);
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
              '今日貓咪報告',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '🐱 了解你家貓咪的情緒',
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
          : _report!.isEmpty
              ? _buildEmptyState()
              : _buildReportContent(_report!),
    );
  }

  /// 空狀態
  Widget _buildEmptyState() {
    final cat = _cats.firstWhere((c) => c.id == _selectedCatId);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          // 裝飾圖
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
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
            '今天還沒有 ${cat.name} 的紀錄',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '試著錄下第一聲喵，\n看看牠想表達什麼吧！',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // 引導按鈕
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
                Text(
                  '長按首頁的橘色按鈕錄下貓叫聲，\n翻譯完成後會自動記錄到今天的報告中。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
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
    final cat = _cats.firstWhere(
      (c) => c.id == report.catId,
      orElse: () => _cats.first,
    );

    // 取得默契值
    final bondScore = _currentBond?.bondScore ?? 0;
    
    // 產生日記
    final diary = _diaryService.generateDiary(
      catName: cat.name,
      dominantEmotion: report.dominantEmotion,
      totalTranslations: report.totalTranslations,
      emotionCounts: report.emotionCounts,
      averageConfidence: report.averageConfidence,
      bondScore: bondScore,
      taskCompleted: false, // TODO: 從 DailyTaskService 取得
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.heart_broken, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('分享卡片功能即將開放 🐾'),
                      ],
                    ),
                    backgroundColor: KawaiiTheme.primaryPink,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KawaiiTheme.radiusCircle),
                  boxShadow: [
                    BoxShadow(
                      color: KawaiiTheme.primaryPink.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.share, color: KawaiiTheme.primaryPink, size: 18),
                    SizedBox(width: 8),
                    Text(
                      '分享今天的小日記',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: KawaiiTheme.primaryPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('🐱', style: TextStyle(fontSize: 30)),
                ),
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
}
