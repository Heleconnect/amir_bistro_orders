// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../utils/ui_helpers.dart';
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

  /// 📌 دالة لإغلاق الكيبورد
  void _closeKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// 🔹 كارد قسم الإعدادات
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

  /// 🔹 زر موحد بحجم كامل
  Widget buildFullButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    Color? color,
    bool outlined = false,
  }) {
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
        ),
      );
    }
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(double.infinity, 50),
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
                onChanged: (val) {
                  settings.setRestaurantName(val);
                  _closeKeyboard(context);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restaurantAddressController,
                decoration: const InputDecoration(
                  labelText: "عنوان المطعم",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                onChanged: (val) {
                  settings.setRestaurantAddress(val);
                  _closeKeyboard(context);
                },
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
                    _closeKeyboard(context);
                    UiHelper.showSnackBar(context, "تم تغيير العملة إلى $val ✅");
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
                    _closeKeyboard(context);
                    UiHelper.showSnackBar(context, "تم تغيير الخط ✅");
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
                onChanged: (val) {
                  settings.setThankYouMessage(val);
                  _closeKeyboard(context);
                },
              ),
            ]),

            // 🖨️ الطابعات
            _buildSection(icon: Icons.print, title: "🖨️ الطابعات", children: [
              buildFullButton(
                onPressed: () {
                  Navigator.pushNamed(context, ConnectPrinterScreen.routeName);
                },
                icon: Icons.print,
                label: "إدارة الطابعات",
              ),
              const SizedBox(height: 12),
              buildFullButton(
                onPressed: () async {
                  final success = await settings.printTestPage();
                  _closeKeyboard(context);
                  if (!success) {
                    UiHelper.showSnackBar(
                      context,
                      "⚠️ لم يتم العثور على طابعة متصلة",
                      warning: true,
                    );
                  } else {
                    UiHelper.showSnackBar(context, "✅ تمت طباعة صفحة اختبار");
                  }
                },
                icon: Icons.print_outlined,
                label: "تجربة الطابعة",
                color: Colors.green,
              ),
              const SizedBox(height: 12),
              buildFullButton(
                onPressed: () async {
                  final confirm = await UiHelper.showConfirmDialog(
                    context,
                    title: "تأكيد العملية",
                    message: "هل تريد تصفير الطابعات؟",
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    settings.resetPrinters();
                    _closeKeyboard(context);
                    UiHelper.showSnackBar(context, "🖨️ تم مسح إعدادات الطابعات");
                  }
                },
                icon: Icons.clear_all,
                label: "تصفير الطابعات",
                color: Colors.orangeAccent,
              ),
            ]),

            // 🧾 تصميم الفاتورة
            _buildSection(
              icon: Icons.receipt_long,
              title: "🧾 تصميم الفاتورة",
              children: [
                buildFullButton(
                  onPressed: () {
                    Navigator.pushNamed(context, InvoiceDesignScreen.routeName);
                  },
                  icon: Icons.receipt_long,
                  label: "تخصيص تصميم الفاتورة",
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
                  _closeKeyboard(context);
                  UiHelper.showSnackBar(
                    context,
                    val ? "✅ تم تفعيل خيار منجز" : "⛔️ تم إلغاء خيار منجز",
                    warning: !val,
                  );
                },
              ),
              const SizedBox(height: 12),
              buildFullButton(
                onPressed: () async {
                  final confirm = await UiHelper.showConfirmDialog(
                    context,
                    title: "تأكيد العملية",
                    message: "هل تريد تصفير عداد الطلبات؟",
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    settings.resetOrderCounter();
                    _closeKeyboard(context);
                    UiHelper.showSnackBar(context, "✅ تم تصفير عداد الطلبات");
                  }
                },
                icon: Icons.refresh,
                label: "تصفير عداد الطلبات",
                color: Colors.redAccent,
              ),
            ]),

            // 🔄 إعادة ضبط
            _buildSection(icon: Icons.restore, title: "🔄 إعادة ضبط", children: [
              buildFullButton(
                onPressed: () async {
                  final confirm = await UiHelper.showConfirmDialog(
                    context,
                    title: "تأكيد العملية",
                    message: "هل تريد إعادة الإعدادات الافتراضية؟",
                    isDestructive: true,
                  );
                  if (confirm == true) {
                    settings.resetToDefaults();
                    setState(() {
                      _restaurantNameController.text = settings.restaurantName;
                      _restaurantAddressController.text =
                          settings.restaurantAddress;
                      _thankYouController.text = settings.thankYouMessage;
                    });
                    _closeKeyboard(context);
                    UiHelper.showSnackBar(
                        context, "تمت إعادة الإعدادات الافتراضية ✅");
                  }
                },
                icon: Icons.restore,
                label: "إعادة الإعدادات الافتراضية",
                outlined: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}