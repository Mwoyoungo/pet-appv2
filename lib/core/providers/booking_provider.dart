import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pet_app/core/models/booking_model.dart';
import 'package:pet_app/core/providers/auth_provider.dart';

final _db = FirebaseFirestore.instance;

// ── Stream of current user's bookings ───────────────────────────────────────
final bookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  return _db
      .collection('bookings')
      .where('userId', isEqualTo: user.uid)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(BookingModel.fromFirestore).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
});

// ── Booking actions notifier ─────────────────────────────────────────────────
class BookingNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<String> createBooking(BookingModel booking) async {
    state = const AsyncValue.loading();
    try {
      final ref = await _db.collection('bookings').add(booking.toFirestore());
      state = const AsyncValue.data(null);
      return ref.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateChannelId(String bookingId, String channelId) async {
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'channelId': channelId,
      });
    } catch (e) {
      // Non-fatal — booking is already saved
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    state = const AsyncValue.loading();
    try {
      await _db.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.name,
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final bookingNotifierProvider =
    NotifierProvider<BookingNotifier, AsyncValue<void>>(BookingNotifier.new);
