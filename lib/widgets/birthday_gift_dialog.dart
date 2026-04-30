import 'package:flutter/material.dart';
import '../models/cat.dart';
import '../services/cat_birthday_service.dart';

/// 生日禮物建議 Dialog
class BirthdayGiftDialog extends StatelessWidget {
  final CatBirthdayService _birthdayService = CatBirthdayService();

  BirthdayGiftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final gifts = _birthdayService.getGiftSuggestions(
      Cat(id: '', name: ''), // 空貓咪只是為了取得禮物列表
    );

    // 按分類分組
    final groupedGifts = <String, List<GiftSuggestion>>{};
    for (final gift in gifts) {
      groupedGifts.putIfAbsent(gift.category, () => []).add(gift);
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Row(
              children: [
                const Text(
                  '🎁',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '給她的小驚喜 🎁',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 文案
            const Text(
              '你可以挑一個適合她的小驚喜，不一定要昂貴，陪伴才是最好的禮物。',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF9B8B8B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // 分類禮物列表
            ...groupedGifts.entries.map((entry) {
              return _buildCategorySection(entry.key, entry.value);
            }),

            const SizedBox(height: 20),

            // 關閉按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8FAB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '關閉',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<GiftSuggestion> gifts) {
    String emoji;
    switch (category) {
      case '玩具':
        emoji = '🎾';
        break;
      case '食物':
        emoji = '🍽';
        break;
      case '舒適':
        emoji = '🛏';
        break;
      case '空間':
        emoji = '🏡';
        break;
      case '可愛':
        emoji = '🎀';
        break;
      default:
        emoji = '🎁';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 分類標題
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4B4B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 分類內的禮物（使用 Wrap 而非 GridView，保持靈活性）
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: gifts.map((gift) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFE4E1),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(gift.emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(
                      gift.name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B4B4B),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// 顯示生日禮物 Dialog
void showBirthdayGiftDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => BirthdayGiftDialog(),
  );
}
