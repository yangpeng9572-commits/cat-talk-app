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


            // 您的權利
            _buildSection(
              emoji: '👤',
              title: '您的權利',
              content: '''根據《個人資料保護法》（中華民國）或其他適用法律，您享有以下權利：

【查閱權】
您有權隨時查閱本 App 儲存的您的個人資料與貓咪資料。

【更正權】
您有權要求更正不正確的個人資料。

【刪除權】
您有權要求刪除您的帳戶與所有相關資料。
刪除後，所有資料將從我們的系統中永久移除。

【資料可攜權】
您有權要求輸出您的資料副本。

【如何行使權利】
請通過 App 內的回饋功能提交您的請求。
我們會在 30 天內處理您的請求。''',
            ),

            const SizedBox(height: 20),

            // 第三方 SDK 說明
            _buildSection(
              emoji: '🔗',
              title: '第三方服務說明',
              content: '''本 App 使用以下第三方服務：

【Google ML Kit（姿勢偵測）】
用於姿勢參考功能。
隱私政策：https://policies.google.com/privacy

【Firebase（Google Analytics）】
用於匿名使用統計與崩溃報告。
隱私政策：https://firebase.google.com/support/privacy

【作業系統麥克風權限】
錄音功能需要您的主動授權。
作業系統的隱私設定不受本政策約束，請參考您的裝置設定。''',
            ),

            const SizedBox(height: 20),


            const SizedBox(height: 20),

            // 資料保存期限
            _buildSection(
              emoji: "📅",
              title: "資料保存期限",
              content: """我們將在您使用本 App 期間保留您的個人資料與貓咪資料。

【保存期限】
• 您的使用者帳戶資料：直到您主動刪除帳戶
• 翻譯歷史記錄：保留 7 年（基於法令遵循需求）
• 使用統計資料（匿名）：保留 2 年
• 錯誤報告與崩潰 logs：保留 90 天

【刪除後保留】
當您刪除帳戶後，我們會在 30 天內從系統中永久刪除您的所有個人資料。
部分資料可能在刪除後最多保留 90 天，這是作業系統備份機制的正常現象。

【例外情況】
若適用的法律、法規或法律程序要求我們保存更長時間的資料，我們會在必要範圍內保留。""",
            ),

            const SizedBox(height: 20),

            // 未成年資料處理
            _buildSection(
              emoji: "👶",
              title: "未成年使用者資料",
              content: """本 App 僅限 13 歲以上使用者使用。

【13 歲以下兒童】
我們不會故意收集 13 歲以下兒童的個人資料。若您發現有 13 歲以下兒童使用本 App，請協助取得其父母或監護人的同意。

【13 至 18 歲未成年】
若您為 13 至 18 歲的未成年人，請在父母或監護人陪同下使用本 App，並了解這些隱私條款。

【父母/監護人權利】
作為父母或監護人，您有權：
• 查看我們收集的未成年人的資料
• 要求刪除未成年人的資料
• 拒絕進一步收集或使用未成年人的資料

如需行使上述權利，請通過 App 內回饋功能聯繫我們。""",
            ),

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
            color: Colors.black.withOpacity(0.05),
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
