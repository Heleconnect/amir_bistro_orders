import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/orders_provider.dart';
import '../providers/settings_provider.dart';

class OrderTile extends StatelessWidget {
  final Order order;

  const OrderTile({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        title: Text('طلب #${order.number}'),
        subtitle: Text(
          'الإجمالي: ${order.total.toStringAsFixed(2)} ${settings.currency}',
        ),
        trailing: Checkbox(
          value: order.done,
          onChanged: (val) {
            if (val != null) {
              ordersProvider.setOrderDone(order.number, val);
            }
          },
        ),
        onTap: () {
          // ممكن تضيف هنا فتح تفاصيل الطلب (Dialog أو Screen جديدة)
        },
      ),
    );
  }
}