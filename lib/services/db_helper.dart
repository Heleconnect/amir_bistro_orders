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
  final List<Order> _pendingSyncOrders = [];
  String _searchQuery = "";
  OrdersFilterType _filterType = OrdersFilterType.all;

  int _orderCounter = 1;
  final SettingsProvider settings;
  StreamSubscription? _ordersSubscription; // إضافة للإشراف على الاشتراك

  OrdersProvider({required this.settings}) {
    _initialize();
  }

  // تهيئة المشترك والبيانات
  void _initialize() async {
    await loadOrders(); // تحميل الطلبات المحلية أولاً
    _ordersSubscription = _firestore
        .collection("orders")
        .snapshots()
        .listen(_updateOrdersFromSnapshot);

    Timer.periodic(const Duration(seconds: 10), (_) {
      if (_pendingSyncOrders.isNotEmpty) {
        _syncPendingOrders();
      }
    });
  }

  // التخلص من الموارد عند التدمير
  @override
  void dispose() {
    _ordersSubscription?.cancel(); // إلغاء الاشتراك لمنع التسرب
    super.dispose();
  }

  // ================== 📌 Getters ==================
  List<Order> get orders => [..._orders];
  int get nextOrderNumber => _orderCounter;

  List<Order> get filteredOrders {
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
    try {
      final localOrders = await DBHelper.getOrders();
      _orders
        ..clear()
        ..addAll(localOrders);

      // تحميل الطلبات من Firebase للمزامنة
      final snapshot = await _firestore.collection("orders").get();
      for (var doc in snapshot.docs) {
        final orderData = doc.data();
        if (orderData.isNotEmpty) {
          final order = Order.fromJson(orderData);
          if (!_orders.any((o) => o.number == order.number)) {
            final orderId = await DBHelper.insertOrder(order);
            order.id = orderId;
            _orders.add(order);
          }
        }
      }

      // تحديث العداد
      _updateOrderCounter();
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ خطأ في تحميل الطلبات: $e");
    }
  }

  // تحديث عداد الطلبات
  void _updateOrderCounter() {
    if (_orders.isNotEmpty) {
      _orderCounter = _orders.map((o) => o.number).reduce((a, b) => a > b ? a : b) + 1;
    } else {
      _orderCounter = 1;
    }
  }

  // ================== 📌 إضافة طلب جديد ==================
  Future<void> addOrder(Order order) async {
    try {
      order.number = _orderCounter;

      final orderId = await DBHelper.insertOrder(order);
      order.id = orderId;

      _orders.add(order);
      _pendingSyncOrders.add(order);
      _orderCounter++;

      await _syncPendingOrders();
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ خطأ في إضافة الطلب: $e");
      rethrow;
    }
  }

  // ================== 📌 تحديث من Firebase ==================
  void _updateOrdersFromSnapshot(QuerySnapshot snapshot) async {
    try {
      for (var doc in snapshot.docs) {
        final orderData = doc.data() as Map<String, dynamic>;
        if (orderData.isNotEmpty) {
          final order = Order.fromJson(orderData);
          final existingIndex = _orders.indexWhere((o) => o.number == order.number);
          
          if (existingIndex == -1) {
            // طلب جديد من Firebase
            final orderId = await DBHelper.insertOrder(order);
            order.id = orderId;
            _orders.add(order);
          } else {
            // تحديث طلب موجود
            final existingOrder = _orders[existingIndex];
            existingOrder.done = order.done;
            existingOrder.total = order.total;
            existingOrder.items = order.items;
            existingOrder.notes = order.notes;
            await DBHelper.updateOrder(existingOrder);
          }
        }
      }

      _updateOrderCounter();
      notifyListeners();
    } catch (e) {
      debugPrint("⚠️ خطأ في تحديث الطلبات من Firebase: $e");
    }
  }

  // ================== 📌 مزامنة الطلبات المعلقة ==================
  Future<void> _syncPendingOrders() async {
    if (_pendingSyncOrders.isEmpty) return;

    final List<Order> syncedOrders = [];
    final List<Order> failedOrders = [];

    for (var order in _pendingSyncOrders) {
      try {
        await _firestore
            .collection("orders")
            .doc(order.number.toString())
            .set(order.toJson(), SetOptions(merge: true));

        syncedOrders.add(order);
      } catch (e) {
        debugPrint("⚠️ فشل مزامنة الطلب ${order.number}: $e");
        failedOrders.add(order);
      }
    }

    _pendingSyncOrders
      ..removeWhere((o) => syncedOrders.contains(o))
      ..addAll(failedOrders); // إعادة الطلبات الفاشلة للمحاولة لاحقاً

    if (syncedOrders.isNotEmpty) {
      debugPrint("✅ تمت مزامنة ${syncedOrders.length} طلب بنجاح مع Firebase");
    }
  }

  // ================== 📌 حذف كل الطلبات ==================
  Future<void> clearAllOrders() async {
    try {
      // حذف من Firebase
      final batch = _firestore.batch();
      final snapshot = await _firestore.collection("orders").get();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // حذف محلي
      _orders.clear();
      _pendingSyncOrders.clear();
      _orderCounter = 1;
      
      await DBHelper.clearOrders();
      notifyListeners();
      
    } catch (e) {
      debugPrint("⚠️ خطأ عند حذف الطلبات: $e");
      rethrow;
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
    try {
      final order = getOrderByNumber(number);
      if (order == null) return;

      order.done = done;
      notifyListeners();

      // تحديث محلي
      await DBHelper.updateOrder(order);

      // محاولة المزامنة مع Firebase
      try {
        await _firestore
            .collection("orders")
            .doc(number.toString())
            .update({'done': done});
      } catch (e) {
        debugPrint("⚠️ فشل مزامنة حالة الطلب: $e");
        if (!_pendingSyncOrders.contains(order)) {
          _pendingSyncOrders.add(order);
        }
      }
    } catch (e) {
      debugPrint("⚠️ خطأ عند تحديث حالة الطلب: $e");
      rethrow;
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