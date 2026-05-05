import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';
import '../models/translation_result.dart';
import '../services/bond_service.dart';
import '../services/translation_history_service.dart';
import '../services/share_card_service.dart';
import '../services/meow_speech_service.dart';
import '../widgets/kawaii_button.dart';
import '../services/top_toast_service.dart';

/// 貓咪小日常互動模式
class HomeInteractionPage extends StatefulWidget {
  final Cat cat;

  const HomeInteractionPage({super.key, required this.cat});

  @override
  State<HomeInteractionPage> createState() => _HomeInteractionPageState();
}

class _HomeInteractionPageState extends State<HomeInteractionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;

  // 互動狀態
  String _currentState = 'idle'; // idle, hungry, playful, affectionate, anxious, greeting
  String _feedbackMessage = '';
  bool _showFeedback = false;

  // 今日統計
  int _todayInteractions = 0;
  int _todayLikeTests = 0;
  int _correctInteractions = 0;
  DateTime _lastInteractionDate = DateTime.now();

  // 喜歡度測試
  bool _showLikeTest = false;
  int _currentLikeScore = 0;

  // 人話轉喵聲
  bool _showTextToMeow = false;
  final TextEditingController _textController = TextEditingController();
  final MeowSpeechService _speechService = MeowSpeechService();

  // 特殊驚喜
  bool _showSurprise = false;
  String _surpriseMessage = '';

  // 分享卡
  String? _shareCardPath;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);

    _loadTodayStats();
    _updateCatState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTodayStats() async {
    // 從 local storage 讀取今日統計
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final today = _todayKey();
    final stats = prefs.getString(today);
    if (stats != null) {
      final parts = stats.split(',');
      setState(() {
        _todayInteractions = int.parse(parts[0]);
        _todayLikeTests = int.parse(parts[1]);
        _correctInteractions = int.parse(parts[2]);
      });
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return 'interaction_${widget.cat.id}_${now.year}${now.month}${now.day}';
  }

  Future<void> _saveTodayStats() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    await prefs.setString(today, '$_todayInteractions,$_todayLikeTests,$_correctInteractions');
  }

  void _showFeedbackMessage(String msg) {
    TopToastService.show(context, message: msg, backgroundColor: const Color(0xFFFF8FAB));
  }

  Future<void> _updateCatState() async {
    try {
      // 取得今日 dominant emotion
      final history = await TranslationHistoryService().getByCatIdWithinDays(widget.cat.id, 1);
      if (history.isEmpty) {
        if (mounted) setState(() => _currentState = 'idle');
        return;
      }

      // 計算今日情緒分佈
      final emotionCount = <EmotionType, int>{};
      for (final h in history) {
        emotionCount[h.emotionType] = (emotionCount[h.emotionType] ?? 0) + 1;
      }

      if (emotionCount.isEmpty) {
        if (mounted) setState(() => _currentState = 'idle');
        return;
      }

      // 找 dominant emotion
      EmotionType? dominant;
      int maxCount = 0;
      emotionCount.forEach((emotion, count) {
        if (count > maxCount) {
          maxCount = count;
          dominant = emotion;
        }
      });

      if (mounted) setState(() {
        _currentState = _emotionToState(dominant);
      });
    } catch (e) {
      setState(() => _currentState = 'idle');
    }
  }

  String _emotionToState(EmotionType? emotion) {
    switch (emotion) {
      case EmotionType.hungry:
        return 'hungry';
      case EmotionType.playful:
        return 'playful';
      case EmotionType.affectionate:
        return 'affectionate';
      case EmotionType.anxious:
        return 'anxious';
      case EmotionType.greeting:
        return 'greeting';
      default:
        return 'idle';
    }
  }

  Future<void> _doInteraction(String type) async {
    if (_todayInteractions >= 5) {
      _showFeedbackMessage('今天已經互動够多了 🐾');
      return;
    }

    // 檢查是否為正確的互動
    final isCorrect = _isCorrectInteraction(type);

    setState(() {
      _todayInteractions++;
      if (isCorrect) _correctInteractions++;
      _showFeedback = true;
      if (isCorrect) {
        _feedbackMessage = _getFeedbackMessage(type);
      } else {
        _feedbackMessage = _getNeutralFeedbackMessage(type);
      }
    });

    // 10% 機率特殊驚喜
    if (Random().nextDouble() < 0.1) {
      setState(() {
        _showSurprise = true;
        _surpriseMessage = '今天她特別黏人 💕';
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSurprise = false);
      });
    }

    // +bond（每天最多 +3）
    if (isCorrect) {
      await BondService().addBond(widget.cat.id, BondService.eventActionTap);
      if (!mounted) return;
    }

    await _saveTodayStats();

    // 3秒後隱藏回饋
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showFeedback = false);
    });
  }

  bool _isCorrectInteraction(String type) {
    switch (_currentState) {
      case 'hungry':
        return type == 'feed';
      case 'playful':
        return type == 'play';
      case 'affectionate':
        return type == 'pet';
      case 'anxious':
        return type == 'pet';
      case 'greeting':
        return type == 'talk';
      default:
        return true;
    }
  }

  String _getFeedbackMessage(String type) {
    final messages = {
      'feed': ['她吃得很满足 🍽️', '她對你準備的食物很滿意 💗'],
      'play': ['她玩得好開心 🎾', '她今天特別有活力 🎉'],
      'pet': ['她好像安心了一點 💕', '她發出滿足的呼嚕聲 😻'],
      'talk': ['她豎起耳朵認真聽 🐱', '她用眼神回應了你 💗'],
    };
    final list = messages[type] ?? ['她很開心 💕'];
    return list[DateTime.now().second % list.length];
  }

  String _getNeutralFeedbackMessage(String type) {
    final messages = {
      'feed': ['她聞了一下 🐾', '她還不太餓的样子 🤔'],
      'play': ['她懶洋洋的 🐱', '她對這個不感興趣 😅'],
      'pet': ['她有點不自在 🤔', '她需要一點時間 🐾'],
      'talk': ['她歪了歪頭 🐱', '她在想什麼呢 🤔'],
    };
    final list = messages[type] ?? ['她有在聽 🐾'];
    return list[DateTime.now().second % list.length];
  }

  Future<void> _doLikeTest() async {
    if (_todayLikeTests >= 1) {
      _showFeedbackMessage('明天再看看她有多喜歡你吧 🐾');
      return;
    }

    final bond = await BondService().getBond(widget.cat.id);
    if (!mounted) return;
    final bondScore = bond.bondScore;

    final score = bondScore + _todayInteractions * 3 + _correctInteractions * 5;
    final clampedScore = score.clamp(0, 100);

    if (!mounted) return;
    setState(() {
      _todayLikeTests++;
      _currentLikeScore = clampedScore;
      _showLikeTest = true;
    });

    await _saveTodayStats();
  }

  Future<void> _shareLikeResult() async {
    final result = await ShareCardService().generatePersonalityCard(
      catName: widget.cat.name,
      personalityType: '$_currentLikeScore%',
      personalityDescription: '今天我陪她玩了一下',
      topEmotion: EmotionType.affectionate,
      bondScore: _currentLikeScore,
    );

    if (result != null && mounted) {
      setState(() => _shareCardPath = result);
      TopToastService.success(context, message: '分享卡已生成 💕');
    }
  }

  Future<void> _doTextToMeow() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showFeedbackMessage('請輸入想說的話 🐱');
      return;
    }

    setState(() => _showTextToMeow = true);
    _textController.clear();

    await _speechService.speakText(text);
    if (!mounted) return;
    setState(() => _showTextToMeow = false);
  }

  void _closeTextToMeow() {
    _speechService.stop();
    setState(() => _showTextToMeow = false);
  }

  String _getCatEmoji() {
    switch (_currentState) {
      case 'hungry':
        return '🐱‍👀';
      case 'playful':
        return '🐱‍🎾';
      case 'affectionate':
        return '😻';
      case 'anxious':
        return '😿';
      case 'greeting':
        return '🐱';
      default:
        return '🐱';
    }
  }

  String _getCatAnimation() {
    switch (_currentState) {
      case 'hungry':
        return '看向碗';
      case 'playful':
        return '跳動';
      case 'affectionate':
        return '靠近';
      case 'anxious':
        return '躲角落';
      case 'greeting':
        return '看你';
      default:
        return '休息中';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0F5),
      body: Stack(
        children: [
          // 溫馨房間背景
          _buildRoomBackground(),

          // 頂部標題
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9B8B8B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.cat.name}的小日常',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // 中央貓咪
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, -_bounceAnimation.value),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getCatEmoji(),
                          style: const TextStyle(fontSize: 100),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCatAnimation(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF9B8B8B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 特殊驚喜
          if (_showSurprise)
            Positioned(
              top: 150,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8FAB),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Text(
                    _surpriseMessage,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // 回饋訊息
          if (_showFeedback)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    _feedbackMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                ),
              ),
            ),

          // 底部互動區
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 今日統計
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip('今日互動', '$_todayInteractions/5'),
                      const SizedBox(width: 16),
                      _buildStatChip('喜歡測試', '$_todayLikeTests/1'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 互動按鈕
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInteractionButton('🍽', '餵她', () => _doInteraction('feed')),
                      _buildInteractionButton('🎾', '陪她玩', () => _doInteraction('play')),
                      _buildInteractionButton('💗', '摸摸她', () => _doInteraction('pet')),
                      _buildInteractionButton('🗣', '跟她說話', () => _doInteraction('talk')),
                      _buildInteractionButton('🔊', '說給她聽', () => _doTextToMeow()),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 喜歡度測試
                  ElevatedButton(
                    onPressed: _doLikeTest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8FAB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('💗 看看她有多喜歡你'),
                  ),
                ],
              ),
            ),
          ),

          // 人話轉喵聲彈窗
          if (_showTextToMeow)
            _buildTextToMeowOverlay(),
        ],
      ),
    );
  }

  Widget _buildRoomBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF8E7),
            Color(0xFFFFE4E1),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 窗戶
          Positioned(
            top: 80,
            right: 30,
            child: Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Column(
                children: [
                  Container(height: 4, color: Colors.white),
                  const Expanded(child: SizedBox()),
                  Container(height: 4, color: Colors.white),
                ],
              ),
            ),
          ),
          // 沙發
          Positioned(
            bottom: 250,
            left: 20,
            child: Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withOpacity(0.6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9B8B8B)),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFF8FAB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton(String emoji, String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8FAB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFF8FAB).withOpacity(0.3)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9B8B8B)),
          ),
        ],
      ),
    );
  }

  String _getLikeMessage(int score) {
    if (score >= 80) return '她今天更喜歡你一點 💗';
    if (score >= 60) return '她對你有好感 🙂';
    if (score >= 40) return '她在觀察你 🤔';
    return '她需要多一點時間 🐾';
  }

  // ===== 人話轉喵聲 =====

  Widget _buildTextToMeowOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                '說給 ${widget.cat.name} 聽',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4B4B),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '輸入你想說的話，會轉成貓咪語播放',
                style: TextStyle(fontSize: 13, color: Color(0xFF9B8B8B)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: '例如：肚子餓了嗎？要喝水嗎？',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF8FAB), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: _closeTextToMeow,
                    child: const Text('取消'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _doTextToMeow,
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text('播放 🎵'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8FAB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
