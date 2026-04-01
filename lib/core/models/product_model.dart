import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String storeId;
  final String name;
  final String? description;
  final String? imageUrl;
  final double price;
  final String category;
  final bool inStock;

  const ProductModel({
    required this.id,
    required this.storeId,
    required this.name,
    this.description,
    this.imageUrl,
    required this.price,
    required this.category,
    this.inStock = true,
  });

  factory ProductModel.fromFirestore(DocumentSnapshot doc, String storeId) {
    final d = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      storeId: storeId,
      name: d['name'] as String? ?? '',
      description: d['description'] as String?,
      imageUrl: d['imageUrl'] as String?,
      price: (d['price'] as num?)?.toDouble() ?? 0.0,
      category: d['category'] as String? ?? 'General',
      inStock: d['inStock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'category': category,
        'inStock': inStock,
      };

  ProductModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? category,
    bool? inStock,
  }) =>
      ProductModel(
        id: id,
        storeId: storeId,
        name: name ?? this.name,
        description: description ?? this.description,
        imageUrl: imageUrl ?? this.imageUrl,
        price: price ?? this.price,
        category: category ?? this.category,
        inStock: inStock ?? this.inStock,
      );
}
