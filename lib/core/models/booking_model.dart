import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, confirmed, completed, cancelled }

class BookingModel {
  const BookingModel({
    required this.id,
    required this.userId,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    required this.serviceName,
    required this.date,
    required this.timeSlot,
    required this.price,
    required this.status,
    required this.createdAt,
    this.notes,
    this.providerImageUrl,
    this.channelId,
  });

  final String id;
  final String userId;
  final String providerId;
  final String providerName;
  final String serviceType;
  final String serviceName;
  final DateTime date;
  final String timeSlot;
  final double price;
  final BookingStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? providerImageUrl;
  final String? channelId;

  factory BookingModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return BookingModel(
      id: doc.id,
      userId: d['userId'] ?? '',
      providerId: d['providerId'] ?? '',
      providerName: d['providerName'] ?? '',
      serviceType: d['serviceType'] ?? '',
      serviceName: d['serviceName'] ?? '',
      date: (d['date'] as Timestamp).toDate(),
      timeSlot: d['timeSlot'] ?? '',
      price: (d['price'] as num).toDouble(),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => BookingStatus.pending,
      ),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      notes: d['notes'],
      providerImageUrl: d['providerImageUrl'],
      channelId: d['channelId'],
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'providerId': providerId,
    'providerName': providerName,
    'serviceType': serviceType,
    'serviceName': serviceName,
    'date': Timestamp.fromDate(date),
    'timeSlot': timeSlot,
    'price': price,
    'status': status.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'notes': notes,
    'providerImageUrl': providerImageUrl,
    'channelId': channelId,
  };

  BookingModel copyWith({
    BookingStatus? status,
    String? notes,
    String? channelId,
  }) => BookingModel(
    id: id,
    userId: userId,
    providerId: providerId,
    providerName: providerName,
    serviceType: serviceType,
    serviceName: serviceName,
    date: date,
    timeSlot: timeSlot,
    price: price,
    status: status ?? this.status,
    createdAt: createdAt,
    notes: notes ?? this.notes,
    providerImageUrl: providerImageUrl,
    channelId: channelId ?? this.channelId,
  );
}
