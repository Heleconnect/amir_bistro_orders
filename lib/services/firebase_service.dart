import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_models; // ✅ Alias

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> syncOrder(app_models.Order order) async { // ✅ استخدم alias
    await _firestore.collection('orders').doc(order.id.toString()).set({
      'id': order.id,
      'total': order.total,
      'done': order.done,
      'createdAt': order.createdAt.toIso8601String(),
      'items': order.items.map((oi) => {
        'itemId': oi.item.id,
        'name': oi.item.name,
        'price': oi.item.price,
        'quantity': oi.quantity,
        'notes': oi.notes,
      }).toList()
    });
  }
}