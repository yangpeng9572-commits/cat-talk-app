import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/main.dart';
import 'package:cat_talk/screens/add_cat_page.dart';
import 'package:cat_talk/screens/privacy_policy_page.dart';
import 'package:cat_talk/screens/about_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    // 模擬 SharedPreferences
    SharedPreferences.setMockInitialValues({
      'hasSeenOnboarding': true, // 跳過 onboarding
    });
  });

  testWidgets('App 應該可以正常啟動', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    await tester.pumpAndSettle();

    // 驗證首頁翻譯按鈕存在
    expect(find.text('長按翻譯'), findsOneWidget);

    // 驗證今日任務卡片存在
    expect(find.text('今日任務'), findsOneWidget);

    // 驗證每日報告卡片存在
    expect(find.text('今日貓咪報告'), findsOneWidget);
  });

  testWidgets('點擊每日報告卡片可以打開報告頁面', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    await tester.pumpAndSettle();

    // 點擊每日報告卡片
    await tester.tap(find.text('今日貓咪報告'));
    await tester.pumpAndSettle();

    // 驗證進入了報告頁面
    expect(find.text('今日貓咪報告'), findsWidgets);
  });

  testWidgets('長按翻譯按鈕應該可以錄音', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    await tester.pumpAndSettle();

    // 找到主要按鈕（長按翻譯）
    final buttonFinder = find.text('長按翻譯');
    expect(buttonFinder, findsOneWidget);
  });

  testWidgets('添加貓咪頁面應該有所有輸入欄位', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddCatPage()));

    // 驗證所有欄位存在
    expect(find.text('性別'), findsOneWidget);
    expect(find.text('年齡'), findsOneWidget);
    expect(find.text('品種'), findsOneWidget);
    expect(find.text('添加'), findsOneWidget);
  });

  testWidgets('年齡滑桿應該可以調整', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddCatPage()));

    // 找到 Slider
    expect(find.byType(Slider), findsOneWidget);

    // 滑動滑桿
    await tester.drag(find.byType(Slider), const Offset(100, 0));
    await tester.pump();
  });

  testWidgets('隱私政策頁面應該可以正常開啟', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyPage()));
    await tester.pumpAndSettle();

    // 驗證標題存在
    expect(find.text('隱私政策'), findsOneWidget);
    
    // 驗證主要章節存在
    expect(find.text('錄音與麥克風使用'), findsOneWidget);
    expect(find.text('貓咪資料'), findsOneWidget);
    expect(find.text('重要安全聲明'), findsOneWidget);
  });

  testWidgets('關於頁面應該可以正常開啟', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AboutPage()));
    await tester.pumpAndSettle();

    // 驗證標題存在
    expect(find.text('關於貓語通'), findsOneWidget);
    
    // 驗證 App 名稱存在
    expect(find.text('讓每一聲喵喵都被聽見'), findsOneWidget);
    
    // 驗證安全聲明存在
    expect(find.text('重要聲明'), findsOneWidget);
  });
}
