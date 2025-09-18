class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  // ✅ Map for SQLite
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
  };

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: (map['id'] ?? '').toString(),
      name: (map['name'] ?? 'غير معروف').toString(),
    );
  }

  // ✅ JSON for Firebase
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'غير معروف').toString(),
    );
  }

  @override
  String toString() => "Category(id: $id, name: $name)";
}