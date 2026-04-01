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
  bool _streamConnected = false;

  @override
  AsyncValue<User?> build() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _connectStreamUser(user);
    }
    return AsyncValue.data(user);
  }

  Future<void> _connectStreamUser(User firebaseUser) async {
    if (_streamConnected) return;
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getStreamToken');
      final result = await callable.call();
      final token = result.data['token'] as String;

      await streamClient.connectUser(
        stream.User(
          id: firebaseUser.uid,
          extraData: {'name': firebaseUser.displayName ?? firebaseUser.email ?? 'User'},
        ),
        token,
      );
      _streamConnected = true;

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
      debugPrint('Stream connect error: $e');
    }
  }

  Future<void> _disconnectStreamUser(String uid) async {
    if (!_streamConnected) return;
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
      _streamConnected = false;
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
        final displayName = user.displayName ??
            user.email?.split('@').first ??
            'User';
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
      state = AsyncValue.data(cred.user);
      if (cred.user != null) {
        await _ensureFirestoreDoc(cred.user!);
        await _connectStreamUser(cred.user!);
      }
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
      state = AsyncValue.data(cred.user);
      if (cred.user != null) {
        await _ensureFirestoreDoc(cred.user!);
        await _connectStreamUser(cred.user!);
      }
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
