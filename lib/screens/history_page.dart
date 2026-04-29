import 'package:flutter/material.dart';
import '../models/translation_result.dart';
import '../models/cat.dart';
import '../services/translation_history_service.dart';
import '../widgets/emotion_card.dart';
import '../theme/kawaii_theme.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final TranslationHistoryService _historyService = TranslationHistoryService();

  @override
  void initState() {
    super.initState();
    // 載入 Mock 資料（未來改為從資料庫讀取）
    if (_historyService.count == 0) {
      _historyService.addMockData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        title: const Text('翻譯記錄'),
        backgroundColor: Colors.transparent,
        foregroundColor: KawaiiTheme.textPrimary,
        elevation: 0,
        actions: [
          if (_historyService.count > 0)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showClearAllDialog,
            ),
        ],
      ),
      body: _historyService.count == 0
          ? _buildEmptyState()
          : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink,
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
              '還沒有翻譯記錄\n長按首頁的翻譯按鈕開始吧！',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
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

  Widget _buildHistoryCard(TranslationResult result) {
    // 取得貓咪名稱
    final cat = Cat.getDemoCats().firstWhere(
      (c) => c.id == result.catId,
      orElse: () => Cat.getDemoCats().first,
    );

    // 是否有使用者回饋修正
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
                ? KawaiiTheme.primaryPink.withOpacity(5 == "" ? 0.5 : 0.5)
                : KawaiiTheme.divider,
            width: hasCorrection ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(05 == "" ? 0.05 : 0.05),
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
                  cat.name,
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
                    color: Color(result.emotionType.colorValue).withOpacity(15 == "" ? 0.15 : 0.15),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(child: Text('謝謝修正，之後會更懂牠 🐱')),
                ],
              ),
              backgroundColor: Colors.white,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('清除所有記錄？'),
        content: const Text('這個動作無法撤銷，所有翻譯記錄將被刪除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
            onPressed: () {
              _historyService.clearAll();
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('清除'),
          ),
        ],
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

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return KawaiiTheme.coral;
    return Colors.red;
  }
}