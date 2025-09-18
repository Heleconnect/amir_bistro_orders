// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';

// Providers
import 'providers/items_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';

// Screens
import 'screens/home_screen.dart';
import 'screens/add_order_screen.dart';
import 'screens/all_orders_screen.dart';
import 'screens/items_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/connect_printer_screen.dart';
import 'screens/add_order_search_screen_animated.dart';

// Utils
import 'utils/app_theme.dart';
import 'utils/permissions_helper.dart'; // الملف الموجود عندك

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // تحميل الإعدادات قبل تشغيل التطبيق
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  runApp(AmirBistroApp(settingsProvider: settingsProvider));
}

class AmirBistroApp extends StatelessWidget {
  final SettingsProvider settingsProvider;

  const AmirBistroApp({
    super.key,
    required this.settingsProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemsProvider()),
        
        // ✅ استخدم FutureProvider لتهيئة OrdersProvider بشكل صحيح
        FutureProvider<OrdersProvider>(
          create: (_) async {
            final ordersProvider = OrdersProvider(settings: settingsProvider);
            await ordersProvider.loadOrders();
            return ordersProvider;
          },
          initialData: OrdersProvider(settings: settingsProvider),
        ),
        
        ChangeNotifierProvider(create: (_) => NotesProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
      ],
      child: FutureBuilder<bool>(
        // ✅ استخدم FutureBuilder للتحقق من الأذونات
        future: PermissionsHelper.ensurePermissions(),
        builder: (context, snapshot) {
          // أثناء التحميل
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            );
          }
          
          // بعد اكتمال التحميل
          final permissionsGranted = snapshot.data ?? false;
          
          return MaterialApp(
            title: 'Amir Bistro Orders',
            debugShowCheckedModeBanner: false,
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,

            builder: (context, child) {
              return ScrollConfiguration(
                behavior: _NoGlowScrollBehavior(),
                child: child!,
              );
            },

            // ✅ استخدم نتيجة FutureBuilder
            home: permissionsGranted
                ? const HomeScreen()
                : const PermissionsErrorScreen(),

            routes: {
              AddOrderScreen.routeName: (_) => const AddOrderScreen(),
              AllOrdersScreen.routeName: (_) => const AllOrdersScreen(),
              ItemsScreen.routeName: (_) => const ItemsScreen(),
              NotesScreen.routeName: (_) => const NotesScreen(),
              SettingsScreen.routeName: (_) => const SettingsScreen(),
              ConnectPrinterScreen.routeName: (_) => const ConnectPrinterScreen(),
              AddOrderSearchScreenAnimated.routeName: (_) =>
                  const AddOrderSearchScreenAnimated(),
            },

            onGenerateRoute: (settings) {
              Widget? page;
              switch (settings.name) {
                case AddOrderScreen.routeName:
                  page = const AddOrderScreen();
                  break;
                case AllOrdersScreen.routeName:
                  page = const AllOrdersScreen();
                  break;
                case ItemsScreen.routeName:
                  page = const ItemsScreen();
                  break;
                case NotesScreen.routeName:
                  page = const NotesScreen();
                  break;
                case SettingsScreen.routeName:
                  page = const SettingsScreen();
                  break;
                case ConnectPrinterScreen.routeName:
                  page = const ConnectPrinterScreen();
                  break;
                case AddOrderSearchScreenAnimated.routeName:
                  page = const AddOrderSearchScreenAnimated();
                  break;
              }
              if (page == null) return null;

              return PageRouteBuilder(
                settings: settings,
                transitionDuration: const Duration(milliseconds: 240),
                reverseTransitionDuration: const Duration(milliseconds: 200),
                pageBuilder: (_, animation, secondaryAnimation) => page!,
                transitionsBuilder: (_, animation, secondary, child) {
                  final offsetTween = Tween<Offset>(
                    begin: const Offset(0, 0.04),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic));

                  final fadeTween = Tween<double>(begin: 0, end: 1)
                      .chain(CurveTween(curve: Curves.easeOut));

                  return SlideTransition(
                    position: animation.drive(offsetTween),
                    child: FadeTransition(
                      opacity: animation.drive(fadeTween),
                      child: child,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// إزالة توهّج الـ overscroll
class _NoGlowScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context,
      Widget child,
      ScrollableDetails details,
      ) {
    return child;
  }
}

/// شاشة بديلة إذا المستخدم رفض الأذونات
class PermissionsErrorScreen extends StatelessWidget {
  const PermissionsErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("الأذونات مطلوبة")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "التطبيق يحتاج أذونات أساسية (Bluetooth + تخزين)\nحتى يعمل بشكل صحيح.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text("فتح الإعدادات"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}