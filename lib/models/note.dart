class Note {
  final int? id; // AUTO_INCREMENT SQLite
  String content; // خليتها مش final حتى نقدر نعدل
  final int orderId; // الطلب المرتبط بالملاحظة

  Note({
    this.id,
    required this.content,
    required this.orderId,
  });

  // ✅ SQLite Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'orderId': orderId,
      };

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      content: (map['content'] ?? '').toString(),
      orderId: map['orderId'] is int
          ? map['orderId']
          : int.tryParse("${map['orderId']}") ?? 0,
    );
  }

  // ✅ JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'orderId': orderId,
      };

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
      id: json['id'] is int ? json['id'] as int? : int.tryParse("${json['id']}"),
      content: (json['content'] ?? '').toString(),
      orderId: json['orderId'] is int
          ? json['orderId']
          : int.tryParse("${json['orderId']}") ?? 0,
    );
  }

  @override
  String toString() => "Note(id: $id, content: $content, orderId: $orderId)";
}