import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('記錄'),
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 插圖
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Text(
                '😺',
                style: TextStyle(fontSize: 60),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            // 說明文字
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                '您可以收聽舊的喵喵聲或將它們下載到您的設備。要開始使用歷史記錄或訪問您的存檔翻譯，請升級。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 32),
            // 升級按鈕
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                // 升級
              },
              child: const Text(
                '取得高級版',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
