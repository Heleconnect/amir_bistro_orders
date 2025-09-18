import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Screens
import 'add_order_screen.dart';
import 'all_orders_screen.dart';
import 'items_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';
import 'add_order_search_screen_animated.dart';

// Providers
import '../providers/settings_provider.dart';

class HomeScreen extends StatelessWidget {
  static const routeName = '/home';

  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    final List<_MenuItem> menuItems = [
      _MenuItem(
        title: '➕ إضافة طلب جديد',
        icon: Icons.add_shopping_cart,
        color: Colors.green,
        route: AddOrderScreen.routeName,
      ),
      _MenuItem(
        title: '📋 جميع الطلبات',
        icon: Icons.list_alt,
        color: Colors.blue,
        route: AllOrdersScreen.routeName,
      ),
      _MenuItem(
        title: '📦 الأقسام والأصناف',
        icon: Icons.category,
        color: Colors.orange,
        route: ItemsScreen.routeName,
      ),
      _MenuItem(
        title: '📝 إدارة الملاحظات',
        icon: Icons.note_alt,
        color: Colors.purple,
        route: NotesScreen.routeName,
      ),
      _MenuItem(
        title: '⚙️ الإعدادات',
        icon: Icons.settings,
        color: Colors.grey,
        route: SettingsScreen.routeName,
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            settings.restaurantName.isNotEmpty
                ? settings.restaurantName
                : "Amir Bistro Orders",
          ),
          centerTitle: true,
          elevation: 4,
        ),
        body: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "اختر عملية:",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (ctx, i) {
                  final item = menuItems[i];
                  return InkWell(
                    onTap: () => Navigator.pushNamed(context, item.route),
                    borderRadius: BorderRadius.circular(20),
                    splashColor: item.color.withOpacity(0.2),
                    child: Card(
                      elevation: 6,
                      shadowColor: item.color.withOpacity(0.3),
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor: item.color.withOpacity(0.15),
                            radius: 34,
                            child: Icon(item.icon, size: 34, color: item.color),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: item.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.search),
          label: const Text('بحث سريع'),
          onPressed: () {
            Navigator.pushNamed(context, AddOrderSearchScreenAnimated.routeName);
          },
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}