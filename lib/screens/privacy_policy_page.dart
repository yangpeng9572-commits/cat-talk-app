import 'package:flutter/material.dart';

/// 隱私政策頁面
class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
        title: const Text(
          '隱私政策',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔒', style: TextStyle(fontSize: 28)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '保護您的隱私',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '我們重視您的資料安全',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 麥克風使用
            _buildSection(
              emoji: '🎤',
              title: '錄音與麥克風使用',
              content: '''喵心語需要使用麥克風來錄下貓咪的叫聲。

當您長按錄音按鈕時，App 會：
• 啟動麥克風收音
• 錄製貓咪叫聲
• 暫時儲存錄音檔案進行分析
• 分析完成後，錄音檔案將被刪除

錄音內容：
• 只用於分析貓咪叫聲特徵
• 不會上傳至任何伺服器
• 不會分享給第三方
• 不會用於任何其他用途''',
            ),

            const SizedBox(height: 20),

            // 貓咪資料
            _buildSection(
              emoji: '🐱',
              title: '貓咪資料',
              content: '''您添加的貓咪資料（名字、性別、年齡、品種）：

• 儲存在您的手機本機
• 用於個人化翻譯參考
• 不會上傳至任何伺服器
• 不會分享給第三方

您可以随时：
• 新增或編輯貓咪資料
• 刪除不想保留的資料''',
            ),

            const SizedBox(height: 20),

            // 翻譯歷史
            _buildSection(
              emoji: '📝',
              title: '翻譯歷史記錄',
              content: '''每次翻譯的結果會保存在手機本機，包括：
• 翻譯時間
• 情緒分析結果
• 您的回饋與修正

您可以：
• 隨時查看歷史記錄
• 刪除單筆記錄
• 清除所有歷史記錄''',
            ),

            const SizedBox(height: 20),

            // 雲端同步說明
            _buildSection(
              emoji: '☁️',
              title: '關於未來雲端同步',
              content: '''目前版本：
• 所有資料僅儲存在您的手機本機

未來如果推出雲端同步功能：
• 我們會事先通知您
• 取得您的明確同意
• 提供資料匯出選項
• 符合當地法規要求''',
            ),

            const SizedBox(height: 20),

            // 安全聲明
            _buildSection(
              emoji: '⚠️',
              title: '重要安全聲明',
              content: '''喵心語的翻譯結果：
• 基於聲音特徵與規律進行的推測
• 僅供日常觀察與參考
• 不能取代專業獸醫診斷

如果您發現：
• 貓咪行為異常
• 貓咪食慾不振
• 貓咪出現不適症狀

請務必諮詢獸醫，勿僅依賴 App 結果做判斷。''',
            ),

            const SizedBox(height: 20),

            // 聯繫我們
            _buildSection(
              emoji: '💬',
              title: '聯繫我們',
              content: '''如果您對隱私政策有任何疑問：
• 可以通過 App 內的回饋功能告訴我們
• 我們會盡快回覆您的問題

最後更新：2026 年 4 月''',
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String emoji,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
