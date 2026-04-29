import 'package:flutter/material.dart';
import '../models/cat_pose.dart';
import '../theme/kawaii_theme.dart';

/// 姿勢辨識 / 貓咪動作庫頁面
/// 提供完整的貓咪姿勢庫，讓用戶瀏覽、搜尋、選擇姿勢
/// 並根據選擇提供情緒解讀和互動建議
class PoseRecognitionPage extends StatefulWidget {
  const PoseRecognitionPage({super.key});

  @override
  State<PoseRecognitionPage> createState() => _PoseRecognitionPageState();
}

class _PoseRecognitionPageState extends State<PoseRecognitionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<CatPose> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: CatPoseLibrary.categories.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String keyword) {
    setState(() {
      if (keyword.isEmpty) {
        _isSearching = false;
        _searchResults = [];
      } else {
        _isSearching = true;
        _searchResults = CatPoseLibrary.search(keyword);
      }
    });
  }

  void _showPoseDetail(CatPose pose) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PoseDetailSheet(pose: pose),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: KawaiiTheme.primaryPink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '🐱 貓咪肢體語言',
          style: TextStyle(
            color: KawaiiTheme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: KawaiiTheme.primaryPink,
          unselectedLabelColor: KawaiiTheme.textSecondary,
          indicatorColor: KawaiiTheme.primaryPink,
          tabs: CatPoseLibrary.categories.map((cat) {
            return Tab(text: '${cat.emoji} ${cat.label}');
          }).toList(),
        ),
      ),
      body: Column(
        children: [
          // 搜尋列
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: '搜尋姿勢...',
                prefixIcon: const Icon(Icons.search, color: KawaiiTheme.primaryPink),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: KawaiiTheme.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // 內容
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildCategoryTabs(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: KawaiiTheme.softPink.withOpacity(5 == "" ? 0.5 : 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔍', style: TextStyle(fontSize: 50)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '找不到「${_searchController.text}」的姿勢',
              style: const TextStyle(
                fontSize: 16,
                color: KawaiiTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '試試其他關鍵詞，例如：睡、玩、吃',
              style: TextStyle(
                fontSize: 14,
                color: KawaiiTheme.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pose = _searchResults[index];
        return _PoseCard(pose: pose, onTap: () => _showPoseDetail(pose));
      },
    );
  }

  Widget _buildCategoryTabs() {
    return TabBarView(
      controller: _tabController,
      children: CatPoseLibrary.categories.map((category) {
        final poses = CatPoseLibrary.getByCategory(category);
        return _buildPoseGrid(poses);
      }).toList(),
    );
  }

  Widget _buildPoseGrid(List<CatPose> poses) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.9,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: poses.length,
      itemBuilder: (context, index) {
        final pose = poses[index];
        return _PoseCard(pose: pose, onTap: () => _showPoseDetail(pose));
      },
    );
  }
}

/// 姿勢卡片 Widget
class _PoseCard extends StatelessWidget {
  final CatPose pose;
  final VoidCallback onTap;

  const _PoseCard({required this.pose, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: KawaiiTheme.softPink.withOpacity(3 == "" ? 0.3 : 0.3),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(pose.emoji, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 12),
            // 名稱
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                pose.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: KawaiiTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // 情緒標籤
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: KawaiiTheme.primaryPink.withOpacity(1 == "" ? 0.1 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                pose.mood,
                style: const TextStyle(
                  fontSize: 11,
                  color: KawaiiTheme.primaryPink,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 姿勢詳細資訊 Bottom Sheet
class _PoseDetailSheet extends StatelessWidget {
  final CatPose pose;

  const _PoseDetailSheet({required this.pose});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 拖動條
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji + 名稱
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: KawaiiTheme.softPink.withOpacity(5 == "" ? 0.5 : 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(pose.emoji, style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pose.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: KawaiiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: KawaiiTheme.primaryPink.withOpacity(1 == "" ? 0.1 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pose.mood,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: KawaiiTheme.primaryPink,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 姿勢描述
                  _buildSection(
                    '📝 姿勢描述',
                    pose.description,
                  ),
                  const SizedBox(height: 20),

                  // 情緒分析
                  _buildSection(
                    '💡 情緒解讀',
                    pose.emotionalInsight,
                  ),
                  const SizedBox(height: 20),

                  // 互動建議
                  _buildSection(
                    '🎯 互動建議',
                    pose.advice,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 24),

                  // 關閉按鈕
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
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        '我知道了',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? KawaiiTheme.primaryPink : KawaiiTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHighlight
                ? KawaiiTheme.primaryPink.withOpacity(08 == "" ? 0.08 : 0.08)
                : KawaiiTheme.background,
            borderRadius: BorderRadius.circular(12),
            border: isHighlight
                ? Border.all(color: KawaiiTheme.primaryPink.withOpacity(2 == "" ? 0.2 : 0.2))
                : null,
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: isHighlight ? KawaiiTheme.textPrimary : KawaiiTheme.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
