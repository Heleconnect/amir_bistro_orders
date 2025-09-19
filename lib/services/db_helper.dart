import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/item.dart';
import '../models/category.dart';
import '../models/note.dart';
import '../models/order.dart' as app_models; // ✅ Alias حتى ما يتعارض مع Firestore

class DBHelper {
  static Database? _db;
  static const int _version = 3; // 🚀 رفعنا نسخة DB عشان نضيف number
  static const String _dbName = 'bistro.db';

  // 📌 أسماء الجداول كثوابت
  static const String tableCategories = "categories";
  static const String tableItems = "items";
  static const String tableNotes = "notes";
  static const String tableOrders = "orders";
  static const String tableOrderItems = "order_items";

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableCategories(
        id TEXT PRIMARY KEY,
        name TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableItems(
        id TEXT PRIMARY KEY,
        name TEXT,
        price REAL,
        categoryId TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableNotes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        content TEXT,
        orderId INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number INTEGER, -- ✅ رقم الطلب
        total REAL,
        done INTEGER,
        createdAt INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableOrderItems(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER,
        itemId TEXT,
        quantity INTEGER,
        notes TEXT
      )
    ''');

    // ✅ فهارس
    await db.execute("CREATE INDEX idx_items_categoryId ON $tableItems(categoryId)");
    await db.execute("CREATE INDEX idx_order_items_orderId ON $tableOrderItems(orderId)");
    await db.execute("CREATE INDEX idx_notes_orderId ON $tableNotes(orderId)");

    print("✅ Database & Tables Created Successfully with Indexes");
  }

  // 🔄 تحديثات مستقبلية (Migration)
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      // إعادة تسمية الجدول القديم
      await db.execute("ALTER TABLE $tableOrders RENAME TO temp_orders");

      // إنشاء جدول جديد مع العمود number
      await db.execute('''
        CREATE TABLE $tableOrders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          number INTEGER,
          total REAL,
          done INTEGER,
          createdAt INTEGER
        )
      ''');

      // نسخ البيانات القديمة
      final oldOrders = await db.query("temp_orders");
      for (var order in oldOrders) {
        final createdAtValue = order['createdAt'];
        int createdAtInt;

        if (createdAtValue is int) {
          createdAtInt = createdAtValue;
        } else if (createdAtValue is String) {
          createdAtInt = DateTime.tryParse(createdAtValue)?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch;
        } else {
          createdAtInt = DateTime.now().millisecondsSinceEpoch;
        }

        await db.insert(tableOrders, {
          'id': order['id'],
          'number': order['id'], // ✅ نخلي الرقم يساوي id القديم كحل مبدئي
          'total': order['total'],
          'done': order['done'],
          'createdAt': createdAtInt,
        });
      }

      await db.execute("DROP TABLE temp_orders");
    }
  }

  // ================== 📌 CATEGORIES ==================
  static Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(
      tableCategories,
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query(tableCategories);
    return maps.map((m) => Category.fromMap(m)).toList();
  }

  static Future<int> deleteCategory(String id) async {
    final db = await database;
    return await db.delete(tableCategories, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      tableCategories,
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  // ================== 📌 ITEMS ==================
  static Future<int> insertItem(Item item) async {
    final db = await database;
    return await db.insert(
      tableItems,
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Item>> getItemsByCategory(String categoryId) async {
    final db = await database;
    final maps = await db.query(
      tableItems,
      where: 'categoryId = ?',
      whereArgs: [categoryId],
    );
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  static Future<List<Item>> getAllItems() async {
    final db = await database;
    final maps = await db.query(tableItems);
    return maps.map((m) => Item.fromMap(m)).toList();
  }

  static Future<int> deleteItem(String id) async {
    final db = await database;
    return await db.delete(tableItems, where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> updateItem(Item item) async {
    final db = await database;
    return await db.update(
      tableItems,
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  // ================== 📌 NOTES ==================
  static Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert(
      tableNotes,
      note.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Note>> getNotesByOrder(int orderId) async {
    final db = await database;
    final maps = await db.query(
      tableNotes,
      where: 'orderId = ?',
      whereArgs: [orderId],
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  static Future<List<Note>> getAllNotes() async {
    final db = await database;
    final maps = await db.query(tableNotes, orderBy: 'id DESC');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  static Future<int> updateNote(Note note) async {
    final db = await database;
    return await db.update(
      tableNotes,
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  static Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete(tableNotes, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearNotes() async {
    final db = await database;
    await db.delete(tableNotes);
  }

  // ================== 📌 ORDERS ==================
  static Future<int> insertOrder(app_models.Order order) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final orderId = await txn.insert(
        tableOrders,
        {
          'number': order.number, // ✅ رقم الطلب
          'total': order.total,
          'done': order.done ? 1 : 0,
          'createdAt': order.createdAt.millisecondsSinceEpoch,
        },
      );

      for (var oi in order.items) {
        await txn.insert(tableOrderItems, {
          'orderId': orderId,
          'itemId': oi.item.id,
          'quantity': oi.quantity,
          'notes': jsonEncode(oi.notes),
        });
      }

      return orderId;
    });
  }

  static Future<List<app_models.Order>> getOrders() async {
    final db = await database;

    final orderMaps = await db.query(tableOrders, orderBy: 'id DESC');
    List<app_models.Order> orders = [];

    for (var map in orderMaps) {
      final orderId = map['id'] as int;

      final itemMaps = await db.rawQuery('''
        SELECT oi.quantity, oi.notes, i.id as itemId, i.name, i.price, i.categoryId
        FROM $tableOrderItems oi
        JOIN $tableItems i ON oi.itemId = i.id
        WHERE oi.orderId = ?
      ''', [orderId]);

      final items = itemMaps.map((m) {
        return app_models.OrderItem(
          item: Item(
            id: m['itemId'] as String,
            name: m['name'] as String,
            price: (m['price'] as num).toDouble(),
            categoryId: m['categoryId'] as String,
          ),
          quantity: m['quantity'] as int,
          notes: (jsonDecode(m['notes'] as String) as List).cast<String>(),
        );
      }).toList();

      orders.add(app_models.Order(
        id: orderId,
        number: (map['number'] as int?) ?? orderId, // ✅ fallback إذا null
        items: items,
        total: (map['total'] as num).toDouble(),
        done: (map['done'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      ));
    }

    return orders;
  }

  static Future<int> updateOrder(app_models.Order order) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      final result = await txn.update(
        tableOrders,
        {
          'number': order.number,
          'total': order.total,
          'done': order.done ? 1 : 0,
          'createdAt': order.createdAt.millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [order.id],
      );

      await txn.delete(tableOrderItems, where: 'orderId = ?', whereArgs: [order.id]);

      for (var oi in order.items) {
        await txn.insert(tableOrderItems, {
          'orderId': order.id,
          'itemId': oi.item.id,
          'quantity': oi.quantity,
          'notes': jsonEncode(oi.notes),
        });
      }

      return result;
    });
  }

  static Future<int> deleteOrder(int id) async {
    final db = await database;

    return await db.transaction<int>((txn) async {
      await txn.delete(tableOrderItems, where: 'orderId = ?', whereArgs: [id]);
      return await txn.delete(tableOrders, where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<void> clearOrders() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(tableOrderItems);
      await txn.delete(tableOrders);
    });
  }
}