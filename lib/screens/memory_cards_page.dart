import 'package:flutter/material.dart';
import '../services/memory_card_service.dart';
import '../theme/kawaii_theme.dart';

/// 回憶收藏頁面
class MemoryCardsPage extends StatefulWidget {
  final String catId;

  const MemoryCardsPage({super.key, required this.catId});

  @override
  State<MemoryCardsPage> createState() => _MemoryCardsPageState();
}

class _MemoryCardsPageState extends State<MemoryCardsPage> {
  final MemoryCardService _memoryCardService = MemoryCardService();
  List<MemoryCard> _cards = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final cards = await _memoryCardService.getMemoryCards(widget.catId);
    setState(() {
      _cards = cards;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unlockedCount = _cards.where((c) => c.isUnlocked).length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9B8B8B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              '💎 回憶收藏',
              style: TextStyle(
                color: Color(0xFF6B4B4B),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Text(
              '收藏與她的重要時刻',
              style: TextStyle(
                color: Color(0xFF9B8B8B),
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: KawaiiTheme.primaryPink))
          : Column(
              children: [
                // 進度提示
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(05 == "" ? 0.05 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('💎', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(
                        '已收藏 $unlockedCount / ${_cards.length}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B4B4B),
                        ),
                      ),
                    ],
                  ),
                ),
                // 卡片列表
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _cards.length,
                    itemBuilder: (ctx, index) => _buildCard(_cards[index]),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(MemoryCard card) {
    final isUnlocked = card.isUnlocked;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
        border: isUnlocked
            ? Border.all(
                color: _getRarityColor(card.rarity).withOpacity(3 == "" ? 0.3 : 0.3),
                width: 1.5,
              )
            : null,
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: _getRarityColor(card.rarity).withOpacity(1 == "" ? 0.1 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // 圖標
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? _getRarityColor(card.rarity).withOpacity(15 == "" ? 0.15 : 0.15)
                  : const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isUnlocked
                  ? Text(card.icon, style: const TextStyle(fontSize: 24))
                  : const Icon(Icons.lock_outline, color: Color(0xFF9B8B8B), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          // 內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      card.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isUnlocked ? const Color(0xFF6B4B4B) : const Color(0xFF9B8B8B),
                      ),
                    ),
                    if (card.rarity != MemoryCardRarity.common) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getRarityColor(card.rarity).withOpacity(15 == "" ? 0.15 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          card.rarity == MemoryCardRarity.rare ? '稀有' : '史詩',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _getRarityColor(card.rarity),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isUnlocked ? card.description : '？？？',
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnlocked ? const Color(0xFF9B8B8B) : const Color(0xFFBBBBBB),
                  ),
                ),
                if (isUnlocked && card.unlockedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '解鎖於 ${_formatDate(card.unlockedAt!)}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFFBBBBBB),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(MemoryCardRarity rarity) {
    switch (rarity) {
      case MemoryCardRarity.common:
        return const Color(0xFF9B8B8B);
      case MemoryCardRarity.rare:
        return const Color(0xFF8B5CF6);
      case MemoryCardRarity.epic:
        return const Color(0xFFFF8FAB);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}';
  }
}