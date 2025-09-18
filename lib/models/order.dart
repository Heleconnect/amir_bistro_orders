import 'item.dart';

class OrderItem {
  Item item;
  int quantity;
  List<String> notes;

  OrderItem({
    required this.item,
    required this.quantity,
    List<String>? notes,
  }) : notes = notes ?? [];

  Map<String, dynamic> toJson() => {
    'item': item.toJson(),
    'quantity': quantity,
    'notes': notes,
  };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      item: json['item'] != null
          ? Item.fromJson(json['item'])
          : Item(id: "0", name: "غير معروف", price: 0.0, categoryId: "0"),
      quantity: (json['quantity'] ?? 0) as int,
      notes: List<String>.from(json['notes'] ?? []),
    );
  }
}

class Order {
  int? id; // SQLite AUTO INCREMENT
  List<OrderItem> items;
  double total;
  bool done;
  DateTime createdAt;

  Order({
    this.id,
    required this.items,
    required this.total,
    this.done = false,
    required this.createdAt,
  });

  int get number => id ?? 0;

  // ✅ SQLite
  Map<String, dynamic> toMap() => {
    'total': total,
    'done': done ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Order.fromMap(Map<String, dynamic> map, List<OrderItem> items) {
    return Order(
      id: map['id'] as int?,
      total: (map['total'] ?? 0).toDouble(),
      done: (map['done'] ?? 0) == 1,
      items: items,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // ✅ JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'total': total,
    'done': done,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int?,
      total: (json['total'] is num) ? (json['total'] as num).toDouble() : 0.0,
      done: json['done'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      items: (json['items'] as List<dynamic>? ?? [])
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }

  void addItem(OrderItem orderItem) {
    items.add(orderItem);
    total += orderItem.item.price * orderItem.quantity;
  }

  void removeItem(OrderItem orderItem) {
    if (items.contains(orderItem)) {
      total -= orderItem.item.price * orderItem.quantity;
      items.remove(orderItem);
    }
  }
}