import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/item.dart';
import '../providers/items_provider.dart';

class SearchItemsScreen extends StatefulWidget {
  static const routeName = '/search-items';

  const SearchItemsScreen({super.key});

  @override
  State<SearchItemsScreen> createState() => _SearchItemsScreenState();
}

class _SearchItemsScreenState extends State<SearchItemsScreen> {
  final TextEditingController _searchController = TextEditingController();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("بحث عن صنف"),
        ),
        body: Column(
          children: [
            // 🔎 مربع البحث
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "ابحث بالاسم أو الكود...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
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
            const Divider(),

            // 📋 عرض النتائج
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
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      leading: const Icon(Icons.fastfood,
                          color: Colors.indigo),
                      title: Text(item.name),
                      subtitle: Text(
                          "السعر: ${item.formattedPrice} | القسم: ${item.categoryId}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.green),
                        tooltip: "إضافة إلى الطلب",
                        onPressed: () {
                          Navigator.pop(context, item);
                        },
                      ),
                    ),
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