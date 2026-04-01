import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItemModel {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String? imageUrl;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
        productId: m['productId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        imageUrl: m['imageUrl'] as String?,
      );
}

class StoreOrderModel {
  final String id;
  final String customerId;
  final String storeId;
  final String ownerId;
  final String storeName;
  final List<OrderItemModel> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String deliveryAddress;
  final String status;
  final DateTime createdAt;

  const StoreOrderModel({
    required this.id,
    required this.customerId,
    required this.storeId,
    required this.ownerId,
    required this.storeName,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.deliveryAddress,
    required this.status,
    required this.createdAt,
  });

  factory StoreOrderModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final itemsList = (d['items'] as List<dynamic>? ?? [])
        .map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i)))
        .toList();
    return StoreOrderModel(
      id: doc.id,
      customerId: d['customerId'] as String? ?? '',
      storeId: d['storeId'] as String? ?? '',
      ownerId: d['ownerId'] as String? ?? '',
      storeName: d['storeName'] as String? ?? '',
      items: itemsList,
      subtotal: (d['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      total: (d['total'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: d['deliveryAddress'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Next status the store owner can advance to
  String? get nextStatus {
    switch (status) {
      case 'pending':
        return 'confirmed';
      case 'confirmed':
        return 'preparing';
      case 'preparing':
        return 'delivered';
      default:
        return null;
    }
  }

  String? get nextStatusLabel {
    switch (nextStatus) {
      case 'confirmed':
        return 'Confirm Order';
      case 'preparing':
        return 'Start Preparing';
      case 'delivered':
        return 'Mark Delivered';
      default:
        return null;
    }
  }
}
