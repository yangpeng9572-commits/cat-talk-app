import 'package:flutter/material.dart';
import '../models/translation_result.dart';
import '../services/audio_player_service.dart';
import '../services/cat_speech_service.dart';
import '../theme/kawaii_theme.dart';

/// 情緒卡片 widget - 情感陪伴版
/// 溫暖可愛的設計，貓咪擬人化語氣
class EmotionCard extends StatefulWidget {
  final TranslationResult result;
  final void Function(UserFeedback feedback) onFeedback;
  final VoidCallback onClose;
  final String catName; // 貓咪名稱，用於個人化文字

  const EmotionCard({
    super.key,
    required this.result,
    required this.onFeedback,
    required this.onClose,
    this.catName = '你的貓',
  });

  @override
  State<EmotionCard> createState() => _EmotionCardState();
}

class _EmotionCardState extends State<EmotionCard> with SingleTickerProviderStateMixin {
  final AudioPlayerService _playerService = AudioPlayerService();
  final CatSpeechService _catSpeechService = CatSpeechService();
  bool _isPlaying = false;
  
  // 解析翻譯結果
  late CatSpeechResult _speechResult;
  
  // 動畫控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _speechResult = _catSpeechService.generateSpeechResult(widget.result);
    
    // 動畫設定
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _playerService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emotionColor = Color(widget.result.emotionType.colorValue);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              emotionColor.withValues(alpha: 0.08),
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
                  // 情緒強度標籤
                  _buildEmotionIntensityLabel(emotionColor),
                  const SizedBox(height: 16),

                  // 貓咪說的話
                  _buildCatSpeech(emotionColor),
                  const SizedBox(height: 16),

                  // 信心度提示
                  _buildConfidenceHint(),
                  const SizedBox(height: 16),

                  // 推測原因
                  _buildReason(),
                  const SizedBox(height: 16),

                  // 建議行動按鈕
                  _buildActionButtons(emotionColor),
                  const SizedBox(height: 20),

                  // 播放錄音按鈕
                  _buildPlayRecordingButton(),
                  const SizedBox(height: 16),

