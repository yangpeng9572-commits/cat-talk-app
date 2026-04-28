import 'package:flutter/material.dart';
import '../models/cat.dart';
import 'add_cat_page.dart';

class CatsPage extends StatelessWidget {
  const CatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cats = Cat.getDemoCats();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('貓咪'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // 自定義語言
            },
            child: const Text(
              '自定義語言',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            // 現有貓咪卡片
            ...cats.map((cat) => _buildCatCard(cat)),
            // 添加新貓咪
            _buildAddCatCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCatCard(Cat cat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 頭像
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.orange.shade100,
            child: const Icon(Icons.pets, size: 40, color: Colors.orange),
          ),
          const SizedBox(height: 12),
          // 名字
          Text(
            cat.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
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
    );
  }

  Widget _buildAddCatCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // 添加新貓咪
        _showAddCatDialog(context);
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
              '添加貓咪簡介',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCatDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddCatPage()),
    );
  }
}
