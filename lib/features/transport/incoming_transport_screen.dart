import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'active_transport_screen.dart';

class IncomingTransportScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const IncomingTransportScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<IncomingTransportScreen> createState() =>
      _IncomingTransportScreenState();
}

class _IncomingTransportScreenState extends State<IncomingTransportScreen>
    with SingleTickerProviderStateMixin {
  static const _timerSeconds = 90;
  int _remaining = _timerSeconds;
  bool _responding = false;
  Timer? _countdown;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseScale = Tween(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _decline(expired: true);
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _timerColor {
    if (_remaining > 60) return AppColors.success;
    if (_remaining > 30) return const Color(0xFFFF9800);
    return AppColors.error;
  }

  Future<void> _accept() async {
    if (_responding) return;
    setState(() => _responding = true);
    _countdown?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _responding = false);
      return;
    }

    final bookingRef = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(bookingRef);
        if (!snap.exists) throw Exception('booking_not_found');
        if (snap.data()!['status'] != 'pending') {
          throw Exception('already_taken');
        }
        tx.update(bookingRef, {
          'status': 'accepted',
          'providerId': uid,
          'isBroadcast': false,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      // Seed provider location immediately
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        await FirebaseFirestore.instance
            .collection('provider_locations')
            .doc(uid)
            .set({
              'lat': pos.latitude,
              'lng': pos.longitude,
              'bookingId': widget.bookingId,
              'isAvailable': false,
              'updatedAt': FieldValue.serverTimestamp(),
            });
      } catch (_) {
        await FirebaseFirestore.instance
            .collection('provider_locations')
            .doc(uid)
            .set({
              'bookingId': widget.bookingId,
              'isAvailable': false,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('already_taken')
          ? 'Job already taken by another driver.'
          : 'Could not accept job. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
      Navigator.of(context).pop();
      return;
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ActiveTransportScreen(
          bookingId: widget.bookingId,
          bookingData: widget.bookingData,
        ),
      ),
    );
  }

  Future<void> _decline({bool expired = false}) async {
    if (_responding) return;
    setState(() => _responding = true);
    _countdown?.cancel();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({
          if (uid != null) 'declinedBy': FieldValue.arrayUnion([uid]),
        });

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pricing = widget.bookingData['pricing'] as Map<String, dynamic>?;
    final fare = (pricing?['customerPays'] as num?)?.toDouble() ?? 0.0;
    final distanceKm =
        (widget.bookingData['distanceKm'] as num?)?.toDouble() ?? 0.0;
    final pickupAddress =
        widget.bookingData['pickupAddress'] as String? ?? 'Pickup';
    final destAddress =
        widget.bookingData['destinationAddress'] as String? ?? 'Destination';
    final durationText = widget.bookingData['durationText'] as String? ?? '';

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ─────────────────────────────────────────────
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseScale,
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.45),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.local_shipping_rounded,
                          color: Color(0xFF0F172A),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New transport job!',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km · ${durationText.isNotEmpty ? durationText : "pet transport"}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _TimerCircle(
                      remaining: _remaining,
                      total: _timerSeconds,
                      color: _timerColor,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Earnings card ───────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "You'll earn",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              'R${fare.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'R8/km · R10 base',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(
                                  0xFF0F172A,
                                ).withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.payments_rounded,
                        color: Color(0x550F172A),
                        size: 52,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── Trip details ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    children: [
                      _TripRow(
                        dot: AppColors.success,
                        label: 'Pickup',
                        value: pickupAddress,
                        isDark: isDark,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 6,
                          top: 2,
                          bottom: 2,
                        ),
                        child: Column(
                          children: List.generate(
                            3,
                            (_) => Container(
                              width: 2,
                              height: 4,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color:
                                  (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight)
                                      .withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      _TripRow(
                        dot: AppColors.error,
                        label: 'Drop-off',
                        value: destAddress,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Action buttons ──────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _responding ? null : _decline,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(
                            color: AppColors.error,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _responding ? null : _accept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _responding
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : Text(
                                'Accept — R${fare.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Timer circle ──────────────────────────────────────────────────────────────

class _TimerCircle extends StatelessWidget {
  final int remaining;
  final int total;
  final Color color;
  const _TimerCircle({
    required this.remaining,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 52,
    height: 52,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CircularProgressIndicator(
          value: remaining / total,
          strokeWidth: 3,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation(color),
        ),
        Text(
          '$remaining',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}

// ── Trip row ──────────────────────────────────────────────────────────────────

class _TripRow extends StatelessWidget {
  final Color dot;
  final String label;
  final String value;
  final bool isDark;
  const _TripRow({
    required this.dot,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}
