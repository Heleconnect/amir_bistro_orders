import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order.dart';
import '../services/db_helper.dart';
import 'settings_provider.dart';

enum OrdersFilterType { all, done, notDone }

class OrdersProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Order> _orders = [];
  final List<Order> _pendingSyncOrders = []; // 🕒 الطلبات المعلقة
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
  List<Order> get orders => [..._orders];
  int get nextOrderNumber => _orderCounter;

  List<Order> get filteredOrders {
    return _orders.where((o) {
      // فلترة حسب البحث
      final matchesSearch = _searchQuery.isEmpty ||
          o.number.toString().contains(_searchQuery);

      // فلترة حسب النوع
      final matchesFilter = _filterType == OrdersFilterType.all ||
          (_filterType == OrdersFilterType.done && o.done) ||
          (_filterType == OrdersFilterType.notDone && !o.done);

      return matchesSearch && matchesFilter;
    }).toList();
  }

  OrdersFilterType get filterType => _filterType;

  // ================== 📌 تحميل الطلبات ==================
  Future<void> loadOrders() async {
    // 1. تحميل الطلبات من SQLite
    final localOrders = await DBHelper.getOrders();
    _orders
      ..clear()
      ..addAll(localOrders);

    // 2. تحميل الطلبات من Firebase ودمجها
    final snapshot = await _firestore.collection("orders").get();
    for (var doc in snapshot.docs) {
      final order = Order.fromJson(doc.data() as Map<String, dynamic>);
      if (!_orders.any((o) => o.number == order.number)) {
        final orderId = await DBHelper.insertOrder(order);
        order.id = orderId;
        _orders.add(order);
      }
    }

    // تحديث العداد للطلب القادم
    _orderCounter = _orders.isNotEmpty
        ? _orders.map((o) => o.number).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    notifyListeners();
  }

  // ================== 📌 إضافة طلب جديد ==================
  Future<void> addOrder(Order order) async {
    order.number = _orderCounter;

    // ✅ حفظ محلي أولاً
    final orderId = await DBHelper.insertOrder(order);
    order.id = orderId;

    _orders.add(order);
    _pendingSyncOrders.add(order);
    _orderCounter++;

    // ✅ محاولة المزامنة
    await _syncPendingOrders();

    notifyListeners();
  }

  // ================== 📌 تحديث من Firebase (Add + Modify + Delete) ==================
  void _updateOrdersFromSnapshot(QuerySnapshot snapshot) async {
    for (var change in snapshot.docChanges) {
      final order =
      Order.fromJson(change.doc.data() as Map<String, dynamic>);

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
        await DBHelper.deleteOrder(order.number); // ✅ لازم تضيف هالدالة بـ DBHelper
      }
    }

    // تحديث رقم الطلب التالي
    _orderCounter = _orders.isNotEmpty
        ? _orders.map((o) => o.number).reduce((a, b) => a > b ? a : b) + 1
        : 1;

    notifyListeners();
  }

  // ================== 📌 مزامنة الطلبات المعلقة ==================
  Future<void> _syncPendingOrders() async {
    if (_pendingSyncOrders.isEmpty) return;

    final List<Order> syncedOrders = [];
    for (var order in _pendingSyncOrders) {
      try {
        await _firestore
            .collection("orders")
            .doc(order.number.toString()) // 🔑 رقم الطلب كمفتاح
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
      // حذف من Firebase
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection("orders").get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // حذف من SQLite
      await DBHelper.clearOrders();
    } catch (e) {
      debugPrint("⚠️ خطأ عند حذف الطلبات: $e");
    }
  }

  // ================== 📌 الحصول على طلب ==================
  Order? getOrderByNumber(int number) {
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
      // تحديث في Firebase
      await _firestore
          .collection("orders")
          .doc(number.toString())
          .update({'done': done});

      // تحديث في SQLite
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