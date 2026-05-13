import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:pet_app/features/splash/splash_screen.dart';
import 'package:pet_app/features/onboarding/onboarding_screen.dart';
import 'package:pet_app/features/auth/login_screen.dart';
import 'package:pet_app/features/home/home_screen.dart';
import 'package:pet_app/features/emergency/clinic_detail_screen.dart';
import 'package:pet_app/shared/screens/provider_list_screen.dart';
import 'package:pet_app/features/insurance/pet_insurance_screen.dart';
import 'package:pet_app/features/store/store_list_screen.dart';
import 'package:pet_app/features/store/store_detail_screen.dart';
import 'package:pet_app/features/store/cart_screen.dart';
import 'package:pet_app/features/store/my_store_screen.dart';
import 'package:pet_app/features/booking/booking_screen.dart';
import 'package:pet_app/features/booking/my_bookings_screen.dart';
import 'package:pet_app/features/chat/chat_list_screen.dart';
import 'package:pet_app/features/profile/profile_screen.dart';
import 'package:pet_app/features/providers/provider_profile_screen.dart';
import 'package:pet_app/features/admin/admin_screen.dart';
import 'package:pet_app/features/transport/transport_map_screen.dart';

class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const home = '/';
  static const clinicDetail = '/clinic/:id';
  static const groomersList = '/groomers';
  static const sittersList = '/sitters';
  static const walkersList = '/walkers';
  static const daycareList = '/daycare';
  static const trainersList = '/trainers';
  static const behavioristList = '/behaviorists';
  static const transportList = '/transport';
  static const hydrotherapyList = '/hydrotherapy';
  static const boardingList = '/boarding';
  static const petInsurance = '/pet-insurance';
  static const storeList = '/store-list';
  static const storeDetail = '/store/:storeId';
  static const cart = '/cart';
  static const myStore = '/my-store';
  static const booking = '/booking';
  static const myBookings = '/bookings';
  static const orders = '/orders';
  static const chatList = '/chat';
  static const profile = '/profile';
  static const providerProfile = '/provider/:uid';
  static const admin = '/admin';
}

/// Listens to Firebase auth state and notifies GoRouter to re-evaluate redirects.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable() {
    _sub = FirebaseAuth.instance.authStateChanges().listen(
      (_) => notifyListeners(),
    );
  }
  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authListenable = _AuthListenable();

/// Routes that require a signed-in user.
const _protectedRoutes = {
  AppRoutes.chatList,
  AppRoutes.myBookings,
  AppRoutes.orders,
  AppRoutes.booking,
  AppRoutes.profile,
  AppRoutes.myStore,
  AppRoutes.admin,
};

final appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  refreshListenable: _authListenable,
  redirect: (context, state) {
    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;
    final isProtected =
        _protectedRoutes.contains(loc) || loc.startsWith('/provider/');
    if (isProtected && user == null) return AppRoutes.login;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => SplashScreen(
        onComplete: ({required bool isFirstTime}) {
          if (isFirstTime) {
            context.go(AppRoutes.login);
          } else {
            context.go(AppRoutes.home);
          }
        },
      ),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) =>
          OnboardingScreen(onDone: () => context.go(AppRoutes.login)),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.clinicDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '1';
        return ClinicDetailScreen(clinicId: id);
      },
    ),
    GoRoute(
      path: AppRoutes.groomersList,
      builder: (context, state) => const ProviderListScreen.grooming(),
    ),
    GoRoute(
      path: AppRoutes.sittersList,
      builder: (context, state) => const ProviderListScreen.sitting(),
    ),
    GoRoute(
      path: AppRoutes.walkersList,
      builder: (context, state) => const ProviderListScreen.walking(),
    ),
    GoRoute(
      path: AppRoutes.daycareList,
      builder: (context, state) => const ProviderListScreen.daycare(),
    ),
    GoRoute(
      path: AppRoutes.trainersList,
      builder: (context, state) => const ProviderListScreen.training(),
    ),
    GoRoute(
      path: AppRoutes.behavioristList,
      builder: (context, state) => const ProviderListScreen.behaviorist(),
    ),
    GoRoute(
      path: AppRoutes.transportList,
      builder: (context, state) => const TransportMapScreen(),
    ),
    GoRoute(
      path: AppRoutes.hydrotherapyList,
      builder: (context, state) => const ProviderListScreen.hydrotherapy(),
    ),
    GoRoute(
      path: AppRoutes.boardingList,
      builder: (context, state) => const ProviderListScreen.boarding(),
    ),
    GoRoute(
      path: AppRoutes.petInsurance,
      builder: (context, state) => const PetInsuranceScreen(),
    ),
    GoRoute(
      path: AppRoutes.storeList,
      builder: (context, state) => const StoreListScreen(),
    ),
    GoRoute(
      path: AppRoutes.storeDetail,
      builder: (context, state) {
        final storeId = state.pathParameters['storeId'] ?? '';
        return StoreDetailScreen(storeId: storeId);
      },
    ),
    GoRoute(
      path: AppRoutes.cart,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: AppRoutes.myStore,
      builder: (context, state) => const MyStoreScreen(),
    ),
    GoRoute(
      path: AppRoutes.booking,
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return BookingScreen(
          providerId: extra['providerId'] ?? 'unknown',
          providerName: extra['providerName'] ?? 'Provider',
          serviceType: extra['serviceType'] ?? 'grooming',
          providerImageUrl: extra['providerImageUrl'],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.myBookings,
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.orders,
      builder: (context, state) => const MyBookingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.chatList,
      builder: (context, state) => const ChatListScreen(),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoutes.providerProfile,
      builder: (context, state) {
        final uid = state.pathParameters['uid'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ProviderProfileScreen(
          providerUid: uid,
          serviceType: extra['serviceType'] as String? ?? 'grooming',
        );
      },
    ),
    GoRoute(
      path: AppRoutes.admin,
      builder: (context, state) => const AdminScreen(),
    ),
  ],
);
