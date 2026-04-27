import 'package:flutter/material.dart';
import '../models/translation_result.dart';

/// 情緒卡片 widget
/// 溫暖可愛的設計，適合一般貓咪飼主理解
class EmotionCard extends StatelessWidget {
  final TranslationResult result;
  final void Function(UserFeedback feedback) onFeedback;
  final VoidCallback onClose;

  const EmotionCard({
    super.key,
    required this.result,
    required this.onFeedback,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(result.emotionType.colorValue).withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖動條
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 主要內容
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Emoji 和情緒標籤
                _buildEmotionHeader(),
                const SizedBox(height: 20),

                // 人類翻譯
                _buildHumanText(),
                const SizedBox(height: 20),

                // 信心值
                _buildConfidenceBar(),
                const SizedBox(height: 16),

                // 低信心提示（< 50%）
                if (result.confidence < 0.5) _buildLowConfidenceHint(),

                // 原因和建議（一起顯示）
                _buildReasonAndAction(),
                const SizedBox(height: 24),

                // 按鈕區域
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Color(result.emotionType.colorValue).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            result.emotionType.emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Text(
            result.emotionType.label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(result.emotionType.colorValue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHumanText() {
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
        children: [
          const Text(
            '🐱 貓咪想說：',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.humanText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceBar() {
    final confidencePercent = (result.confidence * 100).round();
    final color = _getConfidenceColor(result.confidence);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              result.confidence < 0.5 ? '🤔 這次不太確定' : '💪 翻譯信心度',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: result.confidence < 0.5 ? Colors.orange : Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$confidencePercent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: result.confidence,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLowConfidenceHint() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: const Row(
        children: [
          Text('🤔', style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '這次判斷不太確定，請幫我修正，之後我會更懂牠。',
              style: TextStyle(
                fontSize: 13,
                color: Colors.orange,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonAndAction() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade100),
      ),
      child: Column(
        children: [
          // 可能原因
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔍', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '為什麼我這樣說？',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.reason,
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
          const SizedBox(height: 12),
          Container(height: 1, color: Colors.orange.shade100),
          const SizedBox(height: 12),
          // 建議行動
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('💡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '建議這樣做',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.suggestedAction,
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
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // 主要按鈕列
        Row(
          children: [
            // 正確按鈕
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final feedback = UserFeedback.correct();
                  onFeedback(feedback);
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text(
                  '正確',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 不準按鈕
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: const BorderSide(color: Colors.red, width: 1.5),
                ),
                onPressed: () => _showFeedbackOptions(context),
                icon: const Icon(Icons.cancel_outlined, size: 20),
                label: const Text(
                  '不準',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 自訂備註
        TextButton.icon(
          onPressed: () => _showCustomNoteDialog(context),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade600,
          ),
          icon: const Icon(Icons.note_add, size: 18),
          label: const Text(
            '新增備註',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _showFeedbackOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _FeedbackOptionsSheet(
        onSelectEmotion: (emotion, isCustom, customNote) {
          final feedback = UserFeedback(
            isCorrect: false,
            correctedEmotion: emotion.name,
            comment: customNote,
            timestamp: DateTime.now(),
          );
          onFeedback(feedback);
        },
      ),
    );
  }

  void _showCustomNoteDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('📝 ', style: TextStyle(fontSize: 24)),
            Text('自訂備註'),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: '記錄你想備注的內容...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final feedback = UserFeedback(
                  isCorrect: false,
                  comment: controller.text,
                  timestamp: DateTime.now(),
                );
                Navigator.pop(context);
                onFeedback(feedback);
              }
            },
            child: const Text('送出'),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

class _FeedbackOptionsSheet extends StatefulWidget {
  final void Function(EmotionType emotion, bool isCustom, String? customNote) onSelectEmotion;

  const _FeedbackOptionsSheet({required this.onSelectEmotion});

  @override
  State<_FeedbackOptionsSheet> createState() => _FeedbackOptionsSheetState();
}

class _FeedbackOptionsSheetState extends State<_FeedbackOptionsSheet> {
  String? _customNote;
  final TextEditingController _noteController = TextEditingController();

  final List<_QuickFeedback> _quickOptions = [
    _QuickFeedback(EmotionType.hungry, '🍽️', '牠是想吃飯'),
    _QuickFeedback(EmotionType.affectionate, '💕', '牠是想撒嬌'),
    _QuickFeedback(EmotionType.playful, '🎾', '牠是想玩'),
    _QuickFeedback(EmotionType.anxious, '😿', '牠是焦慮'),
    _QuickFeedback(EmotionType.uncomfortable, '🤒', '牠可能不舒服'),
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '選擇正確的情緒',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickOptions.map((option) {
                return GestureDetector(
                  onTap: () {
                    widget.onSelectEmotion(option.emotion, false, _customNote);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(option.emotion.colorValue).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(option.emotion.colorValue).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(option.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          option.label,
                          style: TextStyle(
                            color: Color(option.emotion.colorValue),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.note, size: 18, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      '附加備註（選填）',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: '例如：當時在廚房附近...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                  onChanged: (value) {
                    setState(() => _customNote = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _QuickFeedback {
  final EmotionType emotion;
  final String emoji;
  final String label;
  _QuickFeedback(this.emotion, this.emoji, this.label);
}

void showFeedbackThanksDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🐱',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '這些回饋會幫助我更懂你的貓',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        Center(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('太好了！'),
          ),
        ),
      ],
    ),
  );
}
