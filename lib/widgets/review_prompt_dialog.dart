import 'package:flutter/material.dart';
import '../services/review_service.dart';

/// 評價引導 Dialog（情感分流版）
class ReviewPromptDialog extends StatefulWidget {
  final ReviewService reviewService;

  const ReviewPromptDialog({
    super.key,
    required this.reviewService,
  });

  @override
  State<ReviewPromptDialog> createState() => _ReviewPromptDialogState();
}

class _ReviewPromptDialogState extends State<ReviewPromptDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showFeedbackInput = false;
  final TextEditingController _feedbackController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _heartAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  void _startHeartAnimation() {
    _heartController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8F0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF8FAB).withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_showFeedbackInput) _buildFirstLayer(),
            if (_showFeedbackInput) _buildFeedbackInput(),
          ],
        ),
      ),
    );
  }

  /// 第一層：情緒分流
  Widget _buildFirstLayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 標題
        const Text(
          '今天有更了解她一點嗎？🐱',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // 按鈕區
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            _buildEmojiButton('🥰 有！很開心', () => _handlePositive(context)),
            _buildEmojiButton('😐 還好', () => _handleNeutral(context)),
            _buildEmojiButton('😕 沒什麼感覺', () => _handleNegative(context)),
          ],
        ),
        const SizedBox(height: 16),

        // 不要再提醒
        TextButton(
          onPressed: () => _handleDisable(context),
          child: const Text(
            '不要再提醒',
            style: TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  /// 正向：顯示評價邀請
  Widget _buildPositiveLayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 愛心動畫
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: 0.5 + (_heartAnimation.value * 0.5),
              child: Transform.scale(
                scale: 0.8 + (_heartAnimation.value * 0.2),
                child: const Text(
                  '💕',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        const Text(
          '太好了 💕\n可以給我們一點支持嗎？\n這會讓更多人更懂自己的貓 🐾',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton('⭐️ 去支持我們', () => _handleGoToStore(context)),
            _buildActionButton('稍後再說', () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }

  /// 中立/負向：顯示感謝
  Widget _buildNeutralLayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🐾',
          style: TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 16),

        const Text(
          '謝謝你告訴我們 🐾\n我們會努力讓她更懂你',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton('告訴我們哪裡可以更好', () {
              setState(() => _showFeedbackInput = true);
            }),
            _buildActionButton('先不用', () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }

  /// 內部回饋輸入
  Widget _buildFeedbackInput() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '想讓她更懂你嗎？',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        const Text(
          '告訴我們哪裡可以更好，\n或哪一次結果不像她。',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF8A8A8A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: '例如：她明明是高興的，結果顯示是生氣...',
            hintStyle: const TextStyle(color: Color(0xFFB0B0B0)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton('送出', () => _handleSubmitFeedback(context)),
            _buildActionButton('先不用', () => Navigator.pop(context)),
          ],
        ),
      ],
    );
  }

  /// 送出成功
  Widget _buildFeedbackSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🐾',
          style: TextStyle(fontSize: 48),
        ),
        const SizedBox(height: 16),

        const Text(
          '謝謝你，我們會把這些意見記下來 🐾',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildActionButton('確定', () => Navigator.pop(context)),
      ],
    );
  }

  /// 正向回饋成功
  Widget _buildSuccessLayer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _heartAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: 0.5 + (_heartAnimation.value * 0.5),
              child: Transform.scale(
                scale: 0.8 + (_heartAnimation.value * 0.2),
                child: const Text(
                  '💕💕💕',
                  style: TextStyle(fontSize: 48),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        const Text(
          '謝謝你 💕\n你們的默契又更靠近了一點',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4A4A4A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        _buildActionButton('確定', () => Navigator.pop(context)),
      ],
    );
  }

  // ==================== 按鈕建構 ====================

  Widget _buildEmojiButton(String label, VoidCallback onPressed) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE4D6)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF4A4A4A),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8FAB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Text(label),
    );
  }

  // ==================== 事件處理 ====================

  void _handlePositive(BuildContext context) {
    _startHeartAnimation();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8FAB).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: _buildPositiveLayer(),
        ),
      ),
    );
  }

  void _handleNeutral(BuildContext context) {
    Navigator.pop(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF8FAB).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: _buildNeutralLayer(),
        ),
      ),
    );
  }

  void _handleNegative(BuildContext context) {
    _handleNeutral(context); // 流程一樣
  }

  void _handleDisable(BuildContext context) async {
    await widget.reviewService.disableReviewPromptForever();
    if (context.mounted) {
      Navigator.pop(context);
    }
  }

  void _handleGoToStore(BuildContext context) async {
    Navigator.pop(context); // 關閉 dialog
    await widget.reviewService.openStoreReview();

    // 顯示成功
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8FAB).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: _buildSuccessLayer(),
          ),
        ),
      );
    }
  }

  void _handleSubmitFeedback(BuildContext context) async {
    final feedback = _feedbackController.text.trim();
    if (feedback.isEmpty) return;

    await widget.reviewService.saveUserFeedback(feedback);

    if (context.mounted) {
      Navigator.pop(context); // 關閉輸入 dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8F0),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8FAB).withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: _buildFeedbackSuccess(),
          ),
        ),
      );
    }
  }
}

/// 顯示評價引導 Dialog
Future<void> showReviewPromptIfNeeded(BuildContext context) async {
  final reviewService = ReviewService();

  if (!await reviewService.shouldShowReviewPrompt()) return;

  await reviewService.showReviewPrompt();

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (context) => ReviewPromptDialog(reviewService: reviewService),
  );
}
