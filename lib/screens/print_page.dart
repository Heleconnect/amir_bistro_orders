import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../services/printing_service.dart';

class PrintPage extends StatelessWidget {
  static const routeName = '/print-page';

  const PrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final printerService = PrintingService(settings: settings);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("اختبار الطباعة")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text(
                "يمكنك اختبار الطابعة هنا للتأكد من الإعدادات",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // زر اختبار طابعة المطبخ
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("اختبار طابعة المطبخ"),
                onPressed: () async {
                  await printerService.printTest(PrinterType.kitchen);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إرسال أمر الطباعة للمطبخ ✅")),
                  );
                },
              ),
              const SizedBox(height: 12),

              // زر اختبار طابعة الزبون
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("اختبار طابعة الزبون"),
                onPressed: () async {
                  await printerService.printTest(PrinterType.customer);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إرسال أمر الطباعة للزبون ✅")),
                  );
                },
              ),
              const SizedBox(height: 12),

              // زر اختبار الطابعة المشتركة
              ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text("اختبار الطابعة المشتركة"),
                onPressed: () async {
                  await printerService.printTest(PrinterType.shared);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("تم إرسال أمر الطباعة للطابعة المشتركة ✅")),
                  );
                },
              ),
              const Divider(height: 32),

              // زر طباعة فاتورة تجريبية
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                icon: const Icon(Icons.receipt_long),
                label: const Text("طباعة فاتورة تجريبية"),
                onPressed: () async {
                  final demoOrder = {
                    "id": 999,
                    "items": [
                      {"name": "بيتزا مارجريتا", "quantity": 2, "price": 15.0},
                      {"name": "بيبسي", "quantity": 1, "price": 3.0},
                    ],
                    "total": 33.0,
                    "restaurantName": settings.restaurantName,
                    "restaurantAddress": settings.restaurantAddress,
                  };

                  try {
                    await printerService.ensurePrinterAndPrint(demoOrder, demoOrder);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تمت طباعة الفاتورة التجريبية ✅")),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("فشل الطباعة: $e")),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}