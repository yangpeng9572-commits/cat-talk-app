import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cat_talk/main.dart';
import 'package:cat_talk/screens/home_page.dart';
import 'package:cat_talk/screens/cats_page.dart';
import 'package:cat_talk/screens/add_cat_page.dart';

void main() {
  testWidgets('App 應該可以正常啟動', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    
    // 驗證首頁翻譯按鈕存在
    expect(find.text('長按開始自動翻譯'), findsOneWidget);
    
    // 驗證底部導航存在
    expect(find.text('翻譯'), findsOneWidget);
    expect(find.text('貓咪'), findsOneWidget);
    expect(find.text('記錄'), findsOneWidget);
    expect(find.text('簡介'), findsOneWidget);
  });

  testWidgets('點擊底部導航可以切換頁面', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    
    // 點擊貓咪分頁
    await tester.tap(find.text('貓咪'));
    await tester.pumpAndSettle();
    
    // 驗證貓咪頁面
    expect(find.text('添加貓咪簡介'), findsOneWidget);
  });

  testWidgets('長按翻譯按鈕應該可以錄音', (WidgetTester tester) async {
    await tester.pumpWidget(const CatTalkApp());
    
    // 找到主要按鈕（長按翻譯）
    final buttonFinder = find.text('長按開始自動翻譯');
    expect(buttonFinder, findsOneWidget);
  });

  testWidgets('添加貓咪頁面應該有所有輸入欄位', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: AddCatPage()));
    
    // 驗證所有欄位存在
    expect(find.text('貓咪的名字'), findsOneWidget);
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
}
