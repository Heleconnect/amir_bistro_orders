import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemTile extends StatelessWidget {
  final Item item;
  final VoidCallback onDelete;

  const ItemTile({super.key, required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.name),
      subtitle: Text('${item.price.toStringAsFixed(2)} € - ${item.categoryId}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: onDelete,
      ),
    );
  }
}