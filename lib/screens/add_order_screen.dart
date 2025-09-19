import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/items_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/settings_provider.dart';
import '../models/item.dart' as model;
import '../models/order.dart' as app_models; // ✅ alias
import '../services/printing_service.dart';

class AddOrderScreen extends StatefulWidget {
  static const routeName = '/add-order';

  const AddOrderScreen({super.key});

  @override
  State<AddOrderScreen> createState() => _AddOrderScreenState();
}

class _AddOrderScreenState extends State<AddOrderScreen> {
  final List<app_models.OrderItem> _orderItems = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  void _addItem(model.Item item, int quantity, {List<String>? notes}) {
    final orderItem =
        app_models.OrderItem(item: item, quantity: quantity, notes: notes ?? []);
    _orderItems.add(orderItem);
    _listKey.currentState?.insertItem(
      _orderItems.length - 1,
      duration: const Duration(milliseconds: 300),
    );
    setState(() {});
  }

  void _removeItem(int index) {
    final removedItem = _orderItems.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedItem(removedItem, animation, index),
      duration: const Duration(milliseconds: 300),
    );
    setState(() {});
  }

  void _clearAllItems() {
    final count = _orderItems.length;
    for (var i = count - 1; i >= 0; i--) {
      _removeItem(i);
    }
    setState(() {});
  }

  void _updateQuantity(int index, int newQuantity) {
    if (newQuantity <= 0) {
      _removeItem(index);
    } else {
      setState(() {
        _orderItems[index] =
            _orderItems[index].copyWith(quantity: newQuantity);
      });
    }
  }

  double get total =>
      _orderItems.fold(0, (sum, e) => sum + e.item.price * e.quantity);

  int get totalPieces => _orderItems.fold(0, (sum, e) => sum + e.quantity);

  Future<void> _showAddItemDialog() async {
    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);

    model.Item? selectedItem;
    int quantity = 1;
    String note = '';
    String? selectedCategoryId;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('➕ إضافة صنف'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "اختر القسم"),
                value: selectedCategoryId,
                isExpanded: true,
                items: itemsProvider.categories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) {
                  setStateDialog(() {
                    selectedCategoryId = val;
                    selectedItem = null;
                  });
                },
              ),
              const SizedBox(height: 8),
              if (selectedCategoryId != null)
                DropdownButtonFormField<model.Item>(
                  decoration: const InputDecoration(labelText: "اختر الصنف"),
                  value: selectedItem,
                  isExpanded: true,
                  items: itemsProvider.items
                      .where((i) => i.categoryId == selectedCategoryId)
                      .map((i) => DropdownMenuItem(
                          value: i,
                          child: Text(
                              "${i.name} - ${i.price.toStringAsFixed(2)}")))
                      .toList(),
                  onChanged: (val) => setStateDialog(() => selectedItem = val),
                ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: 'الكمية'),
                keyboardType: TextInputType.number,
                onChanged: (val) => quantity = int.tryParse(val) ?? 1,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration:
                    const InputDecoration(labelText: 'ملاحظة (اختياري)'),
                onChanged: (val) => note = val,
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                if (selectedItem != null) {
                  _addItem(selectedItem!, quantity,
                      notes: note.isNotEmpty ? [note] : []);
                }
                Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndPrintOrder() async {
    if (_orderItems.isEmpty) return;

    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    final order = app_models.Order(
      items: _orderItems,
      total: total,
      createdAt: DateTime.now(),
    );

    await ordersProvider.addOrder(order);

    final kitchenInvoice = {
      "id": order.number,
      "items": order.items.map((e) => e.toJson()).toList(),
      "total": order.total,
      "title": "فاتورة المطبخ"
    };

    final customerInvoice = {
      "id": order.number,
      "total": order.total,
      "title": "فاتورة الزبون",
    };

    final printer = PrintingService(settings: settings);
    await printer.ensurePrinterAndPrint(kitchenInvoice, customerInvoice);

    setState(() => _orderItems.clear());
  }

  Widget _buildAnimatedItem(
      app_models.OrderItem item, Animation<double> animation, int index) {
    return SizeTransition(
      sizeFactor: animation,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          title: Text(item.item.name),
          subtitle: item.notes.isNotEmpty ? Text(item.notes.join(", ")) : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.orange),
                onPressed: () => _updateQuantity(index, item.quantity - 1),
              ),
              Text("${item.quantity}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () => _updateQuantity(index, item.quantity + 1),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOrderEmpty = _orderItems.isEmpty;
    final currency = Provider.of<SettingsProvider>(context).currency;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('➕ إضافة طلب جديد')),
        body: Column(
          children: [
            Expanded(
              child: AnimatedList(
                key: _listKey,
                initialItemCount: _orderItems.length,
                itemBuilder: (ctx, index, animation) =>
                    _buildAnimatedItem(_orderItems[index], animation, index),
              ),
            ),
            if (_orderItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "الأصناف: ${_orderItems.length} • القطع: $totalPieces",
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        Text(
                          "الإجمالي: ${total.toStringAsFixed(2)} $currency",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _clearAllItems,
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      label: const Text("حذف الكل"),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 45),
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isOrderEmpty ? null : _saveAndPrintOrder,
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ وطباعة الطلب'),
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddItemDialog,
          tooltip: "إضافة صنف",
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}