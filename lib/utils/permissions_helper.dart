import 'package:permission_handler/permission_handler.dart';

class PermissionsHelper {
  /// الأذونات الأساسية اللي نحتاجها للطباعة والحفظ
  static final List<Permission> _permissions = [
    Permission.storage,            // التخزين لحفظ PDF (Android < 11)
    Permission.manageExternalStorage, // التخزين العميق (Android 11+)
    Permission.bluetooth,          // بلوتوث أساسي
    Permission.bluetoothScan,      // مسح الأجهزة القريبة (Android 12+)
    Permission.bluetoothConnect,   // الاتصال بالأجهزة (Android 12+)
    Permission.bluetoothAdvertise, // إعلان (اختياري لبعض الأجهزة)
  ];

  /// ✅ يطلب كل الأذونات دفعة وحدة
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await _permissions.request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      final denied = statuses.entries
          .where((e) => !e.value.isGranted)
          .map((e) => e.key.toString())
          .toList();
      print("❌ أذونات ناقصة: $denied");
    } else {
      print("✅ كل الأذونات مُنحت بنجاح");
    }

    return allGranted;
  }

  /// ✅ يفحص إذا الأذونات كلها متاحة
  static Future<bool> checkPermissions() async {
    for (var permission in _permissions) {
      if (!await permission.isGranted) {
        print("❌ مفقود: $permission");
        return false;
      }
    }
    return true;
  }

  /// ✅ يتأكد من الأذونات (يفحص + يطلب إذا ناقصة)
  static Future<bool> ensurePermissions() async {
    final granted = await checkPermissions();
    if (granted) return true;
    return await requestAllPermissions();
  }
}