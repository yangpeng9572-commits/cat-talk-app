import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cat.dart';
import '../models/translation_result.dart';
import '../services/personality_analysis_service.dart';
import '../services/translation_history_service.dart';
import '../services/daily_report_service.dart';
import '../services/bond_service.dart';
import '../services/cat_learning_service.dart';
import '../services/share_card_service.dart';
import '../services/top_toast_service.dart';
import '../theme/kawaii_theme.dart';

/// 7天貓咪個性分析卡頁面
class PersonalityCardPage extends StatefulWidget {
  final String catId;
  final Cat cat;

  const PersonalityCardPage({
    super.key,
    required this.catId,
    required this.cat,
  });

  @override
  State<PersonalityCardPage> createState() => _PersonalityCardPageState();
}

class _PersonalityCardPageState extends State<PersonalityCardPage> {
  PersonalityAnalysis? _analysis;
  bool _isLoading = true;
  bool _isGeneratingShareCard = false;

  // Services
  late TranslationHistoryService _historyService;
  late DailyReportService _reportService;
  late BondService _bondService;
  late CatLearningService _learningService;
  late PersonalityAnalysisService _analysisService;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  Future<void> _loadAnalysis() async {
    final prefs = await SharedPreferences.getInstance();

    _historyService = TranslationHistoryService();
    await _historyService.init(prefs);

    _learningService = CatLearningService();
    await _learningService.init(prefs);

    _reportService = DailyReportService(
      historyService: _historyService,
      learningService: _learningService,
    );
    await _reportService.init(prefs);

    _bondService = BondService();
    await _bondService.init(prefs);

    _analysisService = PersonalityAnalysisService(
      historyService: _historyService,
      reportService: _reportService,
      bondService: _bondService,
      learningService: _learningService,
    );

    final analysis = _analysisService.getAnalysis(
      widget.catId,
      widget.cat.name,
    );

    setState(() {
      _analysis = analysis;
      _isLoading = false;
    });
  }

  Future<void> _shareCard() async {
    if (_analysis == null || !_analysis!.hasEnoughData) return;

    setState(() => _isGeneratingShareCard = true);

    try {
      final shareService = ShareCardService();
      final imagePath = await shareService.generatePersonalityCard(
        catName: widget.cat.name,
        personalityType: _analysis!.personalityType,
        personalityDescription: _analysis!.personalityDescription,
        topEmotion: _analysis!.topEmotions.firstOrNull ?? EmotionType.other,
        bondScore: _bondService.getBond(widget.catId).bondScore,
      );

      if (mounted && imagePath != null) {
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: '${widget.cat.name} 的 7 天小檔案 🐱 #喵心語 #貓咪个性',
        );
      }
    } catch (e) {
      if (mounted) {
        TopToastService.error(context, message: '分享卡生成失敗，請稍後再試 🥺');
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingShareCard = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.creamWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: KawaiiTheme.primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.cat.name}的7天小檔案 🐱',
          style: const TextStyle(
            color: KawaiiTheme.primaryPink,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analysis == null || !_analysis!.hasEnoughData
              ? _buildEmptyState()
              : _buildContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: KawaiiTheme.softPink.withValues(alpha: 77/255),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets,
                size: 60,
                color: KawaiiTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '再記錄幾天',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: KawaiiTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '我就能更了解她 🐾',
              style: TextStyle(
                fontSize: 18,
                color: KawaiiTheme.primaryPink,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KawaiiTheme.softPink.withValues(alpha: 51/255),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '需要至少 3 筆翻譯記錄\n才能產出分析報告',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: KawaiiTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final analysis = _analysis!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 個性類型卡片
          _buildPersonalityCard(analysis),
          const SizedBox(height: 20),

          // TOP 3 情緒
          _buildTopEmotionsCard(analysis),
          const SizedBox(height: 20),

          // 數據統計
          _buildStatsCard(analysis),
          const SizedBox(height: 20),

          // 主人建議
          _buildSuggestionCard(analysis),
          const SizedBox(height: 32),

          // 分享按鈕
          _buildShareButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildPersonalityCard(PersonalityAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [KawaiiTheme.primaryPink, KawaiiTheme.softPink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: KawaiiTheme.primaryPink.withValues(alpha: 77/255),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // 貓咪名字
          Text(
            analysis.catName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          // 個性類型
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 51/255),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              analysis.personalityType,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 描述
          Text(
            analysis.personalityDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 230/255),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEmotionsCard(PersonalityAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13/255),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('🏆 ', style: TextStyle(fontSize: 20)),
              Text(
                'TOP 3 情緒',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KawaiiTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...analysis.topEmotions.asMap().entries.map((entry) {
            final index = entry.key;
            final emotion = entry.value;
            final count = analysis.emotionCounts[emotion] ?? 0;
            const medals = ['🥇', '🥈', '🥉'];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(medals[index], style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getEmotionName(emotion),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: KawaiiTheme.softPink,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$count 次',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: KawaiiTheme.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatsCard(PersonalityAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13/255),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊 ', style: TextStyle(fontSize: 20)),
              Text(
                '7 天數據',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: KawaiiTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('🐾', '翻譯次數', '${analysis.totalTranslations} 次'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem('💕', '默契成長', '+${analysis.bondGrowth}'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatItem('🎯', '平均信心值', '${(analysis.averageConfidence * 100).toStringAsFixed(0)}%'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KawaiiTheme.creamWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: KawaiiTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: KawaiiTheme.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(PersonalityAnalysis analysis) {
    final hasWarning = analysis.topEmotions.contains(EmotionType.uncomfortable);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasWarning ? KawaiiTheme.peach.withValues(alpha: 77/255) : KawaiiTheme.lavender.withValues(alpha: 77/255),
        borderRadius: BorderRadius.circular(20),
        border: hasWarning ? Border.all(color: KawaiiTheme.peach, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(hasWarning ? '⚠️ ' : '💡 ', style: const TextStyle(fontSize: 20)),
              Text(
                hasWarning ? '貼心提醒' : '陪伴建議',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: hasWarning ? KawaiiTheme.peach : KawaiiTheme.lavender,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            analysis.ownerSuggestion,
            style: TextStyle(
              fontSize: 16,
              color: hasWarning ? KawaiiTheme.textPrimary : KawaiiTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton() {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: _isGeneratingShareCard ? null : _shareCard,
        style: ElevatedButton.styleFrom(
          backgroundColor: KawaiiTheme.primaryPink,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          elevation: 4,
        ),
        child: _isGeneratingShareCard
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.share, size: 24),
                  SizedBox(width: 8),
                  Text('分享這張小檔案', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }

  String _getEmotionName(EmotionType emotion) {
    switch (emotion) {
      case EmotionType.affectionate:
        return '🥰 撒嬌';
      case EmotionType.hungry:
        return '🍽️ 餓了';
      case EmotionType.playful:
        return '🎾 想玩';
      case EmotionType.attention:
        return '👀 需要關注';
      case EmotionType.anxious:
        return '😰 焦慮';
      case EmotionType.angry:
        return '😾 生氣';
      case EmotionType.greeting:
        return '🐱 打招呼';
      case EmotionType.uncomfortable:
        return '🤒 不舒服';
      case EmotionType.other:
        return '🐾 其他';
    }
  }
}