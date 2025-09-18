import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import '../providers/settings_provider.dart';
import '../models/order.dart';

class PdfGenerator {
  /// توليد فاتورة المطبخ
  static Future<Uint8List> generateKitchenPdf(dynamic order, SettingsProvider settings) async {
    final pdf = pw.Document();

    final number = (order is Map) ? order['id'] : order.number;
    final items = (order is Map) ? order['items'] : order.items;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'فاتورة المطبخ',
              style: pw.TextStyle(fontSize: settings.fontSize + 2, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            pw.Text('رقم الطلب: $number', style: pw.TextStyle(fontSize: settings.fontSize)),
            pw.Divider(),
            pw.Text('الأصناف:', style: pw.TextStyle(fontSize: settings.fontSize)),
            ...items.map((item) {
              final itemName = (item is Map) ? item['name'] : item.item.name;
              final quantity = (item is Map) ? item['quantity'] ?? item['qty'] : item.quantity;
              final notes = (item is Map)
                  ? (item['notes'] ?? "")
                  : (item.notes.isNotEmpty ? " (${item.notes.join(', ')})" : "");
              return pw.Text(
                "$itemName x$quantity$notes",
                style: pw.TextStyle(fontSize: settings.fontSize),
              );
            }),
            if (settings.showNotes) pw.Divider(),
            if (settings.showNotes)
              pw.Text(
                'ملاحظات: ${(order is Map) ? (order['notes'] ?? '') : order.items.expand((e) => e.notes).join(', ')}',
                style: pw.TextStyle(fontSize: settings.fontSize - 1, color: PdfColors.grey),
              ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// توليد فاتورة الزبون
  static Future<Uint8List> generateCustomerPdf(dynamic order, SettingsProvider settings) async {
    final pdf = pw.Document();

    final number = (order is Map) ? order['id'] : order.number;
    final total = (order is Map) ? order['total'] : order.total;

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              settings.restaurantName,
              style: pw.TextStyle(fontSize: settings.fontSize + 4, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              settings.restaurantAddress,
              style: pw.TextStyle(fontSize: settings.fontSize - 2, color: PdfColors.grey),
            ),
            pw.SizedBox(height: 10),
            pw.Divider(),
            pw.Text('طلب رقم: $number', style: pw.TextStyle(fontSize: settings.fontSize)),
            pw.SizedBox(height: 5),
            pw.Text(
              'الإجمالي: ${total.toStringAsFixed(2)} ${settings.currency}',
              style: pw.TextStyle(fontSize: settings.fontSize + 2, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 15),
            pw.Text(
              'شكراً لزيارتكم ❤️',
              style: pw.TextStyle(fontSize: settings.fontSize, fontWeight: pw.FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }
}