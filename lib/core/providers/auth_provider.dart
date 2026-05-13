import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart' as stream;
import 'package:pet_app/main.dart' show streamClient;

// ── Auth state stream ────────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ── Current user convenience provider ───────────────────────────────────────
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// ── Auth notifier ────────────────────────────────────────────────────────────
class AuthNotifier extends Notifier<AsyncValue<User?>> {
  @override
  AsyncValue<User?> build() {
    final user = FirebaseAuth.instance.currentUser;
    // If user is logged in, connect to Stream before returning ready state
    if (user != null) {
      // Start connection and update state when done
      _initWithStreamConnection(user);
      return const AsyncValue.loading();
    }
    return AsyncValue.data(user);
  }

  Future<void> _initWithStreamConnection(User firebaseUser) async {
    debugPrint(
      'AuthNotifier: Starting Stream connection for ${firebaseUser.uid}',
    );
    try {
      await _connectStreamUser(firebaseUser);
      debugPrint('AuthNotifier: Stream connection successful');
      // Only set state to data after Stream is connected
      state = AsyncValue.data(firebaseUser);
    } catch (e) {
      debugPrint('AuthNotifier: Stream connection FAILED: $e');
      // Even if Stream fails, allow user into app (they can retry in chat)
      state = AsyncValue.data(firebaseUser);
    }
  }

  Future<void> _connectStreamUser(User firebaseUser) async {
    debugPrint('_connectStreamUser: Starting for ${firebaseUser.uid}');

    // Use actual client state as ground truth — the _streamConnected flag
    // resets on provider rebuild so it cannot be trusted alone.
    final currentStreamUser = streamClient.state.currentUser;
    if (currentStreamUser?.id == firebaseUser.uid) {
      debugPrint(
        '_connectStreamUser: Already connected for user: ${firebaseUser.uid}',
      );
      return;
    }

    // Different user connected — disconnect first
    if (currentStreamUser != null) {
      debugPrint(
        '_connectStreamUser: Disconnecting previous user ${currentStreamUser.id}',
      );
      await _disconnectStreamUser(firebaseUser.uid);
    }

    try {
      debugPrint(
        '_connectStreamUser: Calling getStreamToken Cloud Function...',
      );
      final callable = FirebaseFunctions.instance.httpsCallable(
        'getStreamToken',
      );
      final result = await callable.call();
      final token = result.data['token'] as String;
      debugPrint('_connectStreamUser: Got token, connecting to Stream...');

      await streamClient.connectUser(
        stream.User(
          id: firebaseUser.uid,
          extraData: {
            'name': firebaseUser.displayName ?? firebaseUser.email ?? 'User',
          },
        ),
        token,
      );
      debugPrint('_connectStreamUser: SUCCESS - Connected to Stream');

      // Save FCM token for push notifications (mobile only)
      if (!kIsWeb) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await _saveFcmToken(firebaseUser.uid, fcmToken);
        }
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
          _saveFcmToken(firebaseUser.uid, newToken);
        });
      }
    } catch (e) {
      debugPrint('_connectStreamUser: FAILED with error: $e');
      rethrow;
    }
  }

  Future<void> _disconnectStreamUser(String uid) async {
    // Use actual client state — _streamConnected flag may be stale after rebuild.
    if (streamClient.state.currentUser == null) return;
    try {
      if (!kIsWeb) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmTokens': FieldValue.arrayRemove([fcmToken]),
          });
        }
      }
      await streamClient.disconnectUser();
    } catch (e) {
      debugPrint('Stream disconnect error: $e');
    }
  }

  Future<void> _saveFcmToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Save FCM token error: $e');
    }
  }

  Future<void> _ensureFirestoreDoc(User user) async {
    try {
      final db = FirebaseFirestore.instance;
      final doc = await db.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        final displayName =
            user.displayName ?? user.email?.split('@').first ?? 'User';
        await db.collection('users').doc(user.uid).set({
          'displayName': displayName,
          'email': user.email ?? '',
          'photoUrl': user.photoURL,
          'isProvider': false,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('ensureFirestoreDoc error: $e');
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _ensureFirestoreDoc(cred.user!);
        await _connectStreamUser(cred.user!);
      }
      state = AsyncValue.data(cred.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user != null) {
        await _ensureFirestoreDoc(cred.user!);
        await _connectStreamUser(cred.user!);
      }
      state = AsyncValue.data(cred.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    throw Exception(
      'Google sign-in requires Firebase project configuration. '
      'Add google-services.json (Android) and GoogleService-Info.plist (iOS) first.',
    );
  }

  Future<void> signOut() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _disconnectStreamUser(uid);
    await FirebaseAuth.instance.signOut();
    state = const AsyncValue.data(null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  AuthNotifier.new,
);
