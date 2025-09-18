// lib/screens/connect_printer_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

import '../providers/settings_provider.dart';
import '../services/printing_service.dart';
import '../utils/permissions_helper.dart';
import '../utils/ui_helpers.dart'; // ✅ نستخدم UiHelper

class ConnectPrinterScreen extends StatefulWidget {
  static const routeName = '/connect-printer';
  const ConnectPrinterScreen({super.key});

  @override
  State<ConnectPrinterScreen> createState() => _ConnectPrinterScreenState();
}

class _ConnectPrinterScreenState extends State<ConnectPrinterScreen> {
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  bool _isConnecting = false;
  PrinterType _target = PrinterType.shared;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    final ok = await PermissionsHelper.checkPermissions();
    if (!ok) {
      if (!mounted) return;
      UiHelper.showConfirmDialog(
        context,
        title: "الأذونات مطلوبة",
        message:
        "رجاءً فعّل إذن البلوتوث من الإعدادات حتى أتمكن من البحث عن الطابعات.",
        isDestructive: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final devices = await _bluetooth.getBondedDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      UiHelper.showSnackBar(context, "❌ تعذر قراءة الطابعات: $e", error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _connectTo(BluetoothDevice device, PrinterType type) async {
    final ok = await PermissionsHelper.checkPermissions();
    if (!ok) {
      UiHelper.showConfirmDialog(
        context,
        title: "الأذونات مطلوبة",
        message: "لا يمكن الاتصال بالطابعة بدون إذن البلوتوث.",
        isDestructive: true,
      );
      return;
    }

    setState(() => _isConnecting = true);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final service = PrintingService(settings: settings);

    try {
      if (await _bluetooth.isConnected ?? false) {
        await _bluetooth.disconnect();
      }

      final success = await service.connectPrinter(device, type);
      if (!mounted) return;

      UiHelper.showSnackBar(
        context,
        success
            ? "✅ تم الاتصال بـ ${device.name ?? device.address}"
            : "❌ فشل الاتصال بالطابعة",
        error: !success,
      );
    } catch (e) {
      UiHelper.showSnackBar(context, "خطأ أثناء الاتصال: $e", error: true);
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _test(PrinterType type) async {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final service = PrintingService(settings: settings);

    try {
      await service.printTest(type);
      if (!mounted) return;
      UiHelper.showSnackBar(
        context,
        switch (type) {
          PrinterType.kitchen => "✅ اختبار طابعة المطبخ ناجح",
          PrinterType.customer => "✅ اختبار طابعة الزبون ناجح",
          PrinterType.shared => "✅ اختبار الطابعة المشتركة ناجح",
        },
      );
    } catch (e) {
      UiHelper.showSnackBar(context, "فشل اختبار الطباعة: $e", error: true);
    }
  }

  Future<void> _disconnect() async {
    try {
      if (await _bluetooth.isConnected ?? false) {
        await _bluetooth.disconnect();
      }
      UiHelper.showSnackBar(context, "📴 تم قطع الاتصال بالطابعة");
    } catch (_) {
      UiHelper.showSnackBar(context, "❌ تعذر قطع الاتصال", error: true);
    }
  }

  Widget _buildTargetSelector() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text("المشتركة"),
          selected: _target == PrinterType.shared,
          onSelected: (_) => setState(() => _target = PrinterType.shared),
        ),
        ChoiceChip(
          label: const Text("المطبخ"),
          selected: _target == PrinterType.kitchen,
          onSelected: (_) => setState(() => _target = PrinterType.kitchen),
        ),
        ChoiceChip(
          label: const Text("الزبون"),
          selected: _target == PrinterType.customer,
          onSelected: (_) => setState(() => _target = PrinterType.customer),
        ),
      ],
    );
  }

  Widget _buildCurrentSelectionCard() {
    final settings = Provider.of<SettingsProvider>(context);
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("الطابعات الحالية",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            _rowLabel("المشتركة:", settings.sharedPrinterDevice?.name),
            _rowLabel("المطبخ:", settings.kitchenPrinterDevice?.name),
            _rowLabel("الزبون:", settings.customerPrinterDevice?.name),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _test(PrinterType.shared),
                  icon: const Icon(Icons.print),
                  label: const Text("اختبار المشتركة"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _test(PrinterType.kitchen),
                  icon: const Icon(Icons.kitchen),
                  label: const Text("اختبار المطبخ"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _test(PrinterType.customer),
                  icon: const Icon(Icons.person),
                  label: const Text("اختبار الزبون"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowLabel(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(title)),
          Expanded(
            child: Text(
              value ?? "❌ غير محددة",
              style: TextStyle(
                color: value == null ? Colors.red : Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    if (_isLoading || _isConnecting) {
      return Expanded(child: UiHelper.buildLoader(text: "جاري البحث..."));
    }
    if (_devices.isEmpty) {
      return const Expanded(
        child: Center(child: Text("🔍 لا توجد طابعات مقترنة")),
      );
    }

    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _devices.length,
        itemBuilder: (ctx, i) {
          final d = _devices[i];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.print, color: Colors.indigo),
              title: Text(d.name ?? "بدون اسم"),
              subtitle: Text(d.address ?? ""),
              trailing: ElevatedButton(
                onPressed: () => _connectTo(d, _target),
                child: Text(
                  switch (_target) {
                    PrinterType.shared => "تعيين كـ مشتركة",
                    PrinterType.kitchen => "تعيين كـ مطبخ",
                    PrinterType.customer => "تعيين كـ زبون",
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionsBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.refresh),
              label: const Text("إعادة البحث"),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off),
              label: const Text("قطع الاتصال"),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("🔌 توصيل الطابعة")),
        body: Column(
          children: [
            const SizedBox(height: 8),
            _buildCurrentSelectionCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Text("اختر هدف الاتصال:",
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  _buildTargetSelector(),
                ],
              ),
            ),
            _buildDevicesList(),
            _buildActionsBar(),
          ],
        ),
      ),
    );
  }
}