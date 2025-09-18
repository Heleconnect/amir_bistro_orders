import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:collection/collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider with ChangeNotifier {
  // ======================
  // 🔹 إعدادات عامة
  // ======================
  bool _completedEnabled = true;
  int _orderCounter = 0;
  String _restaurantName = "AMIR BISTRO";
  String _restaurantAddress = "Neustadt 47, 24939 Flensburg";
  double _fontSize = 14.0;
  String _fontFamily = "default";
  bool _showNotes = true;
  String _currency = "€";
  String _thankYouMessage = "شكراً لتعاملكم معنا ❤️";

  // ======================
  // 🔹 الطابعات
  // ======================
  String? _kitchenPrinterName;
  String? _customerPrinterName;
  String? _sharedPrinterName;

  BluetoothDevice? _kitchenPrinterDevice;
  BluetoothDevice? _customerPrinterDevice;
  BluetoothDevice? _sharedPrinterDevice;

  // ======================
  // 🔹 Firebase + Debounce
  // ======================
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Timer? _debounceTimer;

  // ======================
  // 🔹 Getters
  // ======================
  bool get completedEnabled => _completedEnabled;
  int get orderCounter => _orderCounter;
  String get restaurantName => _restaurantName;
  String get restaurantAddress => _restaurantAddress;
  double get fontSize => _fontSize;
  String get fontFamily => _fontFamily;
  bool get showNotes => _showNotes;
  String get currency => _currency;
  String get thankYouMessage => _thankYouMessage;

  String? get kitchenPrinterName => _kitchenPrinterName;
  String? get customerPrinterName => _customerPrinterName;
  String? get sharedPrinterName => _sharedPrinterName;

  BluetoothDevice? get kitchenPrinterDevice => _kitchenPrinterDevice;
  BluetoothDevice? get customerPrinterDevice => _customerPrinterDevice;
  BluetoothDevice? get sharedPrinterDevice => _sharedPrinterDevice;

  // ======================
  // 🔹 تحميل الإعدادات
  // ======================
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    _restaurantName = prefs.getString("restaurantName") ?? _restaurantName;
    _restaurantAddress = prefs.getString("restaurantAddress") ?? _restaurantAddress;
    _fontSize = prefs.getDouble("fontSize") ?? _fontSize;
    _fontFamily = prefs.getString("fontFamily") ?? _fontFamily;
    _showNotes = prefs.getBool("showNotes") ?? _showNotes;
    _completedEnabled = prefs.getBool("completedEnabled") ?? _completedEnabled;
    _orderCounter = prefs.getInt("orderCounter") ?? _orderCounter;
    _currency = prefs.getString("currency") ?? _currency;
    _thankYouMessage = prefs.getString("thankYouMessage") ?? _thankYouMessage;

    _kitchenPrinterName = prefs.getString("kitchenPrinterName");
    _customerPrinterName = prefs.getString("customerPrinterName");
    _sharedPrinterName = prefs.getString("sharedPrinterName");

    await _reconnectPrinters();
    notifyListeners();

    // ✅ استماع مباشر لتغييرات Firebase
    _firestore.collection("settings").doc("main").snapshots().listen((doc) {
      if (!doc.exists) return;
      final data = doc.data()!;
      _restaurantName = data["restaurantName"] ?? _restaurantName;
      _restaurantAddress = data["restaurantAddress"] ?? _restaurantAddress;
      _fontSize = (data["fontSize"] ?? _fontSize).toDouble();
      _fontFamily = data["fontFamily"] ?? _fontFamily;
      _showNotes = data["showNotes"] ?? _showNotes;
      _completedEnabled = data["completedEnabled"] ?? _completedEnabled;
      _orderCounter = data["orderCounter"] ?? _orderCounter;
      _currency = data["currency"] ?? _currency;
      _thankYouMessage = data["thankYouMessage"] ?? _thankYouMessage;

      _kitchenPrinterName = data["kitchenPrinterName"];
      _customerPrinterName = data["customerPrinterName"];
      _sharedPrinterName = data["sharedPrinterName"];

      _reconnectPrinters();
      notifyListeners();
    });
  }

  // ======================
  // 🔹 حفظ الإعدادات (محلي + Firebase مع Debounce)
  // ======================
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("restaurantName", _restaurantName);
    await prefs.setString("restaurantAddress", _restaurantAddress);
    await prefs.setDouble("fontSize", _fontSize);
    await prefs.setString("fontFamily", _fontFamily);
    await prefs.setBool("showNotes", _showNotes);
    await prefs.setBool("completedEnabled", _completedEnabled);
    await prefs.setInt("orderCounter", _orderCounter);
    await prefs.setString("currency", _currency);
    await prefs.setString("thankYouMessage", _thankYouMessage);

    if (_kitchenPrinterName != null) prefs.setString("kitchenPrinterName", _kitchenPrinterName!);
    if (_customerPrinterName != null) prefs.setString("customerPrinterName", _customerPrinterName!);
    if (_sharedPrinterName != null) prefs.setString("sharedPrinterName", _sharedPrinterName!);

    // ✅ Debounce → يحفظ في Firebase بعد 3 ثوانٍ
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () async {
      try {
        await _firestore.collection("settings").doc("main").set({
          "restaurantName": _restaurantName,
          "restaurantAddress": _restaurantAddress,
          "fontSize": _fontSize,
          "fontFamily": _fontFamily,
          "showNotes": _showNotes,
          "completedEnabled": _completedEnabled,
          "orderCounter": _orderCounter,
          "currency": _currency,
          "thankYouMessage": _thankYouMessage,
          "kitchenPrinterName": _kitchenPrinterName,
          "customerPrinterName": _customerPrinterName,
          "sharedPrinterName": _sharedPrinterName,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("⚠️ خطأ أثناء حفظ الإعدادات في Firebase: $e");
      }
    });
  }

  // ======================
  // 🔹 Setters
  // ======================
  void setRestaurantName(String name) { _restaurantName = name; notifyListeners(); saveSettings(); }
  void setRestaurantAddress(String address) { _restaurantAddress = address; notifyListeners(); saveSettings(); }
  void setFontSize(double size) { _fontSize = size; notifyListeners(); saveSettings(); }
  void setFontFamily(String family) { _fontFamily = family; notifyListeners(); saveSettings(); }
  void setShowNotes(bool value) { _showNotes = value; notifyListeners(); saveSettings(); }
  void setCurrency(String value) { _currency = value; notifyListeners(); saveSettings(); }
  void setThankYouMessage(String message) { _thankYouMessage = message; notifyListeners(); saveSettings(); }
  void setCompletedEnabled(bool value) { _completedEnabled = value; notifyListeners(); saveSettings(); }
  void resetOrderCounter() { _orderCounter = 0; notifyListeners(); saveSettings(); }

  // ======================
  // 🔹 Reset
  // ======================
  void resetToDefaults() {
    _restaurantName = "AMIR BISTRO";
    _restaurantAddress = "Neustadt 47, 24939 Flensburg";
    _currency = "€";
    _fontSize = 14.0;
    _fontFamily = "default";
    _thankYouMessage = "شكراً لتعاملكم معنا ❤️";
    _showNotes = true;
    _completedEnabled = true;
    _orderCounter = 0;

    // تصفير الطابعات
    _kitchenPrinterName = null;
    _customerPrinterName = null;
    _sharedPrinterName = null;
    _kitchenPrinterDevice = null;
    _customerPrinterDevice = null;
    _sharedPrinterDevice = null;

    notifyListeners();
    saveSettings();
  }

  // ======================
  // 🔹 Printers
  // ======================
  Future<void> _reconnectPrinters() async {
    final devices = await BlueThermalPrinter.instance.getBondedDevices();
    if (_kitchenPrinterName != null) {
      _kitchenPrinterDevice = devices.firstWhereOrNull((d) => d.name == _kitchenPrinterName);
    }
    if (_customerPrinterName != null) {
      _customerPrinterDevice = devices.firstWhereOrNull((d) => d.name == _customerPrinterName);
    }
    if (_sharedPrinterName != null) {
      _sharedPrinterDevice = devices.firstWhereOrNull((d) => d.name == _sharedPrinterName);
    }
  }

  // ✅ مسح إعدادات الطابعات فقط
  void resetPrinters() {
    _kitchenPrinterName = null;
    _customerPrinterName = null;
    _sharedPrinterName = null;
    _kitchenPrinterDevice = null;
    _customerPrinterDevice = null;
    _sharedPrinterDevice = null;
    notifyListeners();
    saveSettings();
  }

  // ✅ طباعة صفحة اختبار
  Future<bool> printTestPage() async {
    try {
      final printer = BlueThermalPrinter.instance;

      // استخدام الطابعة المشتركة إن وجدت، أو أول طابعة متصلة
      final device = _sharedPrinterDevice ?? _customerPrinterDevice ?? _kitchenPrinterDevice;
      if (device == null) return false;

      await printer.connect(device);
      await printer.printNewLine();
      await printer.printCustom("=== صفحة اختبار ===", 2, 1);
      await printer.printCustom(_restaurantName, 1, 1);
      await printer.printCustom(_restaurantAddress, 0, 1);
      await printer.printNewLine();
      await printer.printCustom("شكراً لاستخدامك النظام ✅", 1, 1);
      await printer.printNewLine();
      await printer.paperCut(); // قص الورق (لو مدعوم)
      return true;
    } catch (e) {
      debugPrint("⚠️ فشل في الطباعة التجريبية: $e");
      return false;
    }
  }
}