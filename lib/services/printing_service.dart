import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../providers/settings_provider.dart';

enum PrinterType { kitchen, customer, shared }

class PrintingService {
  final SettingsProvider settings;
  static final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  PrintingService({required this.settings});

  // مراجع أجهزة الطابعات من الإعدادات
  BluetoothDevice? get _kitchenDevice => settings.kitchenPrinterDevice;
  BluetoothDevice? get _customerDevice => settings.customerPrinterDevice;
  BluetoothDevice? get _sharedDevice => settings.sharedPrinterDevice;

  /// ✅ دالة موحدة للتأكد من الاتصال
  Future<bool> _ensureConnected(BluetoothDevice device) async {
    try {
      final isConnected = await _bluetooth.isConnected ?? false;
      if (!isConnected) {
        await _bluetooth.connect(device);
      }
      return true;
    } catch (e) {
      debugPrint("⚠️ فشل الاتصال بالطابعة: $e");
      return false;
    }
  }

  /// ===== الاتصال بالطابعة =====
  Future<bool> connectPrinter(BluetoothDevice device, PrinterType type) async {
    if (!await _ensureConnected(device)) return false;

    // خزّن الجهاز والاسم حسب النوع
    switch (type) {
      case PrinterType.kitchen:
        settings.kitchenPrinterDevice = device;
        settings.kitchenPrinterName = device.name;
        break;
      case PrinterType.customer:
        settings.customerPrinterDevice = device;
        settings.customerPrinterName = device.name;
        break;
      case PrinterType.shared:
        settings.sharedPrinterDevice = device;
        settings.sharedPrinterName = device.name;
        break;
    }
    return true;
  }

  /// ===== طباعة اختبارية =====
  Future<void> printTest(PrinterType type) async {
    final device = switch (type) {
      PrinterType.kitchen => _kitchenDevice,
      PrinterType.customer => _customerDevice,
      PrinterType.shared => _sharedDevice,
    };

    if (device == null) return;
    if (!await _ensureConnected(device)) return;

    _bluetooth.printNewLine();
    _bluetooth.printCustom(
      switch (type) {
        PrinterType.kitchen => "=== اختبار طابعة المطبخ ===",
        PrinterType.customer => "=== اختبار طابعة الزبون ===",
        PrinterType.shared => "=== اختبار الطابعة المشتركة ===",
      },
      2,
      1,
    );
    _bluetooth.printNewLine();
    _bluetooth.printCustom("تم الاتصال بنجاح ✅", 1, 1);
    _bluetooth.printNewLine();

    try {
      await _bluetooth.paperCut();
    } catch (_) {}
  }

  /// ===== طباعة الطلب مباشرة (نصي) =====
  Future<void> _printDirect(Map<String, dynamic> order, PrinterType type) async {
    final device = switch (type) {
      PrinterType.kitchen => _kitchenDevice,
      PrinterType.customer => _customerDevice,
      PrinterType.shared => _sharedDevice,
    };

    if (device == null) return;
    if (!await _ensureConnected(device)) return;

    _bluetooth.printNewLine();

    if (type == PrinterType.kitchen) {
      // ✅ فاتورة المطبخ
      _bluetooth.printCustom("=== فاتورة المطبخ ===", 2, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("رقم الطلب: ${order['id']}", 1, 0);
      _bluetooth.printNewLine();

      if (order['items'] != null) {
        for (final item in (order['items'] as List)) {
          final notes = (item['notes'] is List && (item['notes'] as List).isNotEmpty)
              ? " (${(item['notes'] as List).join(', ')})"
              : "";
          _bluetooth.printCustom("${item['name']} ×${item['quantity']}$notes", 1, 0);
        }
      }

      _bluetooth.printNewLine();
      _bluetooth.printCustom("الإجمالي: ${order['total']} ${settings.currency}", 2, 1);
    } else if (type == PrinterType.customer) {
      // ✅ فاتورة الزبون
      _bluetooth.printCustom("=== فاتورة الزبون ===", 2, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("رقم الطلب: ${order['id']}", 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom("الإجمالي: ${order['total']} ${settings.currency}", 2, 1);
      _bluetooth.printNewLine();
      _bluetooth.printCustom(settings.thankYouMessage, 1, 1);
    }

    _bluetooth.printNewLine();
    try {
      await _bluetooth.paperCut();
    } catch (_) {}
  }

  /// ===== طباعة PDF =====
  Future<void> printPdf(Uint8List pdfData, {BluetoothDevice? device}) async {
    try {
      if (device != null && await _ensureConnected(device)) {
        await Printing.layoutPdf(
          onLayout: (format) async => pdfData,
          format: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        );
      }
    } catch (e) {
      debugPrint("⚠️ خطأ أثناء طباعة PDF: $e");
    }
  }

  /// ===== طباعة ذكية (مطبخ + زبون) =====
  Future<void> ensurePrinterAndPrint(
    Map<String, dynamic> kitchenInvoice,
    Map<String, dynamic> customerInvoice,
  ) async {
    if (_sharedDevice != null) {
      await _printDirect(kitchenInvoice, PrinterType.shared);
      await _printDirect(customerInvoice, PrinterType.shared);
      return;
    }

    if (_kitchenDevice != null && _customerDevice == null) {
      await _printDirect(kitchenInvoice, PrinterType.kitchen);
      await _printDirect(customerInvoice, PrinterType.kitchen);
      return;
    }

    if (_customerDevice != null && _kitchenDevice == null) {
      await _printDirect(kitchenInvoice, PrinterType.customer);
      await _printDirect(customerInvoice, PrinterType.customer);
      return;
    }

    if (_kitchenDevice != null && _customerDevice != null) {
      await _printDirect(kitchenInvoice, PrinterType.kitchen);
      await _printDirect(customerInvoice, PrinterType.customer);
    } else {
      debugPrint("⚠️ لم يتم إعداد أي طابعة للطباعة.");
    }
  }
}