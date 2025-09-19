import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amir_bistro_orders/main.dart';
import 'package:amir_bistro_orders/providers/settings_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // إنشاء SettingsProvider وتحميل الإعدادات
    final settingsProvider = SettingsProvider();
    await settingsProvider.loadSettings();

    // تشغيل التطبيق
    await tester.pumpWidget(
      AmirBistroApp(
        settingsProvider: settingsProvider,
        permissionsGranted: true, // نفترض أن الأذونات متاحة
      ),
    );

    // التحقق أن التطبيق مبني وفيه Scaffold (يعني شاشة رئيسية)
    expect(find.byType(Scaffold), findsOneWidget);
  });
}