import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String ownerId;
  final String name;
  final String? imageUrl;
  final String? description;
  final String address;
  final double rating;
  final int reviewCount;
  final double deliveryFee;
  final String deliveryTime;
  final bool isOpen;
  final double minimumOrder;

  const StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    this.imageUrl,
    this.description,
    required this.address,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.deliveryFee = 0.0,
    this.deliveryTime = '30-45 min',
    this.isOpen = true,
    this.minimumOrder = 0.0,
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      ownerId: d['ownerId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      description: d['description'] as String?,
      address: d['address'] as String? ?? '',
      rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      deliveryFee: (d['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      deliveryTime: d['deliveryTime'] as String? ?? '30-45 min',
      isOpen: d['isOpen'] as bool? ?? true,
      minimumOrder: (d['minimumOrder'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ownerId': ownerId,
        'name': name,
        'imageUrl': imageUrl,
        'description': description,
        'address': address,
        'rating': rating,
        'reviewCount': reviewCount,
        'deliveryFee': deliveryFee,
        'deliveryTime': deliveryTime,
        'isOpen': isOpen,
        'minimumOrder': minimumOrder,
      };

  StoreModel copyWith({
    String? name,
    String? imageUrl,
    String? description,
    String? address,
    double? deliveryFee,
    String? deliveryTime,
    bool? isOpen,
    double? minimumOrder,
  }) =>
      StoreModel(
        id: id,
        ownerId: ownerId,
        name: name ?? this.name,
        imageUrl: imageUrl ?? this.imageUrl,
        description: description ?? this.description,
        address: address ?? this.address,
        rating: rating,
        reviewCount: reviewCount,
        deliveryFee: deliveryFee ?? this.deliveryFee,
        deliveryTime: deliveryTime ?? this.deliveryTime,
        isOpen: isOpen ?? this.isOpen,
        minimumOrder: minimumOrder ?? this.minimumOrder,
      );
}
