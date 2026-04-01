import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.phone,
    this.address,
    this.petName,
    this.petBreed,
    this.petAge,
    this.petType,
    this.isProvider = false,
    this.providerStatus,
    this.providerBio,
    this.providerRate,
    this.providerServiceTypes = const [],
    this.providerPrices = const {},
    this.isAdmin = false,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? phone;
  final String? address;
  final String? petName;
  final String? petBreed;
  final String? petAge;
  final String? petType;
  final bool isProvider;
  /// 'pending' | 'approved' | 'rejected' — null for non-providers
  final String? providerStatus;
  final String? providerBio;
  final String? providerRate;
  final List<String> providerServiceTypes;
  final Map<String, int> providerPrices;
  final bool isAdmin;

  bool get isPendingApproval => isProvider && providerStatus == 'pending';
  bool get isApprovedProvider => isProvider && providerStatus == 'approved';
  bool get isRejectedProvider => isProvider && providerStatus == 'rejected';

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      displayName: d['displayName'] ?? '',
      email: d['email'] ?? '',
      photoUrl: d['photoUrl'],
      phone: d['phone'],
      address: d['address'],
      petName: d['petName'],
      petBreed: d['petBreed'],
      petAge: d['petAge'],
      petType: d['petType'],
      isProvider: d['isProvider'] ?? false,
      providerStatus: d['providerStatus'] as String?,
      providerBio: d['providerBio'],
      providerRate: d['providerRate'],
      providerServiceTypes: List<String>.from(d['providerServiceTypes'] ?? []),
      providerPrices: Map<String, int>.from(
        (d['providerPrices'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
      ),
      isAdmin: d['isAdmin'] ?? false,
    );
  }

  factory UserProfile.fromAuth(User user) => UserProfile(
    uid: user.uid,
    displayName:
        user.displayName ?? user.email?.split('@').first ?? 'Pet Lover',
    email: user.email ?? '',
    photoUrl: user.photoURL,
  );

  Map<String, dynamic> toFirestore() => {
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
    'phone': phone,
    'address': address,
    'petName': petName,
    'petBreed': petBreed,
    'petAge': petAge,
    'petType': petType,
    'isProvider': isProvider,
    'providerStatus': providerStatus,
    'providerBio': providerBio,
    'providerRate': providerRate,
    'providerServiceTypes': providerServiceTypes,
    'providerPrices': providerPrices,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? address,
    String? petName,
    String? petBreed,
    String? petAge,
    String? petType,
    String? photoUrl,
    bool? isProvider,
    String? providerStatus,
    String? providerBio,
    String? providerRate,
    List<String>? providerServiceTypes,
    Map<String, int>? providerPrices,
    bool? isAdmin,
  }) => UserProfile(
    uid: uid,
    displayName: displayName ?? this.displayName,
    email: email,
    photoUrl: photoUrl ?? this.photoUrl,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    petName: petName ?? this.petName,
    petBreed: petBreed ?? this.petBreed,
    petAge: petAge ?? this.petAge,
    petType: petType ?? this.petType,
    isProvider: isProvider ?? this.isProvider,
    providerStatus: providerStatus ?? this.providerStatus,
    providerBio: providerBio ?? this.providerBio,
    providerRate: providerRate ?? this.providerRate,
    providerServiceTypes: providerServiceTypes ?? this.providerServiceTypes,
    providerPrices: providerPrices ?? this.providerPrices,
    isAdmin: isAdmin ?? this.isAdmin,
  );
}

// ── Provider ─────────────────────────────────────────────────────────────────
final _db = FirebaseFirestore.instance;

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final auth = FirebaseAuth.instance;
  final user = auth.currentUser;
  if (user == null) return const Stream.empty();

  return _db.collection('users').doc(user.uid).snapshots().map((snap) {
    if (!snap.exists) {
      final profile = UserProfile.fromAuth(user);
      snap.reference.set(profile.toFirestore(), SetOptions(merge: true));
      return profile;
    }
    return UserProfile.fromFirestore(snap);
  });
});

// ── Profile update notifier ───────────────────────────────────────────────────
class ProfileNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> updateProfile(UserProfile profile) async {
    state = const AsyncValue.loading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      await _db
          .collection('users')
          .doc(user.uid)
          .set(profile.toFirestore(), SetOptions(merge: true));

      await user.updateDisplayName(profile.displayName);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> toggleProvider(String uid, bool isProvider) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isProvider': isProvider,
        // Clear status when disabling provider role
        if (!isProvider) 'providerStatus': null,
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateProviderInfo(
    String uid, {
    required String bio,
    required List<String> serviceTypes,
    required Map<String, int> prices,
    required String phone,
    required String address,
  }) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isProvider': true,
        'providerStatus': 'pending',
        'providerBio': bio,
        'providerServiceTypes': serviceTypes,
        'providerPrices': prices,
        'phone': phone,
        'address': address,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> approveProvider(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'providerStatus': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> rejectProvider(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({
        'providerStatus': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final profileNotifierProvider =
    NotifierProvider<ProfileNotifier, AsyncValue<void>>(ProfileNotifier.new);
