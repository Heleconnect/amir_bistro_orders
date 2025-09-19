import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../models/order.dart' as app_models;
import '../providers/items_provider.dart';
import '../providers/orders_provider.dart';
import '../providers/settings_provider.dart';
import '../services/printing_service.dart';

class AddOrderSearchScreenAnimated extends StatefulWidget {
  static const routeName = '/add-order-search-animated';

  const AddOrderSearchScreenAnimated({super.key});

  @override
  State<AddOrderSearchScreenAnimated> createState() =>
      _AddOrderSearchScreenAnimatedState();
}

class _AddOrderSearchScreenAnimatedState
    extends State<AddOrderSearchScreenAnimated>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final List<app_models.OrderItem> _orderItems = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Item> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    _filteredItems = itemsProvider.items;
  }

  void _searchItems(String query) {
    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    setState(() {
      if (query.isEmpty) {
        _filteredItems = itemsProvider.items;
      } else {
        _filteredItems = itemsProvider.items
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.id.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _addItem(Item item) {
    final orderItem = app_models.OrderItem(item: item, quantity: 1);
    _orderItems.add(orderItem);
    _listKey.currentState?.insertItem(
      _orderItems.length - 1,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _removeItem(int index) {
    final removedItem = _orderItems.removeAt(index);
    _listKey.currentState?.removeItem(
      index,
      (context, animation) =>
          _buildOrderItemTile(removedItem, animation, removed: true),
      duration: const Duration(milliseconds: 300),
    );
  }

  void _clearAllItems() {
    final count = _orderItems.length;
    for (var i = count - 1; i >= 0; i--) {
      _removeItem(i);
    }
  }

  Future<void> _saveOrder() async {
    if (_orderItems.isEmpty) return;

    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
    final settingsProvider =
        Provider.of<SettingsProvider>(context, listen: false);

    final order = app_models.Order(
      items: _orderItems,
      total: _orderItems.fold(
          0.0, (sum, e) => sum + e.item.price * e.quantity),
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
      "restaurantName": settingsProvider.restaurantName,
      "restaurantAddress": settingsProvider.restaurantAddress,
    };

    final printer = PrintingService(settings: settingsProvider);
    await printer.ensurePrinterAndPrint(kitchenInvoice, customerInvoice);

    setState(() => _orderItems.clear());
  }

  Widget _buildOrderItemTile(app_models.OrderItem orderItem,
      Animation<double> animation,
      {bool removed = false}) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: removed ? Curves.easeInBack : Curves.easeOutBack,
    );

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: curvedAnimation,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              title: Text(orderItem.item.name),
              subtitle: Text(
                "${orderItem.item.formattedPrice} ×${orderItem.quantity}",
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: "حذف الصنف",
                onPressed: () {
                  final index = _orderItems.indexOf(orderItem);
                  if (index >= 0) _removeItem(index);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = Provider.of<SettingsProvider>(context).currency;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("إضافة طلب (بحث مباشر)")),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "ابحث عن صنف...",
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchItems('');
                          },
                        )
                      : null,
                ),
                onChanged: _searchItems,
              ),
            ),
            Expanded(
              child: _filteredItems.isEmpty
                  ? const Center(
                      child: Text(
                        "لا توجد أصناف مطابقة",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredItems.length,
                      itemBuilder: (ctx, i) {
                        final item = _filteredItems[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            leading:
                                const Icon(Icons.fastfood, color: Colors.indigo),
                            title: Text(item.name),
                            subtitle: Text(item.formattedPrice),
                            trailing: IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: Colors.green),
                              tooltip: "إضافة للطلب",
                              onPressed: () => _addItem(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: AnimatedList(
                      key: _listKey,
                      initialItemCount: _orderItems.length,
                      itemBuilder: (ctx, index, animation) =>
                          _buildOrderItemTile(_orderItems[index], animation),
                    ),
                  ),
                  if (_orderItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: OutlinedButton.icon(
                        onPressed: _clearAllItems,
                        icon: const Icon(Icons.delete_forever,
                            color: Colors.red),
                        label: const Text("حذف الكل"),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton.icon(
                onPressed: _saveOrder,
                icon: const Icon(Icons.save),
                label: Text(
                  "حفظ وطباعة الطلب (${_orderItems.fold(0.0, (sum, e) => sum + e.item.price * e.quantity).toStringAsFixed(2)} $currency)",
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}