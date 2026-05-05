import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cat.dart';
import '../services/cat_service.dart';
import '../theme/kawaii_theme.dart';
import 'add_cat_page.dart';
import 'edit_cat_page.dart';

class CatsPage extends StatefulWidget {
  const CatsPage({super.key});

  @override
  State<CatsPage> createState() => _CatsPageState();
}

class _CatsPageState extends State<CatsPage> {
  List<Cat> _cats = [];

  // ===== 圖片顯示 Helper =====
  Widget _buildCatAvatar(
    String? avatarPath, {
    double radius = 40,
    double iconSize = 40,
  }) {
    final path = avatarPath;
    final hasValidPath = path != null &&
        path.isNotEmpty &&
        !path.startsWith('content://') &&
        File(path).existsSync();

    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFFFE0B2),
      backgroundImage: hasValidPath ? FileImage(File(path)) : null,
      child: hasValidPath
          ? null
          : Icon(
              Icons.pets,
              color: const Color(0xFFFF8A65),
              size: iconSize,
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadCats();
  }

  Future<void> _loadCats() async {
    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    setState(() {
      _cats = catService.getAllCats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        title: const Text('我的貓咪'),
        backgroundColor: Colors.transparent,
        foregroundColor: KawaiiTheme.textPrimary,
        elevation: 0,
      ),
      body: _cats.isEmpty
          ? _buildEmptyState()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  // 現有貓咪卡片
                  ..._cats.map((cat) => _buildCatCard(cat)),
                  // 添加新貓咪
                  _buildAddCatCard(context),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: KawaiiTheme.softPink.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('🐱', style: TextStyle(fontSize: 60)),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '還沒有新增貓咪',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: KawaiiTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '點擊下方按鈕新增你的第一隻貓咪',
            style: TextStyle(
              fontSize: 14,
              color: KawaiiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildAddCatCard(context),
        ],
      ),
    );
  }

  Widget _buildCatCard(Cat cat) {
    return GestureDetector(
      onTap: () async {
        // 編輯這隻貓咪
        if (!mounted) return;
        final updatedCat = await Navigator.push<Cat?>(
          context,
          MaterialPageRoute(builder: (context) => EditCatPage(cat: cat)),
        );
        if (updatedCat != null) {
          _loadCats(); // 重新載入貓咪列表
          if (!mounted) return;
          setState(() {});
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(KawaiiTheme.radiusLarge),
          boxShadow: KawaiiTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 頭像
            _buildCatAvatar(cat.avatarPath),
            const SizedBox(height: 8),
            // 名字
            Text(
              cat.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            // 品種
            Text(
              cat.breed,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            // 年齡
            Text(
              cat.ageStageLabel,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddCatCard(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        // 添加新貓咪
        if (!mounted) return;
        final newCatId = await Navigator.push<String?>(
          context,
          MaterialPageRoute(builder: (context) => const AddCatPage()),
        );
        if (newCatId != null) {
          _loadCats(); // 重新載入貓咪列表
          if (!mounted) return;
          setState(() {});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange, width: 2, style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 48, color: Colors.orange),
            SizedBox(height: 8),
            Text(
              '新增貓咪',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
