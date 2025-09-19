import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/item.dart';
import '../models/category.dart' as app_models;
import '../services/db_helper.dart';

class ItemsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<app_models.Category> _categories = [];
  final List<Item> _items = [];

  final List<app_models.Category> _pendingCategories = [];
  final List<Item> _pendingItems = [];

  List<app_models.Category> get categories => [..._categories];
  List<Item> get items => [..._items];

  ItemsProvider() {
    loadData();

    _firestore.collection("categories").snapshots().listen(_updateCategoriesFromFirebase);
    _firestore.collection("items").snapshots().listen(_updateItemsFromFirebase);

    Timer.periodic(const Duration(seconds: 10), (_) {
      if (_pendingCategories.isNotEmpty || _pendingItems.isNotEmpty) {
        _syncPendingData();
      }
    });
  }

  Future<void> loadData() async {
    final localCategories = await DBHelper.getCategories();
    final localItems = await DBHelper.getAllItems();

    _categories
      ..clear()
      ..addAll(localCategories);
    _items
      ..clear()
      ..addAll(localItems);

    notifyListeners();

    final catsSnapshot = await _firestore.collection("categories").get();
    for (var doc in catsSnapshot.docs) {
      final cat = app_models.Category.fromJson(doc.data());
      if (!_categories.any((c) => c.id == cat.id)) {
        _categories.add(cat);
        await DBHelper.insertCategory(cat);
      }
    }

    final itemsSnapshot = await _firestore.collection("items").get();
    for (var doc in itemsSnapshot.docs) {
      final item = Item.fromJson(doc.data());
      if (!_items.any((i) => i.id == item.id)) {
        _items.add(item);
        await DBHelper.insertItem(item);
      }
    }

    notifyListeners();
  }

  Future<void> addCategory(app_models.Category category) async {
    _categories.add(category);
    notifyListeners();

    await DBHelper.insertCategory(category);

    try {
      await _firestore.collection("categories").doc(category.id).set(category.toJson());
    } catch (_) {
      _pendingCategories.add(category);
    }
  }

  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
    _items.removeWhere((i) => i.categoryId == id);
    notifyListeners();

    await DBHelper.deleteCategory(id);

    try {
      await _firestore.collection("categories").doc(id).delete();
    } catch (_) {}
  }

  Future<void> updateCategory(app_models.Category updated) async {
    final index = _categories.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _categories[index] = updated;
      notifyListeners();

      await DBHelper.updateCategory(updated);

      try {
        await _firestore.collection("categories").doc(updated.id).update(updated.toJson());
      } catch (_) {
        _pendingCategories.add(updated);
      }
    }
  }

  Future<void> addItem(Item item) async {
    _items.add(item);
    notifyListeners();

    await DBHelper.insertItem(item);

    try {
      await _firestore.collection("items").doc(item.id).set(item.toJson());
    } catch (_) {
      _pendingItems.add(item);
    }
  }

  Future<void> removeItem(String id) async {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();

    await DBHelper.deleteItem(id);

    try {
      await _firestore.collection("items").doc(id).delete();
    } catch (_) {}
  }

  /// ✅ alias لحل الخطأ بالشاشات (deleteItem = removeItem)
  Future<void> deleteItem(String id) async {
    return removeItem(id);
  }

  Future<void> updateItem(Item updated) async {
    final index = _items.indexWhere((i) => i.id == updated.id);
    if (index >= 0) {
      _items[index] = updated;
      notifyListeners();

      await DBHelper.updateItem(updated);

      try {
        await _firestore.collection("items").doc(updated.id).update(updated.toJson());
      } catch (_) {
        _pendingItems.add(updated);
      }
    }
  }

  /// ✅ جديد: إرجاع الأصناف حسب القسم
  List<Item> itemsByCategory(String categoryId) {
    return _items.where((i) => i.categoryId == categoryId).toList();
  }

  List<Item> filteredItems(String query) {
    if (query.isEmpty) return _items;
    return _items.where((i) => i.name.toLowerCase().contains(query.toLowerCase())).toList();
  }

  void _updateCategoriesFromFirebase(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      final cat = app_models.Category.fromJson(doc.data() as Map<String, dynamic>);
      final index = _categories.indexWhere((c) => c.id == cat.id);

      if (index >= 0) {
        _categories[index] = cat;
        await DBHelper.updateCategory(cat);
      } else {
        _categories.add(cat);
        await DBHelper.insertCategory(cat);
      }
    }
    notifyListeners();
  }

  void _updateItemsFromFirebase(QuerySnapshot snapshot) async {
    for (var doc in snapshot.docs) {
      final item = Item.fromJson(doc.data() as Map<String, dynamic>);
      final index = _items.indexWhere((i) => i.id == item.id);

      if (index >= 0) {
        _items[index] = item;
        await DBHelper.updateItem(item);
      } else {
        _items.add(item);
        await DBHelper.insertItem(item);
      }
    }
    notifyListeners();
  }

  Future<void> _syncPendingData() async {
    for (var cat in List<app_models.Category>.from(_pendingCategories)) {
      try {
        await _firestore.collection("categories").doc(cat.id).set(cat.toJson());
        _pendingCategories.remove(cat);
      } catch (_) {}
    }

    for (var item in List<Item>.from(_pendingItems)) {
      try {
        await _firestore.collection("items").doc(item.id).set(item.toJson());
        _pendingItems.remove(item);
      } catch (_) {}
    }
  }
}