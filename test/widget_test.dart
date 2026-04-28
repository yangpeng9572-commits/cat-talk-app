import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/screens/add_cat_page.dart';
import 'package:cat_talk/screens/privacy_policy_page.dart';
import 'package:cat_talk/screens/about_page.dart';

void main() {
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
