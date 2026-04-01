import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
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
  late Animation<double> _scaleAnim;
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

    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
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

    // Navigate after animation — but wait for auth stream to emit first.
    // Firebase Auth persists sessions; authStateChanges() fires quickly from
    // local cache, but may not have emitted by the time the animation ends on
    // slow devices. Reading currentUserProvider while still loading returns
    // null, causing a false "logged-out" state.
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      final authAsync = ref.read(authStateProvider);
      if (authAsync.hasValue) {
        // Auth already resolved — navigate immediately.
        widget.onComplete(isFirstTime: authAsync.value == null);
      } else {
        // Auth stream still loading — wait for the first emitted value.
        _authSub = ref.listenManual(authStateProvider, (_, next) {
          if (next.hasValue && mounted) {
            _authSub?.close();
            _authSub = null;
            widget.onComplete(isFirstTime: next.value == null);
          }
        });
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
      backgroundColor: AppColors.backgroundDark,
      body: ResponsiveContainer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0f0f1a), Color(0xFF1a1a2e), Color(0xFF16213e)],
            ),
          ),
          child: Stack(
            children: [
              // Background glow blobs
              Positioned(
                top: -80,
                right: -80,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                  ),
                ),
              ),

              // Center content
              Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo
                      ScaleTransition(
                        scale: _scaleAnim,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.5),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.pets_rounded,
                            color: Color(0xFF0F172A),
                            size: 52,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // App name
                      SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          children: [
                            Text(
                              'Pet App',
                              style: GoogleFonts.inter(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your pet deserves the best',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                color: Colors.white.withValues(alpha: 0.5),
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom loading indicator
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Loading...',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
