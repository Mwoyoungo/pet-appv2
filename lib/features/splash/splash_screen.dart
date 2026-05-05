import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/core/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key, required this.onComplete});
  final void Function({required bool isFirstTime}) onComplete;

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  ProviderSubscription<AsyncValue<User?>>? _authSub;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _ctrl,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
          ),
        );

    _ctrl.forward();

    // Navigate after animation — but wait for auth provider (Firebase + Stream)
    // to fully connect before navigating to home screen.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;

      // Check authProvider which includes Firebase + Stream connection
      final authAsync = ref.read(authProvider);

      if (authAsync.hasValue) {
        // Auth (including Stream) already resolved — navigate immediately.
        debugPrint('Splash: Auth ready, user=${authAsync.value?.uid}');
        widget.onComplete(isFirstTime: authAsync.value == null);
      } else if (authAsync.isLoading) {
        // Auth still loading (connecting to Stream) — wait for completion.
        debugPrint('Splash: Auth loading, waiting...');
        _authSub = ref.listenManual(authProvider, (_, next) {
          if (next.hasValue && mounted) {
            debugPrint('Splash: Auth now ready, navigating...');
            _authSub?.close();
            _authSub = null;
            widget.onComplete(isFirstTime: next.value == null);
          } else if (next.hasError && mounted) {
            debugPrint('Splash: Auth error, navigating anyway...');
            _authSub?.close();
            _authSub = null;
            // Even with error, let user in (chat can retry)
            widget.onComplete(isFirstTime: next.value == null);
          }
        });
      } else {
        // Auth error or no user
        debugPrint('Splash: Auth error or no user');
        widget.onComplete(isFirstTime: true);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.close();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181d33),
      body: ResponsiveContainer(
        child: Container(
          color: const Color(0xFF181d33),
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Text(
                  'Pet App',
                  style: GoogleFonts.inter(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
