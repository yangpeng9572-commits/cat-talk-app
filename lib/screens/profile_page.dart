import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 頂部個人資訊
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B4513), Color(0xFFD2691E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      // 升級
                    },
                    child: const Text('升級到高級版'),
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
                icon: Icons.lock,
                title: '修改密碼',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.replay,
                title: '再看一次新手教程',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.home,
                title: '貓咪空間設定',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.campaign,
                title: '在 Cat Talk 上做廣告',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.privacy_tip,
                title: '個人隱私保護政策',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.delete_forever,
                title: '刪除帳號',
                onTap: () {},
              ),
              _buildMenuItem(
                icon: Icons.logout,
                title: '退出帳號',
                textColor: Colors.red,
                onTap: () {},
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
                  style: TextStyle(color: Colors.grey.shade500),
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
}
