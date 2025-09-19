import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../models/item.dart';
import '../models/category.dart';

class ItemsScreen extends StatefulWidget {
  static const routeName = '/items';

  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ItemsProvider>(context, listen: false).loadData();
  }

  void _showItemDialog({Item? item, required String categoryId}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController =
        TextEditingController(text: item?.price.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                item == null ? Icons.add_box : Icons.edit,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(item == null ? "إضافة صنف جديد" : "تعديل الصنف"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "اسم الصنف",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "السعر",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    double.tryParse(priceController.text) == null) {
                  return; // ما في SnackBar، بس منوقف التنفيذ
                }

                final newItem = Item(
                  id: item?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text),
                  categoryId: categoryId,
                );

                final provider =
                    Provider.of<ItemsProvider>(context, listen: false);
                if (item == null) {
                  provider.addItem(newItem);
                } else {
                  provider.updateItem(newItem);
                }
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.save),
              label: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(
                category == null ? Icons.add : Icons.edit,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(category == null ? "إضافة قسم جديد" : "تعديل القسم"),
            ],
          ),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: "اسم القسم",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                  return; // بدون SnackBar
                }

                final newCategory = Category(
                  id: category?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                );

                final provider =
                    Provider.of<ItemsProvider>(context, listen: false);
                if (category == null) {
                  provider.addCategory(newCategory);
                } else {
                  provider.updateCategory(newCategory);
                }
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.save),
              label: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsProvider = Provider.of<ItemsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("📦 إدارة الأصناف والأقسام"),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.white),
              tooltip: "إضافة قسم",
              onPressed: () => _showCategoryDialog(),
            ),
          ],
        ),
        body: itemsProvider.categories.isEmpty
            ? const Center(
                child: Text("لا توجد أقسام بعد، أضف قسم جديد ✨"),
              )
            : ListView.builder(
                itemCount: itemsProvider.categories.length,
                itemBuilder: (ctx, i) {
                  final category = itemsProvider.categories[i];
                  final items = itemsProvider.itemsByCategory(category.id);

                  return Card(
                    margin: const EdgeInsets.all(8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ExpansionTile(
                      leading:
                          const Icon(Icons.category, color: Colors.orange),
                      title: Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      children: [
                        if (items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text("لا توجد أصناف في هذا القسم"),
                          ),
                        ...items.map((item) {
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text(item.formattedPrice),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () => _showItemDialog(
                                    item: item,
                                    categoryId: category.id,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    itemsProvider.deleteItem(item.id);
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                        ListTile(
                          leading: const Icon(Icons.add, color: Colors.blue),
                          title: const Text("إضافة صنف جديد"),
                          onTap: () => _showItemDialog(
                            categoryId: category.id,
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}