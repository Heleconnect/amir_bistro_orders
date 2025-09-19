import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../services/printing_service.dart';
import '../models/order.dart' as app_models; // ✅ alias

// ✅ Enum للفلترة
enum OrderFilter { all, done, notDone }

class AllOrdersScreen extends StatefulWidget {
  static const routeName = '/all-orders';

  const AllOrdersScreen({super.key});

  @override
  State<AllOrdersScreen> createState() => _AllOrdersScreenState();
}

class _AllOrdersScreenState extends State<AllOrdersScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  OrderFilter filter = OrderFilter.all;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final currency = settings.currency;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📋 جميع الطلبات'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: searchController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'ابحث برقم الطلب...',
                  filled: true,
                  fillColor: Colors.grey[100],
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              searchController.clear();
                              searchQuery = "";
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
            ),
            if (settings.completedEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonFormField<OrderFilter>(
                  value: filter,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "فلترة الطلبات",
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: OrderFilter.all, child: Text("جميع الطلبات")),
                    DropdownMenuItem(
                        value: OrderFilter.done,
                        child: Text("الطلبات المنجزة ✅")),
                    DropdownMenuItem(
                        value: OrderFilter.notDone,
                        child: Text("الطلبات غير المنجزة ⏳")),
                  ],
                  onChanged: (val) {
                    setState(() {
                      filter = val!;
                    });
                  },
                ),
              ),
            if (settings.completedEnabled) const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("orders")
                    .orderBy("number", descending: true)
                    .snapshots(),
                builder: (ctx, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "لا توجد طلبات ❌",
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  final orders = snapshot.data!.docs.map((doc) {
                    return app_models.Order.fromJson(
                        doc.data() as Map<String, dynamic>);
                  }).where((order) {
                    if (searchQuery.isNotEmpty &&
                        !order.number.toString().contains(searchQuery.trim())) {
                      return false;
                    }
                    if (settings.completedEnabled) {
                      if (filter == OrderFilter.done) return order.done;
                      if (filter == OrderFilter.notDone) return !order.done;
                    }
                    return true;
                  }).toList();

                  if (orders.isEmpty) {
                    return const Center(
                      child: Text("لا توجد طلبات مطابقة ❌"),
                    );
                  }

                  return ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      return Card(
                        key: ValueKey(order.number),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 3,
                        color: order.done
                            ? Colors.green.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          title: Row(
                            children: [
                              Text(
                                'طلب رقم: ${order.number}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (order.done)
                                const Padding(
                                  padding: EdgeInsets.only(right: 6),
                                  child: Icon(Icons.check_circle,
                                      color: Colors.green),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...order.items.map((app_models.OrderItem oi) {
                                final notes = oi.notes.isNotEmpty
                                    ? " (${oi.notes.join(', ')})"
                                    : "";
                                final subtotal =
                                    oi.item.price * oi.quantity;
                                return Text(
                                  "${oi.item.name} ×${oi.quantity}$notes - ${subtotal.toStringAsFixed(2)} $currency",
                                  style: const TextStyle(fontSize: 14),
                                );
                              }),
                              const SizedBox(height: 4),
                              Text(
                                'الإجمالي: ${order.total.toStringAsFixed(2)} $currency',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.print,
                                    color: Colors.green),
                                tooltip: 'طباعة مباشرة',
                                onPressed: () async {
                                  final printer =
                                      PrintingService(settings: settings);

                                  final kitchenInvoice = {
                                    "id": order.number,
                                    "items": order.items
                                        .map((e) => e.toJson())
                                        .toList(),
                                    "total": order.total,
                                    "title": "فاتورة المطبخ"
                                  };

                                  final customerInvoice = {
                                    "id": order.number,
                                    "total": order.total,
                                    "title": "فاتورة الزبون",
                                    "restaurantName": settings.restaurantName,
                                    "restaurantAddress":
                                        settings.restaurantAddress,
                                  };

                                  await printer.ensurePrinterAndPrint(
                                      kitchenInvoice, customerInvoice);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                tooltip: 'حذف الطلب',
                                onPressed: () async {
                                  await FirebaseFirestore.instance
                                      .collection("orders")
                                      .doc(order.number.toString())
                                      .delete();
                                },
                              ),
                              if (settings.completedEnabled)
                                Checkbox(
                                  value: order.done,
                                  activeColor:
                                      Theme.of(context).primaryColor,
                                  onChanged: (val) async {
                                    if (val != null) {
                                      await FirebaseFirestore.instance
                                          .collection("orders")
                                          .doc(order.number.toString())
                                          .update({"done": val});
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}