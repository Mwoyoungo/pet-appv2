import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'transport_tracking_screen.dart';

class TransportSearchingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const TransportSearchingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<TransportSearchingScreen> createState() =>
      _TransportSearchingScreenState();
}

class _TransportSearchingScreenState extends State<TransportSearchingScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final AnimationController _dotCtrl;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  StreamSubscription<DocumentSnapshot>? _bookingSub;
  Timer? _timeout;
  bool _navigated = false;
  String _broadcastStatus = '';

  @override
  void initState() {
    super.initState();

    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _dotCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringScale = Tween(
      begin: 1.0,
      end: 2.8,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringOpacity = Tween(
      begin: 0.6,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen(_onBookingUpdate);

    _timeout = Timer(const Duration(minutes: 3), () {
      if (!_navigated && mounted) _cancelSearch(timedOut: true);
    });
  }

  void _onBookingUpdate(DocumentSnapshot snap) {
    if (!snap.exists || _navigated) return;
    final data = snap.data() as Map<String, dynamic>;
    final status = data['status'] as String?;
    final broadcastStatus = data['broadcastStatus'] as String? ?? '';

    if (broadcastStatus != _broadcastStatus && mounted) {
      setState(() => _broadcastStatus = broadcastStatus);
    }

    if (status == 'accepted' && !_navigated) {
      _navigated = true;
      _bookingSub?.cancel();
      _timeout?.cancel();
      if (!mounted) return;
      final providerId = data['providerId'] as String? ?? '';
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TransportTrackingScreen(
            bookingId: widget.bookingId,
            providerId: providerId,
            bookingData: {
              ...widget.bookingData,
              'status': 'accepted',
              'providerId': providerId,
            },
          ),
        ),
      );
    }

    if (status == 'cancelled' && !_navigated) {
      _navigated = true;
      _bookingSub?.cancel();
      _timeout?.cancel();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _cancelSearch({bool timedOut = false}) async {
    if (_navigated) return;
    _navigated = true;
    _bookingSub?.cancel();
    _timeout?.cancel();
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': 'cancelled', 'isBroadcast': false});
    if (!mounted) return;
    if (timedOut) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No drivers available right now. Try again shortly.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _bookingSub?.cancel();
    _timeout?.cancel();
    _ringCtrl.dispose();
    _dotCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pricing = widget.bookingData['pricing'] as Map<String, dynamic>?;
    final fare = (pricing?['customerPays'] as num?)?.toDouble() ?? 0.0;
    final distanceKm =
        (widget.bookingData['distanceKm'] as num?)?.toDouble() ?? 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _cancelSearch();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: Stack(
          children: [
            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: GestureDetector(
                    onTap: _cancelSearch,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Centre content ───────────────────────────────────────────
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pulse ring + truck icon
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _ringCtrl,
                          builder: (_, __) => Transform.scale(
                            scale: _ringScale.value,
                            child: Container(
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary.withValues(
                                  alpha: _ringOpacity.value * 0.45,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.local_shipping_rounded,
                            color: Color(0xFF0F172A),
                            size: 34,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Finding your driver',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Matching you with nearby transport drivers',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Bounce dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      3,
                      (i) => _BounceDot(delay: i * 200),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Status pill
                  if (_broadcastStatus.isNotEmpty)
                    _StatusPill(status: _broadcastStatus, isDark: isDark),

                  const SizedBox(height: 24),

                  // Trip summary pill
                  _TripSummaryPill(
                    fare: fare,
                    distanceKm: distanceKm,
                    durationText:
                        widget.bookingData['durationText'] as String? ?? '',
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            // ── Cancel button ────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: TextButton(
                    onPressed: _cancelSearch,
                    child: Text(
                      'Cancel search',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bounce dot ────────────────────────────────────────────────────────────────

class _BounceDot extends StatefulWidget {
  final int delay;
  const _BounceDot({required this.delay});

  @override
  State<_BounceDot> createState() => _BounceDotState();
}

class _BounceDotState extends State<_BounceDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _anim = Tween(
      begin: 0.0,
      end: -7.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Transform.translate(
      offset: Offset(0, _anim.value),
      child: Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
      ),
    ),
  );
}

// ── Status pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  final String status;
  final bool isDark;
  const _StatusPill({required this.status, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final (icon, text, color) = switch (status) {
      'notified' => (
        Icons.notifications_active_rounded,
        'Driver notified nearby',
        AppColors.success,
      ),
      'no_providers_online' => (
        Icons.wifi_off_rounded,
        'No drivers online right now',
        AppColors.error,
      ),
      'no_providers_nearby' => (
        Icons.location_off_rounded,
        'No drivers within range',
        AppColors.error,
      ),
      _ => (
        Icons.access_time_rounded,
        'Reaching drivers…',
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trip summary pill ─────────────────────────────────────────────────────────

class _TripSummaryPill extends StatelessWidget {
  final double fare;
  final double distanceKm;
  final String durationText;
  final bool isDark;

  const _TripSummaryPill({
    required this.fare,
    required this.distanceKm,
    required this.durationText,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillChip(
            icon: Icons.payments_rounded,
            value: 'R${fare.toStringAsFixed(0)}',
            isDark: isDark,
          ),
          _divider(isDark),
          _PillChip(
            icon: Icons.straighten_rounded,
            value: '${distanceKm.toStringAsFixed(1)} km',
            isDark: isDark,
          ),
          if (durationText.isNotEmpty) ...[
            _divider(isDark),
            _PillChip(
              icon: Icons.access_time_rounded,
              value: durationText,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
    width: 1,
    height: 24,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: isDark ? AppColors.borderDark : AppColors.borderLight,
  );
}

class _PillChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool isDark;
  const _PillChip({
    required this.icon,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: AppColors.primary),
      const SizedBox(width: 6),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
      ),
    ],
  );
}