                  // 回饋區
                  _buildFeedbackSection(emotionColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 情緒強度標籤
  Widget _buildEmotionIntensityLabel(Color emotionColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: emotionColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _speechResult.emotionIntensity,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: emotionColor,
        ),
      ),
    );
  }

  /// 貓咪說的話
  Widget _buildCatSpeech(Color emotionColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: emotionColor.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 標題
          Text(
            '${widget.catName} 可能想說：',
            style: TextStyle(
              fontSize: 14,
              color: KawaiiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          
          // Emoji（大一點）
          Text(
            widget.result.emotionType.emoji,
            style: const TextStyle(fontSize: 56),
          ),
          const SizedBox(height: 16),
          
          // 主要翻譯文字
          Text(
            _speechResult.speech,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.4,
              color: KawaiiTheme.textPrimary,
            ),
          ),
          
          // 獸醫提醒（如果是不舒服的話）
          if (_speechResult.needsVetReminder) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  const Text('⚠️', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '這只是聲音與行為推測，若持續異常，建議諮詢獸醫。',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 信心度提示
  Widget _buildConfidenceHint() {
    if (_speechResult.isHighConfidence) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 18),
            const SizedBox(width: 8),
            Text(
              _catSpeechService.getHighConfidenceHint(),
              style: TextStyle(
                fontSize: 13,
                color: Colors.green.shade800,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_speechResult.isLowConfidence) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🤔', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _catSpeechService.getLowConfidenceHint(),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.orange.shade800,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  /// 推測原因
  Widget _buildReason() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: KawaiiTheme.creamWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _speechResult.reason,
              style: TextStyle(
                fontSize: 14,
                color: KawaiiTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 建議行動按鈕
  Widget _buildActionButtons(Color emotionColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text(
              '你可以試試：',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KawaiiTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _speechResult.suggestedActions.map((action) {
            return GestureDetector(
              onTap: () => _onActionTapped(action),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: emotionColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: emotionColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getActionIcon(action),
                      size: 16,
                      color: emotionColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      action,
                      style: TextStyle(
                        fontSize: 14,
                        color: emotionColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  IconData _getActionIcon(String action) {
    if (action.contains('摸摸') || action.contains('抱')) {
      return Icons.favorite;
    }
    if (action.contains('飯') || action.contains('吃') || action.contains('水')) {
      return Icons.restaurant;
    }
    if (action.contains('玩') || action.contains('逗')) {
      return Icons.sports_tennis;
    }
    if (action.contains('看') || action.contains('注意')) {
      return Icons.visibility;
    }
    if (action.contains('陪') || action.contains('空間')) {
      return Icons.access_time;
    }
    if (action.contains('叫') || action.contains('回')) {
      return Icons.chat_bubble;
    }
    if (action.contains('觀察') || action.contains('檢查')) {
      return Icons.search;
    }
    if (action.contains('獸醫')) {
      return Icons.local_hospital;
    }
    if (action.contains('打') || action.contains('頭')) {
      return Icons.waving_hand;
    }
    return Icons.pets;
  }

  void _onActionTapped(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.favorite, color: KawaiiTheme.primaryPink, size: 20),
            const SizedBox(width: 12),
            Text(_catSpeechService.getActionCompletedFeedback()),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        ),
        duration: const Duration(milliseconds: 1500),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 播放錄音按鈕
  Widget _buildPlayRecordingButton() {
    if (widget.result.recordingPath == null) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: _togglePlayRecording,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _isPlaying ? KawaiiTheme.primaryPink : KawaiiTheme.softPink.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? Icons.stop : Icons.play_arrow,
              color: _isPlaying ? Colors.white : KawaiiTheme.primaryPink,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _isPlaying ? '停止播放' : '播放錄音',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _isPlaying ? Colors.white : KawaiiTheme.primaryPink,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlayRecording() async {
    if (widget.result.recordingPath == null) return;

    if (_isPlaying) {
      await _playerService.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      final success = await _playerService.play(widget.result.recordingPath!);
      if (success) {
        if (mounted) setState(() => _isPlaying = true);
        _playerService.player.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _isPlaying = false);
        });
      }
    }
  }

  /// 回饋區
  Widget _buildFeedbackSection(Color emotionColor) {
    return Column(
      children: [
        // 你覺得像她嗎？
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: emotionColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '你覺得像她嗎？',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: emotionColor,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // 按鈕列
        Row(
          children: [
            // 像她
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
                onPressed: () => _onFeedbackCorrect(),
                icon: const Icon(Icons.favorite, size: 20),
                label: const Text(
                  '像她',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 不太像
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(color: Colors.grey.shade400, width: 1.5),
                ),
                onPressed: () => _showFeedbackOptions(context),
                icon: const Icon(Icons.sentiment_neutral, size: 20),
                label: const Text(
                  '不太像',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // 幫她修正
        TextButton.icon(
          onPressed: () => _showFeedbackOptions(context),
          style: TextButton.styleFrom(
            foregroundColor: KawaiiTheme.primaryPink,
          ),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text(
            '幫她修正',
            style: TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _onFeedbackCorrect() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 12),
            Expanded(child: Text(_catSpeechService.getCorrectFeedback())),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    
    final feedback = UserFeedback.correct();
    widget.onFeedback(feedback);
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
            correctedEmotion: emotion?.name,
            comment: customNote,
            timestamp: DateTime.now(),
          );
          widget.onFeedback(feedback);
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
              backgroundColor: KawaiiTheme.primaryPink,
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
                widget.onFeedback(feedback);
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }
}

/// 反饋選項 BottomSheet
class _FeedbackOptionsSheet extends StatefulWidget {
  final void Function(EmotionType? emotion, bool isCustom, String? customNote) onSelectEmotion;

  const _FeedbackOptionsSheet({required this.onSelectEmotion});

  @override
  State<_FeedbackOptionsSheet> createState() => _FeedbackOptionsSheetState();
}

class _FeedbackOptionsSheetState extends State<_FeedbackOptionsSheet> {
  EmotionType? _selectedEmotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '選擇正確的情緒',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '謝謝你告訴我，我會慢慢學會她的習慣 🐾',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 20),
          
          // 情緒選項
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EmotionType.values.where((e) => e != EmotionType.other).map((emotion) {
              final isSelected = _selectedEmotion == emotion;
              return GestureDetector(
                onTap: () => setState(() => _selectedEmotion = emotion),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Color(emotion.colorValue).withValues(alpha: 0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Color(emotion.colorValue) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emotion.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        emotion.label,
                        style: TextStyle(
                          color: isSelected ? Color(emotion.colorValue) : Colors.black,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
          // 送出按鈕
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: KawaiiTheme.primaryPink,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _selectedEmotion == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onSelectEmotion(_selectedEmotion, false, null);
                    },
              child: const Text(
                '送出',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}
