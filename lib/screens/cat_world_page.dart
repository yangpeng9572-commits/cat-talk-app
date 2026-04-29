import 'package:flutter/material.dart';

/// 她的小世界 🏡 - 貓咪房間佈置系統（第一階段：占位頁）
class CatWorldPage extends StatelessWidget {
  const CatWorldPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F5),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF9B8B8B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '她的小世界 🏡',
          style: TextStyle(
            color: Color(0xFF6B4B4B),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 頂部溫馨插圖區
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E1).withAlpha(180),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🏡',
                  style: TextStyle(fontSize: 80),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 主標題
            const Text(
              '她的小世界\n正在慢慢準備中 🐾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6B4B4B),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 16),

            // 副標
            const Text(
              '之後你可以在這裡幫她佈置房間、\n換小配件、收藏可愛回憶。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFF9B8B8B),
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),

            // 即將推出區塊預告
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🌟 未來可以在這裡做這些事',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4B4B),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 預告功能列表
                  _buildFeatureItem('🛋️', '房間佈置', '幫她選擇舒適的角落'),
                  _buildFeatureItem('🪑', '家具小物', '小床墊、跳台、抓板'),
                  _buildFeatureItem('🎀', '貓咪配件', '項圈、蝴蝶結、小領結'),
                  _buildFeatureItem('✨', '情緒動畫', '開心時的特效動畫'),
                  _buildFeatureItem('🖼️', '分享卡模板', '可愛的曬貓卡樣式'),
                  _buildFeatureItem('🌸', '季節限定', '節日特別主題佈置'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 溫馨提醒
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB6C1).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFB6C1).withAlpha(77),
                ),
              ),
              child: Row(
                children: [
                  const Text(
                    '💝',
                    style: TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '陪伴越多，她的小世界也會越溫暖',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B4B4B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '功能陸續推出中，敬請期待',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 返回按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8FAB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '先回去陪她 🐱',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B4B4B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9B8B8B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
