import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_page.dart';
import 'screens/cats_page.dart';
import 'screens/history_page.dart';
import 'screens/profile_page.dart';
import 'theme/kawaii_theme.dart';
import 'services/push_notification_service.dart';

/// Debug Tools 開關：flutter run --dart-define=ENABLE_DEBUG_TOOLS=true
/// release 模式下此值為 false（kDebugMode 為 false）
const bool kEnableDebugTools =
    bool.fromEnvironment('ENABLE_DEBUG_TOOLS', defaultValue: false);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 設定系統 UI 樣式
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  
  runApp(const CatTalkApp());
}

class CatTalkApp extends StatelessWidget {
  const CatTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '喵心語',
      debugShowCheckedModeBanner: false,
      theme: KawaiiTheme.themeData,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _homePageKey = GlobalKey<HomePageState>();
  int _currentIndex = 0;

  // callback 供 ProfilePage 使用：切回首頁並重播 onboarding
  void _handleReplayOnboarding() {
    // 切回首頁 tab
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    // 等下一幀再通知 HomePage 顯示 onboarding（確保 IndexedStack 已切換完成）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _homePageKey.currentState?.replayOnboarding();
    });
  }

  late final List<Widget> _pages = [
    HomePage(key: _homePageKey),
    const CatsPage(),
    const HistoryPage(),
    ProfilePage(onReplayOnboarding: _handleReplayOnboarding),
  ];

  @override
  void initState() {
    super.initState();
    // 檢查生日推播提醒
    _checkBirthdayReminders();
  }

  Future<void> _checkBirthdayReminders() async {
    final pushService = PushNotificationService();
    await pushService.checkBirthdayReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: KawaiiTheme.cardBackground,
          boxShadow: [
            BoxShadow(
              color: KawaiiTheme.primaryPink.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: KawaiiTheme.cardBackground,
            selectedItemColor: KawaiiTheme.primaryPink,
            unselectedItemColor: KawaiiTheme.textLight,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 12,
            ),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.pets_outlined),
                activeIcon: _PawIcon(),
                label: '翻譯',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.cruelty_free_outlined),
                activeIcon: Icon(Icons.cruelty_free, size: 28),
                label: '貓咪',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                activeIcon: Icon(Icons.history, size: 28),
                label: '記錄',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, size: 28),
                label: '簡介',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 自定義可愛爪子 icon
class _PawIcon extends StatelessWidget {
  const _PawIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: KawaiiTheme.primaryPink.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.pets,
        size: 22,
        color: KawaiiTheme.primaryPink,
      ),
    );
  }
}
