import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/kawaii_theme.dart';
import '../services/cat_service.dart';
import 'debug_cat_service.dart';
import 'debug_test_models.dart';

/// Debug 驗收工具頁
/// 第一段：空白殼
/// 第二段：D1 新增測試貓 + D5 清除測試資料
class DebugVerificationScreen extends StatefulWidget {
  const DebugVerificationScreen({super.key});

  @override
  State<DebugVerificationScreen> createState() =>
      _DebugVerificationScreenState();
}

class _DebugVerificationScreenState extends State<DebugVerificationScreen> {
  /// 測試結果列表
  final List<DebugTestResult> _results = [];

  /// 測試是否執行中
  bool _isRunning = false;

  /// DebugCatService（懶初始化）
  DebugCatService? _debugCatService;

  /// 初始化 service
  Future<void> _ensureService() async {
    if (_debugCatService != null) return;
    final prefs = await SharedPreferences.getInstance();
    final catService = CatService(prefs);
    _debugCatService = DebugCatService(catService);
  }

  /// 執行單一測試並更新結果
  Future<void> _runTest(String name, Future<DebugTestResult> Function() testFn) async {
    setState(() => _isRunning = true);

    try {
      final result = await testFn();
      setState(() {
        _results.insert(0, result);
        _isRunning = false;
      });
    } catch (e) {
      setState(() {
        _results.insert(0, DebugTestResult(
          name: name,
          passed: false,
          message: '例外錯誤: ${e.toString()}',
          durationMs: 0,
          createdAt: DateTime.now(),
        ));
        _isRunning = false;
      });
    }
  }

  /// D1: 新增測試貓
  Future<DebugTestResult> _testAddDebugCat() async {
    final stopwatch = Stopwatch()..start();
    await _ensureService();

    final before = _debugCatService!.getDebugCatCount();
    await _debugCatService!.addDebugCat();
    final after = _debugCatService!.getDebugCatCount();

    stopwatch.stop();

    if (after == before + 1) {
      return DebugTestResult(
        name: 'D1: 新增測試貓',
        passed: true,
        message: '新增成功，數量 $before → $after',
        durationMs: stopwatch.elapsedMilliseconds,
        createdAt: DateTime.now(),
      );
    } else {
      return DebugTestResult(
        name: 'D1: 新增測試貓',
        passed: false,
        message: '數量未增加，預期 ${before + 1}，實際 $after',
        durationMs: stopwatch.elapsedMilliseconds,
        createdAt: DateTime.now(),
      );
    }
  }

  /// D5: 清除測試資料
  Future<DebugTestResult> _testClearDebugCats() async {
    final stopwatch = Stopwatch()..start();
    await _ensureService();

    final before = _debugCatService!.getDebugCatCount();
    final deleted = await _debugCatService!.clearDebugCats();
    final after = _debugCatService!.getDebugCatCount();

    stopwatch.stop();

    if (deleted > 0 && after == 0) {
      return DebugTestResult(
        name: 'D5: 清除測試資料',
        passed: true,
        message: '清除成功，刪除 $deleted 筆，目前 debug 貓: $after',
        durationMs: stopwatch.elapsedMilliseconds,
        createdAt: DateTime.now(),
      );
    } else if (deleted == 0) {
      return DebugTestResult(
        name: 'D5: 清除測試資料',
        passed: true,
        message: '無測試資料需清除',
        durationMs: stopwatch.elapsedMilliseconds,
        createdAt: DateTime.now(),
      );
    } else {
      return DebugTestResult(
        name: 'D5: 清除測試資料',
        passed: false,
        message: '清除失敗，刪除 $deleted 筆，仍有 $after 筆',
        durationMs: stopwatch.elapsedMilliseconds,
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KawaiiTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        title: const Text('Debug 驗收工具'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清除結果',
            onPressed: () => setState(() => _results.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // 測試按鈕區
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _TestButton(
                    label: 'D1 新增測試貓',
                    icon: Icons.add_circle_outline,
                    isRunning: _isRunning,
                    onPressed: () => _runTest('D1: 新增測試貓', _testAddDebugCat),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TestButton(
                    label: 'D5 清除測試資料',
                    icon: Icons.cleaning_services_outlined,
                    isRunning: _isRunning,
                    onPressed: () => _runTest('D5: 清除測試資料', _testClearDebugCats),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 結果列表
          Expanded(
            child: _results.isEmpty
                ? const Center(
                    child: Text(
                      '點擊上方按鈕執行測試',
                      style: TextStyle(color: KawaiiTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final r = _results[index];
                      return _ResultCard(result: r);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// 測試按鈕
class _TestButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isRunning;
  final VoidCallback onPressed;

  const _TestButton({
    required this.label,
    required this.icon,
    required this.isRunning,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isRunning ? null : onPressed,
      icon: isRunning
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// 測試結果卡片
class _ResultCard extends StatelessWidget {
  final DebugTestResult result;

  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: result.passed ? Colors.green : Colors.red,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  result.passed ? Icons.check_circle : Icons.cancel,
                  color: result.passed ? Colors.green : Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Text(
                  result.passed ? 'PASS' : 'FAIL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: result.passed ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: KawaiiTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  '${result.durationMs}ms',
                  style: TextStyle(
                    fontSize: 12,
                    color: KawaiiTheme.textLight,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: KawaiiTheme.textLight,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(result.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: KawaiiTheme.textLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}
