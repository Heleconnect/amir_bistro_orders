import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:amir_bistro_orders/main.dart';
import 'package:amir_bistro_orders/providers/settings_provider.dart';
import 'package:amir_bistro_orders/screens/home_screen.dart'; // ✅ إضافة مهمة

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // إنشاء SettingsProvider وتحميل الإعدادات
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    // تشغيل التطبيق
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              return FutureBuilder<bool>(
                future: Future.value(true), // نفترض أن الأذونات متاحة
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }
                  return const HomeScreen(); // ✅ صار معرف
                },
              );
            },
          ),
        ),
      ),
    );

    // التحقق أن التطبيق مبني وفيه Scaffold (يعني شاشة رئيسية)
    expect(find.byType(Scaffold), findsOneWidget);
  });
}