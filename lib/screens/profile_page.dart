import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'achievement_page.dart';
import 'about_page.dart';
import 'privacy_policy_page.dart';
import 'cat_world_page.dart';
import '../theme/kawaii_theme.dart';
import '../widgets/onboarding_overlay.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          // 頂部個人資訊
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: KawaiiTheme.primaryGradient,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // 頭像
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  // 用戶名
                  const Text(
                    '使用者',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'yangpeng9572@gmail.com',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 升級按鈕
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KawaiiTheme.cardBackground,
                      foregroundColor: KawaiiTheme.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // 升級 - 未來功能
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('高級版功能即將推出 🐾'),
                          backgroundColor: KawaiiTheme.primaryPink,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    },
                    child: const Text('她的小世界 Plus'),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // 功能列表
          SliverList(
            delegate: SliverChildListDelegate([
              _buildMenuItem(
                icon: Icons.emoji_events,
                title: '成就',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AchievementPage()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.home,
                title: '她的小世界 🏡',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CatWorldPage()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.replay,
                title: '再看一次新手教程',
                onTap: () async {
                  // 重置新手教學狀態並顯示
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('hasSeenOnboarding', false);
                  if (context.mounted) {
                    Navigator.pop(context); // 返回首頁
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('新手教程已重置，向下滑動即可查看 🐾'),
                        backgroundColor: KawaiiTheme.primaryPink,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },
              ),
              _buildMenuItem(
                icon: Icons.campaign,
                title: '關於喵心語',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.privacy_tip,
                title: '隱私政策',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                  );
                },
              ),
              _buildMenuItem(
                icon: Icons.delete_forever,
                title: '刪除帳號',
                textColor: Colors.red,
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: '退出帳號',
                textColor: KawaiiTheme.coral,
                onTap: () {
                  _showLogoutDialog(context);
                },
              ),
            ]),
          ),

          // 版本資訊
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '版本 1.0.0',
                  style: TextStyle(color: KawaiiTheme.textLight),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.black),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚠️ ', style: TextStyle(fontSize: 24)),
            Text('刪除帳號'),
          ],
        ),
        content: const Text(
          '刪除帳號會清除所有資料，包括：\n\n'
          '• 貓咪資料\n'
          '• 翻譯歷史\n'
          '• 每日報告\n'
          '• 她的小世界收藏\n\n'
          '此操作無法恢復，確定要刪除嗎？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('請透過設定 > 應用程式 > 喵心語 刪除所有資料 🐾'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('確定刪除'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🚪 ', style: TextStyle(fontSize: 24)),
            Text('退出帳號'),
          ],
        ),
        content: const Text(
          '確定要退出登入嗎？\n\n退出後需要重新登入才能使用喵心語。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: KawaiiTheme.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('退出功能即將開放 🐾'),
                  backgroundColor: KawaiiTheme.primaryPink,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('確定退出'),
          ),
        ],
      ),
    );
  }
}
