// lib/screens/invoice_design_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class InvoiceDesignScreen extends StatefulWidget {
  static const routeName = '/invoice-design';

  const InvoiceDesignScreen({super.key});

  @override
  State<InvoiceDesignScreen> createState() => _InvoiceDesignScreenState();
}

class _InvoiceDesignScreenState extends State<InvoiceDesignScreen> {
  late TextEditingController _restaurantNameController;
  late TextEditingController _restaurantAddressController;
  late TextEditingController _thankYouMessageController;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _restaurantNameController =
        TextEditingController(text: settings.restaurantName);
    _restaurantAddressController =
        TextEditingController(text: settings.restaurantAddress);
    _thankYouMessageController =
        TextEditingController(text: settings.thankYouMessage);
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _restaurantAddressController.dispose();
    _thankYouMessageController.dispose();
    super.dispose();
  }

  void _showSnack(BuildContext context, String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: error ? Colors.red : Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("🖨️ تصميم الفاتورة")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              // 🏪 اسم المطعم
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: TextField(
                    controller: _restaurantNameController,
                    decoration: const InputDecoration(
                      labelText: "اسم المطعم",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.store, color: Colors.indigo),
                    ),
                    onChanged: settings.setRestaurantName,
                  ),
                ),
              ),

              // 📍 عنوان المطعم
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: TextField(
                    controller: _restaurantAddressController,
                    decoration: const InputDecoration(
                      labelText: "عنوان المطعم",
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.location_on, color: Colors.teal),
                    ),
                    onChanged: settings.setRestaurantAddress,
                  ),
                ),
              ),

              // 💌 رسالة الشكر (للزبون)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    TextField(
                      controller: _thankYouMessageController,
                      decoration: const InputDecoration(
                        labelText: "رسالة الشكر في فاتورة الزبون",
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.favorite, color: Colors.red),
                      ),
                      onChanged: settings.setThankYouMessage,
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "معاينة: ${settings.thankYouMessage}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              settings.setThankYouMessage(
                                  "شكراً لتعاملكم معنا ❤️");
                              _thankYouMessageController.text =
                                  settings.thankYouMessage;
                              _showSnack(
                                  context, "تم استرجاع الرسالة الافتراضية ✅");
                            },
                            icon: const Icon(Icons.restore, color: Colors.blue),
                            label: const Text("استرجاع الافتراضي"),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 📝 خيار الملاحظات
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: SwitchListTile(
                  value: settings.showNotes,
                  onChanged: settings.setShowNotes,
                  title: const Text("إظهار الملاحظات في الفاتورة"),
                  secondary:
                  const Icon(Icons.note_alt, color: Colors.blueGrey),
                ),
              ),

              // 🔠 حجم الخط
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading:
                  const Icon(Icons.format_size, color: Colors.deepPurple),
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
              ),

              // 🎨 اختيار نوع الخط
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.font_download, color: Colors.brown),
                  title: const Text("نوع الخط"),
                  trailing: DropdownButton<String>(
                    value: settings.fontFamily,
                    underline: const SizedBox(),
                    items: {
                      "default": "افتراضي",
                      "bold": "عريض",
                      "cursive": "مزخرف",
                    }.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        settings.setFontFamily(val);
                        _showSnack(context, "تم تغيير الخط إلى $val ✅");
                      }
                    },
                  ),
                ),
              ),

              // 💱 اختيار العملة
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.attach_money, color: Colors.orange),
                  title: const Text("العملة"),
                  trailing: DropdownButton<String>(
                    value: settings.currency,
                    underline: const SizedBox(),
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
                ),
              ),

              const SizedBox(height: 24),

              // ✅ زر الحفظ
              ElevatedButton.icon(
                onPressed: () {
                  _showSnack(context, "تم حفظ إعدادات الفاتورة ✅");
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.save),
                label: const Text("حفظ التعديلات"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 🔄 زر إعادة ضبط
              OutlinedButton.icon(
                onPressed: () {
                  settings.resetToDefaults();

                  setState(() {
                    _restaurantNameController.text = settings.restaurantName;
                    _restaurantAddressController.text =
                        settings.restaurantAddress;
                    _thankYouMessageController.text = settings.thankYouMessage;
                  });

                  _showSnack(context, "تمت إعادة الإعدادات الافتراضية ✅");
                },
                icon: const Icon(Icons.restore),
                label: const Text("إعادة الإعدادات الافتراضية"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}