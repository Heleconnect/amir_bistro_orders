class Item {
  final String id;
  final String name;
  final double price;
  final String categoryId;

  Item({
    required this.id,
    required this.name,
    required this.price,
    required this.categoryId,
  });

  // ✅ JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'categoryId': categoryId,
  };

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'غير معروف').toString(),
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      categoryId: (json['categoryId'] ?? '').toString(),
    );
  }

  // ✅ SQLite Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'price': price,
    'categoryId': categoryId,
  };

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'غير معروف').toString(),
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      categoryId: (map['categoryId'] ?? '').toString(),
    );
  }

  // ✅ عرض السعر بالعملة
  String formattedPrice(String currency) =>
      "${price.toStringAsFixed(2)} $currency";

  @override
  String toString() =>
      "Item(id: $id, name: $name, price: $price, categoryId: $categoryId)";
}