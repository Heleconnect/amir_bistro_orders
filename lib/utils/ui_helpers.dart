import 'package:flutter/material.dart';

class UiHelper {
  /// 🎨 Snackbar موحّد (نجاح / خطأ / تحذير + أيقونة + Action)
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool error = false,
    bool warning = false,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final color = error
        ? Colors.red
        : warning
            ? Colors.orange
            : Colors.green;

    final icon = error
        ? Icons.error
        : warning
            ? Icons.warning
            : Icons.check_circle;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: (actionLabel != null && onAction != null)
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }

  /// 📌 Dialog موحّد للتأكيد أو التحذير
  static Future<bool?> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isDestructive ? Icons.warning : Icons.info,
              color: isDestructive ? Colors.red : Colors.blue,
            ),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.green,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  /// ⏳ Loader موحّد مع خيارات إضافية
  static Widget buildLoader({
    String? text,
    Color color = Colors.blue,
    double size = 40,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(color: color),
          ),
          if (text != null) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}