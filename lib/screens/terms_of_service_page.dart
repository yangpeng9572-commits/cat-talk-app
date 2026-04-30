import 'package:flutter/material.dart';

/// 使用協議與服務條款頁面
/// 
/// v2 修正內容：
/// - 移除錯誤的 Firebase 條款（Firebase 未使用）
/// - 補上聯繫 email
/// - 修正責任上限文字（加「除法律另有規定外」）
/// - 補上資料刪除權說明
/// - 補上 ML Kit 姿勢偵測說明
class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
          '使用協議',
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
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.orange.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Text('📜', style: TextStyle(fontSize: 32)),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '使用協議',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '最後更新：2026 年 4 月（第二版）',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 服務說明
            _buildSection(
              emoji: '📱',
              title: '一、服務說明',
              content: '''喵心語 Cat Talk（以下簡稱「本 App」）是一款貓咪叫聲翻譯與情緒陪伴應用程式。

本 App 會根據貓咪叫聲的音量、音調、長短、節奏等特徵，結合規則引擎，推測貓咪可能想要表達的情緒或需求。

本 App 同時提供「她的小世界」虛擬互動功能、「貓咪動作庫」姿勢參考功能，以及每日情緒報告等個人化服務。

本 App 的翻譯結果僅為參考用途，不構成任何醫療建議、獸醫診斷或專業行為評估。''',

              ), const SizedBox(height: 16),

            // 使用者年齡限制
            _buildSection(
              emoji: '🎂',
              title: '二、使用者年齡限制',
              content: '''本 App 僅限年滿 13 歲的使用者使用。

若您未滿 18 歲，請在父母或監護人的陪同與同意下使用本 App。

父母或監護人應告知未成年使用者如何安全使用本 App，包括錄音功能的正確使用方式。''',

              ), const SizedBox(height: 16),

            // 智慧財產權
            _buildSection(
              emoji: '©️',
              title: '三、智慧財產權',
              content: '''本 App 的名稱「喵心語 Cat Talk」、標誌、所有頁面設計、圖示、按鈕圖案、資料庫結構、程式碼及內容（以下簡稱「智慧財產」），版權與所有權均歸屬本 App 開發團隊（以下簡稱「開發者」）所有。

未經開發者明確書面同意，任何人不得：
• 複製、修改、或散佈本 App 的任何內容
• 使用爬蟲、機器人或其他自動化工具存取本 App
• 去除或竄改本 App 中的版權聲明或水印
• 將本 App 的智慧財產用於任何商業用途

本 App 使用的開源軟體元件，請參閱各元件之授權條款。''',

              ), const SizedBox(height: 16),

            // 使用者責任
            _buildSection(
              emoji: '✅',
              title: '四、使用者責任',
              content: '''使用本 App 時，您同意：

• 遵守當地法律規範使用本 App
• 不將本 App 用於任何非法目的
• 不干擾或嘗試未經授權存取本 App 的任何功能
• 不利用本 App 從事任何傷害動物之行為
• 錄音時請自行確認場所與情況許可
• 對您的貓咪負有完全之照顧與管理責任
• 定期更新 App 至最新版本，以獲得最佳安全性''',

              ), const SizedBox(height: 16),

            // 禁止事項
            _buildSection(
              emoji: '🚫',
              title: '五、使用禁止事項',
              content: '''您不得且不應該：

• 使用本 App 作為虐待動物的工具或藉口
• 將本 App 的翻譯結果作為醫療診斷的唯一依據
• 在未取得他人同意的情況下錄製他人的貓咪叫聲
• 試圖破解、逆向工程、或規避本 App 的安全機制
• 以自動化方式大量註冊帳戶或干擾本 App 正常運作
• 散佈任何含有誹謗、騷擾、威脅、或不實內容的資訊''',

              ), const SizedBox(height: 16),

            // 醫療免責聲明（重要）
            _buildWarningSection(
              emoji: '⚠️',
              title: '六、健康與醫療重要聲明（請務必詳讀）',
              content: '''【高風險條款】

本 App 的翻譯結果：

❌ 不能取代獸醫師的專業診斷
❌ 不能作為判斷貓咪健康問題的唯一依據
❌ 不能用於延誤或代替正規醫療照護

如果您觀察到以下情形，請立即就醫：
• 貓咪食慾不振或完全不進食
• 貓咪出現異常叫聲、嗜睡或攻擊行為
• 貓咪有嘔吐、腹瀉、呼吸困難等症狀
• 貓咪行為突然改變超過 24 小時

本 App 的情緒分析結果是根據統計規律與聲音特徵推測，並非獸醫學或動物行為學的專業判斷。開發者不對翻譯結果的準確性作出任何保證，亦不對用戶因信賴翻譯結果而延誤就醫之情事承擔任何法律責任。''',

              ), const SizedBox(height: 16),

            // 責任限制
            _buildSection(
              emoji: '⚖️',
              title: '七、責任限制',
              content: '''除法律另有規定外，在法律允許的最大範圍內：

【開發者不承擔以下責任】

• 因使用本 App 或無法使用本 App 所造成之任何直接或間接損失
• 本 App 翻譯結果的準確性、完整性、或時效性
• 用戶與其貓咪之間因使用本 App 而產生之任何爭議
• 因 Force Majeure（不可抗力）事件導致本 App 無法正常運作
• 用戶設備、相關軟體、或網路連線問題所造成之服務中斷
• 用戶資料遺失（建議用戶定期備份重要資料）

【最大責任上限】

若開發者因任何法律理論對您負有責任，該責任之總金額不得超過您為本 App 支付之費用（如有），或新台幣 100 元，以兩者中較低者為準。

本條之限制不影響消費者依法享有之權利，亦不適用於因開發者故意或重大過失所致之責任。''',

              ), const SizedBox(height: 16),

            // 第三方服務與 SDK
            _buildSection(
              emoji: '🔗',
              title: '八、第三方服務與 SDK',
              content: '''本 App 使用以下第三方服務協助提供功能：

【Google ML Kit（姿勢偵測）】
用於即時分析人體姿勢，提供「貓咪動作庫」姿勢參考功能。所有姿勢分析均在您的手機本機離線執行，影像資料不會上傳至任何伺服器。Google 的隱私政策適用於此服務。

【作業系統服務】
本 App 需要麥克風權限以錄製貓咪叫聲。您的裝置作業系統的隱私權相關設定不受本隱私政策約束，請參考您的作業系統設定。

開發者不對任何第三方服務的作為或不作為負責。使用第三方服務時，請同時閱讀其各自之服務條款與隱私政策。''',

              ), const SizedBox(height: 16),

            // 資料管理
            _buildSection(
              emoji: '🗑️',
              title: '九、資料管理與您的權利',
              content: '''【您的資料儲存】
本 App 的所有資料（貓咪資料、翻譯歷史、成就記錄等）均儲存在您的手機本機，開發者不會主動上傳或存取您的私人資料。

【資料刪除權】
您可隨時通過以下方式刪除您的資料：
• 在 App 內的各項刪除功能清除記錄
• 解除安裝（刪除）本 App（將一併刪除本機所有相關資料）
• 聯繫開發團隊申請資料刪除（見第十二章聯繫方式）

刪除後資料將無法復原，請謹慎操作。''',

              ), const SizedBox(height: 16),

            // 條款修改
            _buildSection(
              emoji: '🔄',
              title: '十、條款修改',
              content: '''開發者保留隨時修改本使用協議之權利。

修改後的條款將於本 App 更新時生效，並公告於本 App 或官方網站。

重大修改（例如涉及責任限制、隱私權重大變更）將會通過推播通知或 App 內公告提前通知您。

繼續使用本 App 即表示您接受修改後的條款。如您不接受修改後的條款，請停止使用本 App 並刪除本 App。''',

              ), const SizedBox(height: 16),

            // 終止服務
            _buildSection(
              emoji: '🛑',
              title: '十一、服務終止',
              content: '''您可以隨時停止使用本 App 並予以解除安裝。

若發生以下情形，開發者有權未經通知終止或暫停您使用本 App：
• 違反本使用協議之任何條款
• 涉及任何欺騙、違法、或不當行為
• 法院命令或法律要求
• 開發者決定停止提供本 App

本 App 的終止不影響任何在此之前已產生之權利或義務。''',

              ), const SizedBox(height: 16),

            // 適用法律
            _buildSection(
              emoji: '⚖️',
              title: '十二、適用法律與管轄',
              content: '''本使用協議之解釋與適用，應以中華民國（台灣）之法律為準。

因本使用協議所產生之任何爭議，雙方同意以台灣台北地方法院為第一審管轄法院。

但若您為消費者（依《消費者保護法》定義），前述限制應不適用於您依法享有之權利。''',

              ), const SizedBox(height: 16),

            // 聯繫方式
            _buildSection(
              emoji: '💬',
              title: '十三、聯繫方式',
              content: '''如您對本使用協議有任何疑問、建議、或希望提出投訴，請通過以下方式聯繫我們：

• 通過本 App 內的回饋功能提交
• 發送電子郵件至：yangpeng9572@gmail.com

我們會在合理期限內回覆您的來信。

如您為未成年人，請在父母或監護人陪同下與我們聯繫。''',

              ), const SizedBox(height: 40),

            // 底部宣告
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text(
                    '使用本 App 即表示您已閱讀、瞭解並同意遵守上述所有條款。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2026 喵心語 Cat Talk 開發團隊',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
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
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
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
              fontSize: 13.5,
              color: Colors.grey.shade700,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningSection({
    required String emoji,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.red.shade900,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
