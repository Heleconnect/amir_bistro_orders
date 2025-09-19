import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/ui_helpers.dart';

class PermissionsHelper {
  /// الأذونات الأساسية للطباعة والحفظ
  static final List<Permission> _permissions = [
    Permission.storage,               // التخزين لحفظ PDF (Android < 11)
    Permission.manageExternalStorage, // التخزين العميق (Android 11+)
    Permission.bluetooth,             // بلوتوث أساسي
    Permission.bluetoothScan,         // مسح الأجهزة القريبة (Android 12+)
    Permission.bluetoothConnect,      // الاتصال بالأجهزة (Android 12+)
    Permission.bluetoothAdvertise,    // إعلان (اختياري لبعض الأجهزة)
  ];

  /// ✅ نسخة مبسطة (بدون UI) — مناسبة لـ main.dart
  static Future<bool> requestAllPermissions() async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final p in _permissions) {
      statuses[p] = await p.request();
    }

    final bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      final denied = statuses.entries
          .where((e) => !e.value.isGranted)
          .map((e) => e.key.toString())
          .toList();

      debugPrint("⚠️ أذونات ناقصة: $denied");
    }

    return allGranted;
  }

  /// ✅ نسخة بواجهة UI (Snackbar + Dialog مع UiHelper)
  static Future<bool> requestAllPermissionsWithUI(BuildContext context) async {
    final Map<Permission, PermissionStatus> statuses = {};

    for (final p in _permissions) {
      statuses[p] = await p.request();
    }

    final bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      final denied = statuses.entries
          .where((e) => !e.value.isGranted)
          .map((e) => e.key.toString())
          .toList();

      // Snackbar من UiHelper
      UiHelper.showSnackBar(
        context,
        "⚠️ الأذونات الناقصة: $denied",
        warning: true,
      );

      // Dialog من UiHelper
      final goSettings = await UiHelper.showConfirmDialog(
        context,
        title: "الأذونات مطلوبة",
        message: "بعض الأذونات ناقصة. هل تريد فتح الإعدادات الآن؟",
        isDestructive: true,
      );

      if (goSettings == true) {
        await openAppSettings();
      }
    }

    return allGranted;
  }

  /// ✅ يفحص إذا الأذونات كلها متاحة
  static Future<bool> checkPermissions() async {
    for (var permission in _permissions) {
      if (!await permission.isGranted) {
        return false;
      }
    }
    return true;
  }

  /// ✅ يتأكد من الأذونات (بدون UI — مناسب لـ main.dart)
  static Future<bool> ensurePermissions() async {
    final granted = await checkPermissions();
    if (granted) return true;
    return await requestAllPermissions();
  }

  /// ✅ يتأكد من الأذونات (مع UI — مناسب للشاشات)
  static Future<bool> ensurePermissionsWithUI(BuildContext context) async {
    final granted = await checkPermissions();
    if (granted) return true;
    return await requestAllPermissionsWithUI(context);
  }
}