import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/items_provider.dart';
import '../providers/settings_provider.dart';
import '../models/category.dart';
import '../models/item.dart';

class CategoriesItemsScreen extends StatelessWidget {
  static const routeName = '/categories-items';

  const CategoriesItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("📦 إدارة الأصناف والأقسام"),
            bottom: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.category), text: "الأقسام"),
                Tab(icon: Icon(Icons.fastfood), text: "الأصناف"),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              _CategoriesTab(),
              _ItemsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================== 🗂️ تبويب الأقسام ======================
class _CategoriesTab extends StatelessWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context) {
    final itemsProvider = Provider.of<ItemsProvider>(context);
    final categories = itemsProvider.categories;

    return Column(
      children: [
        Expanded(
          child: categories.isEmpty
              ? const Center(child: Text("لا توجد أقسام بعد"))
              : ListView.builder(
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) {
                    final category = categories[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading:
                            const Icon(Icons.category, color: Colors.blue),
                        title: Text(category.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.orange),
                              onPressed: () => _showCategoryDialog(
                                context,
                                itemsProvider,
                                category: category,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  color: Colors.red),
                              onPressed: () {
                                itemsProvider.deleteCategory(category.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => _showCategoryDialog(context, itemsProvider,
                category: null),
            icon: const Icon(Icons.add),
            label: const Text("إضافة قسم جديد"),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
        ),
      ],
    );
  }

  Future<void> _showCategoryDialog(
    BuildContext context,
    ItemsProvider provider, {
    Category? category,
  }) async {
    final controller = TextEditingController(text: category?.name ?? "");

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(category == null ? "➕ إضافة قسم" : "✏️ تعديل القسم"),
        content: TextField(
          controller: controller,
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
              if (controller.text.trim().isEmpty) return;

              if (category == null) {
                provider.addCategory(Category(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: controller.text.trim(),
                ));
              } else {
                provider.updateCategory(Category(
                  id: category.id,
                  name: controller.text.trim(),
                ));
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save),
            label: const Text("حفظ"),
          ),
        ],
      ),
    );
  }
}

// ====================== 🍔 تبويب الأصناف ======================
class _ItemsTab extends StatelessWidget {
  const _ItemsTab();

  @override
  Widget build(BuildContext context) {
    final itemsProvider = Provider.of<ItemsProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final items = itemsProvider.items;
    final categories = itemsProvider.categories;

    return Column(
      children: [
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text("لا توجد أصناف بعد"))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final item = items[i];
                    final category = categories.firstWhere(
                      (c) => c.id == item.categoryId,
                      orElse: () =>
                          Category(id: "?", name: "غير معروف"),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.fastfood,
                            color: Colors.green),
                        title: Text(item.name),
                        subtitle: Text(
                            "${item.price.toStringAsFixed(2)} ${settings.currency} • قسم: ${category.name}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  color: Colors.orange),
                              onPressed: () => _showItemDialog(
                                context,
                                itemsProvider,
                                item: item,
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
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () {
              if (categories.isEmpty) return;
              _showItemDialog(context, itemsProvider, item: null);
            },
            icon: const Icon(Icons.add),
            label: const Text("إضافة صنف جديد"),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50)),
          ),
        ),
      ],
    );
  }

  Future<void> _showItemDialog(
    BuildContext context,
    ItemsProvider provider, {
    Item? item,
  }) async {
    final nameController = TextEditingController(text: item?.name ?? "");
    final priceController =
        TextEditingController(text: item?.price.toString() ?? "");
    String? selectedCategoryId = item?.categoryId;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(item == null ? "➕ إضافة صنف" : "✏️ تعديل الصنف"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "اسم الصنف",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: "السعر",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: "القسم",
                  border: OutlineInputBorder(),
                ),
                items: provider.categories.map((c) {
                  return DropdownMenuItem(
                      value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) => selectedCategoryId = val,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  double.tryParse(priceController.text) == null ||
                  selectedCategoryId == null) {
                return;
              }

              if (item == null) {
                provider.addItem(Item(
                  id: DateTime.now()
                      .millisecondsSinceEpoch
                      .toString(),
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text),
                  categoryId: selectedCategoryId!,
                ));
              } else {
                provider.updateItem(Item(
                  id: item.id,
                  name: nameController.text.trim(),
                  price: double.parse(priceController.text),
                  categoryId: selectedCategoryId!,
                ));
              }
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.save),
            label: const Text("حفظ"),
          ),
        ],
      ),
    );
  }
}