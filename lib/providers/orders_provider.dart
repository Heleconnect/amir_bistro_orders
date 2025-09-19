import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart' as app_models; // ✅ Alias لموديل الطلب
import '../services/db_helper.dart';
import 'settings_provider.dart';

enum OrdersFilterType { all, done, notDone }

class OrdersProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<app_models.Order> _orders = [];
  final List<app_models.Order> _pendingSyncOrders = []; // 🕒 الطلبات المعلقة
  String _searchQuery = "";
  OrdersFilterType _filterType = OrdersFilterType.all;

  int _orderCounter = 1;
  final SettingsProvider settings;

  OrdersProvider({required this.settings}) {
    // ✅ الاستماع المباشر لتغييرات الطلبات من Firebase
    _firestore
        .collection("orders")
        .orderBy("number", descending: true)
        .snapshots()
        .listen(_updateOrdersFromSnapshot);

    // ✅ محاولة إعادة المزامنة كل 10 ثوانٍ
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (_pendingSyncOrders.isNotEmpty) {
        _syncPendingOrders();
      }
    });
  }

  // ================== 📌 Getters ==================
  List<app_models.Order> get orders => [..._orders];
  int get nextOrderNumber => _orderCounter;

  List<app_models.Order> get filteredOrders {
    return _orders.where((o) {
      final matchesSearch = _searchQuery.isEmpty ||
          o.number.toString().contains(_searchQuery);

      final matchesFilter = _filterType == OrdersFilterType.all ||
          (_filterType == OrdersFilterType.done && o.done) ||
          (_filterType == OrdersFilterType.notDone && !o.done);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  OrdersFilterType get filterType => _filterType;

  // ================== 📌 تحميل الطلبات ==================
  Future<void> loadOrders() async {
    final localOrders = await DBHelper.getOrders();
    _orders
      ..clear()
      ..addAll(localOrders);

    final snapshot = await _firestore.collection("orders").get();
    for (var doc in snapshot.docs) {
      final order = app_models.Order.fromJson(doc.data() as Map<String, dynamic>);
      if (!_orders.any((o) => o.number == order.number)) {
        final orderId = await DBHelper.insertOrder(order);
        order.id = orderId;
        _orders.add(order);
      }
    }

    _orderCounter = _orders.isNotEmpty
        ? _orders.map((o) => o.number).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    notifyListeners();
  }

  // ================== 📌 إضافة طلب جديد ==================
  Future<void> addOrder(app_models.Order order) async {
    order.number = _orderCounter;

    final orderId = await DBHelper.insertOrder(order);
    order.id = orderId;

    _orders.add(order);
    _pendingSyncOrders.add(order);
    _orderCounter++;

    await _syncPendingOrders();
    notifyListeners();
  }

  // ================== 📌 تحديث من Firebase ==================
  void _updateOrdersFromSnapshot(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      final order =
          app_models.Order.fromJson(change.doc.data() as Map<String, dynamic>);

      if (change.type == DocumentChangeType.added) {
        if (!_orders.any((o) => o.number == order.number)) {
          final orderId = await DBHelper.insertOrder(order);
          order.id = orderId;
          _orders.add(order);
        }
      } else if (change.type == DocumentChangeType.modified) {
        final index = _orders.indexWhere((o) => o.number == order.number);
        if (index != -1) {
          _orders[index] = order;
          await DBHelper.updateOrder(order);
        }
      } else if (change.type == DocumentChangeType.removed) {
        _orders.removeWhere((o) => o.number == order.number);
        await DBHelper.deleteOrder(order.number);
      }
    }

    _orderCounter = _orders.isNotEmpty
        ? _orders.map((o) => o.number).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    notifyListeners();
  }

  // ================== 📌 مزامنة الطلبات المعلقة ==================
  Future<void> _syncPendingOrders() async {
    if (_pendingSyncOrders.isEmpty) return;

    final List<app_models.Order> syncedOrders = [];
    for (var order in _pendingSyncOrders) {
      try {
        await _firestore
            .collection("orders")
            .doc(order.number.toString())
            .set(order.toJson());

        syncedOrders.add(order);
      } catch (e) {
        debugPrint("⚠️ فشل مزامنة الطلب ${order.number}: $e");
      }
    }

    _pendingSyncOrders.removeWhere((o) => syncedOrders.contains(o));

    if (syncedOrders.isNotEmpty) {
      debugPrint("✅ تمت مزامنة ${syncedOrders.length} طلب بنجاح مع Firebase");
    }
  }

  // ================== 📌 حذف كل الطلبات ==================
  Future<void> clearAllOrders() async {
    _orders.clear();
    _pendingSyncOrders.clear();
    _orderCounter = 1;
    notifyListeners();

    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection("orders").get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await DBHelper.clearOrders();
    } catch (e) {
      debugPrint("⚠️ خطأ عند حذف الطلبات: $e");
    }
  }

  // ================== 📌 الحصول على طلب ==================
  app_models.Order? getOrderByNumber(int number) {
    try {
      return _orders.firstWhere((o) => o.number == number);
    } catch (_) {
      return null;
    }
  }

  // ================== 📌 تحديث حالة الطلب ==================
  Future<void> setOrderDone(int number, bool done) async {
    final order = getOrderByNumber(number);
    if (order == null) return;

    order.done = done;
    notifyListeners();

    try {
      await _firestore
          .collection("orders")
          .doc(number.toString())
          .update({'done': done});

      await DBHelper.updateOrder(order);
    } catch (e) {
      debugPrint("⚠️ خطأ عند تحديث حالة الطلب: $e");
      if (!_pendingSyncOrders.contains(order)) {
        _pendingSyncOrders.add(order);
      }
    }
  }

  // ================== 📌 البحث ==================
  void searchOrders(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ================== 📌 تغيير الفلتر ==================
  void setFilterType(OrdersFilterType type) {
    _filterType = type;
    notifyListeners();
  }
}