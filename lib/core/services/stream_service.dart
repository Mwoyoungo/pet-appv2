import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:pet_app/main.dart' show streamClient;

class StreamService {
  StreamService._();

  // ── Ensure the other party exists in Stream before creating a channel ──────
  static Future<void> _ensureStreamUser(String uid) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('ensureStreamUser');
      await callable.call({'uid': uid});
    } catch (e) {
      debugPrint('ensureStreamUser error: $e');
    }
  }

  // ── Create a booking channel and send the auto-message ───────────────────
  static Future<Channel?> createBookingChannel({
    required String bookingId,
    required String userId,
    required String providerId,
    required String providerName,
    required String serviceName,
    required String date,
    required String timeSlot,
  }) async {
    try {
      // Make sure both users exist in Stream
      await _ensureStreamUser(providerId);

      final channelId = 'booking_$bookingId';
      final channel = streamClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': 'Booking: $serviceName',
          'members': [userId, providerId],
        },
      );

      await channel.watch();

      // Add provider as a member
      await channel.addMembers([providerId]);

      // Send auto booking message
      await channel.sendMessage(
        Message(
          text: '📋 New booking: $serviceName on $date at $timeSlot. '
              'Provider: $providerName. Please confirm!',
        ),
      );

      return channel;
    } catch (e) {
      debugPrint('createBookingChannel error: $e');
      return null;
    }
  }

  // ── Get or create a direct chat channel between two users ────────────────
  static Future<Channel?> getOrCreateDirectChannel({
    required String currentUserId,
    required String otherUserId,
    required String otherUserName,
  }) async {
    try {
      await _ensureStreamUser(otherUserId);

      // Use sorted IDs to get a consistent channel ID
      final ids = [currentUserId, otherUserId]..sort();
      final channelId = 'direct_${ids[0]}_${ids[1]}';

      final channel = streamClient.channel(
        'messaging',
        id: channelId,
        extraData: {
          'name': otherUserName,
          'members': [currentUserId, otherUserId],
        },
      );

      await channel.watch();
      await channel.addMembers([otherUserId]);

      return channel;
    } catch (e) {
      debugPrint('getOrCreateDirectChannel error: $e');
      return null;
    }
  }

  // ── Get an existing channel by ID ─────────────────────────────────────────
  static Future<Channel?> getChannel(String channelId) async {
    try {
      final channel = streamClient.channel('messaging', id: channelId);
      await channel.watch();
      return channel;
    } catch (e) {
      debugPrint('getChannel error: $e');
      return null;
    }
  }
}
