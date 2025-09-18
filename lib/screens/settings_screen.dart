// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import 'connect_printer_screen.dart';
import 'invoice_design_screen.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _restaurantNameController;
  late TextEditingController _restaurantAddressController;
  late TextEditingController _thankYouController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _restaurantNameController =
        TextEditingController(text: settings.restaurantName);
    _restaurantAddressController =
        TextEditingController(text: settings.restaurantAddress);
    _thankYouController =
        TextEditingController(text: settings.thankYouMessage);
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _thankYouController.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: error ? Colors.red : Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("⚙️ الإعدادات")),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ⚙️ الإعدادات العامة
            _buildSection(icon: Icons.settings, title: "⚙️ الإعدادات العامة", children: [
              TextField(
                controller: _restaurantNameController,
                decoration: const InputDecoration(
                  labelText: "اسم المطعم",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                onChanged: settings.setRestaurantName,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restaurantAddressController,
                decoration: const InputDecoration(
                  labelText: "عنوان المطعم",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: settings.setRestaurantAddress,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: settings.currency,
                decoration: const InputDecoration(
                  labelText: "العملة",
                  border: OutlineInputBorder(),
                ),
                items: ["€", "د.ل", "\$", "£"].map((c) {
                  return DropdownMenuItem(value: c, child: Text(c));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    settings.setCurrency(val);
                    _showSnack(context, "تم تغيير العملة إلى $val ✅");
                  }
                },
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.format_size, color: Colors.deepPurple),
                title: const Text("حجم الخط"),
                subtitle: Slider(
                  min: 10,
                  max: 24,
                  divisions: 14,
                  value: settings.fontSize,
                  label: settings.fontSize.toStringAsFixed(0),
                  onChanged: settings.setFontSize,
                ),
                trailing: Text(
                  "${settings.fontSize.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: settings.fontFamily,
                decoration: const InputDecoration(
                  labelText: "نوع الخط",
                  border: OutlineInputBorder(),
                ),
                items: {
                  "default": "افتراضي",
                  "bold": "عريض",
                  "cursive": "مزخرف",
                }.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    settings.setFontFamily(val);
                    _showSnack(context, "تم تغيير الخط ✅");
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _thankYouController,
                decoration: const InputDecoration(
                  labelText: "رسالة الشكر للزبون",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.favorite),
                ),
                maxLines: 2,
                onChanged: settings.setThankYouMessage,
              ),
            ]),

            // 🖨️ الطابعات
            _buildSection(icon: Icons.print, title: "🖨️ الطابعات", children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, ConnectPrinterScreen.routeName);
                },
                icon: const Icon(Icons.print),
                label: const Text("إدارة الطابعات"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  final success = await settings.printTestPage();
                  _showSnack(context,
                      success ? "✅ تمت طباعة صفحة اختبار" : "⚠️ فشل الطباعة");
                },
                icon: const Icon(Icons.print_outlined),
                label: const Text("تجربة الطابعة"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  settings.resetPrinters();
                  _showSnack(context, "🖨️ تم مسح إعدادات الطابعات");
                },
                icon: const Icon(Icons.clear_all),
                label: const Text("تصفير الطابعات"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ]),

            // 🧾 تصميم الفاتورة
            _buildSection(
              icon: Icons.receipt_long,
              title: "🧾 تصميم الفاتورة",
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, InvoiceDesignScreen.routeName);
                  },
                  icon: const Icon(Icons.receipt_long),
                  label: const Text("تخصيص تصميم الفاتورة"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),

            // 🧹 إدارة الطلبات
            _buildSection(icon: Icons.list_alt, title: "🧹 إدارة الطلبات", children: [
              SwitchListTile(
                title: const Text("تفعيل خيار منجز ✅"),
                subtitle: const Text("إظهار أو إخفاء خانة منجز داخل الطلبات"),
                value: settings.completedEnabled,
                onChanged: (val) {
                  settings.setCompletedEnabled(val);
                  _showSnack(context,
                      val ? "✅ تم تفعيل خيار منجز" : "⛔️ تم إلغاء خيار منجز");
                },
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  settings.resetOrderCounter();
                  _showSnack(context, "✅ تم تصفير عداد الطلبات");
                },
                icon: const Icon(Icons.refresh),
                label: const Text("تصفير عداد الطلبات"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ]),

            // 🔄 إعادة ضبط
            _buildSection(icon: Icons.restore, title: "🔄 إعادة ضبط", children: [
              OutlinedButton.icon(
                onPressed: () {
                  settings.resetToDefaults();
                  setState(() {
                    _restaurantNameController.text = settings.restaurantName;
                    _restaurantAddressController.text =
                        settings.restaurantAddress;
                    _thankYouController.text = settings.thankYouMessage;
                  });
                  _showSnack(context, "تمت إعادة الإعدادات الافتراضية ✅");
                },
                icon: const Icon(Icons.restore),
                label: const Text("إعادة الإعدادات الافتراضية"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}