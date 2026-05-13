import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_app/core/theme/app_colors.dart';

class TransportTrackingScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final Map<String, dynamic> bookingData;

  const TransportTrackingScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.bookingData,
  });

  @override
  State<TransportTrackingScreen> createState() =>
      _TransportTrackingScreenState();
}

class _TransportTrackingScreenState extends State<TransportTrackingScreen> {
  final _mapCompleter = Completer<GoogleMapController>();
  Set<Marker> _markers = {};

  // Positions
  double _providerLat = 0;
  double _providerLng = 0;
  double _customerLat = 0;
  double _customerLng = 0;

  String _currentStatus = 'accepted';

  StreamSubscription<DocumentSnapshot>? _locationSub;
  StreamSubscription<DocumentSnapshot>? _bookingSub;

  static const _statusLabels = <String, String>{
    'accepted': 'Driver accepted — heading to you',
    'on_the_way': 'Driver is on the way',
    'arrived': 'Driver has arrived at pickup',
    'in_transit': 'Your pet is on the way',
    'delivered': 'Delivered! 🎉',
    'cancelled': 'Trip cancelled',
  };

  static const _stages = [
    'accepted',
    'on_the_way',
    'arrived',
    'in_transit',
    'delivered',
  ];

  @override
  void initState() {
    super.initState();
    _customerLat =
        (widget.bookingData['pickupLat'] as num?)?.toDouble() ?? 0;
    _customerLng =
        (widget.bookingData['pickupLng'] as num?)?.toDouble() ?? 0;
    _currentStatus =
        widget.bookingData['status'] as String? ?? 'accepted';
    _startProviderLocationListener();
    _startBookingListener();
  }

  void _startProviderLocationListener() {
    _locationSub = FirebaseFirestore.instance
        .collection('provider_locations')
        .doc(widget.providerId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data()!;
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      setState(() {
        _providerLat = lat;
        _providerLng = lng;
      });
      _updateMarkers();
      _animateCameraToProvider();
    });
  }

  void _startBookingListener() {
    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data() as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'accepted';
      if (status != _currentStatus) {
        setState(() => _currentStatus = status);
      }
      if (status == 'cancelled') {
        _locationSub?.cancel();
        _bookingSub?.cancel();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('The driver cancelled the trip.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
      if (status == 'delivered' && mounted) {
        _locationSub?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your pet has been delivered! 🐾'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    });
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        if (_providerLat != 0)
          Marker(
            markerId: const MarkerId('driver'),
            position: LatLng(_providerLat, _providerLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueOrange),
            infoWindow: const InfoWindow(title: 'Driver'),
          ),
        if (_customerLat != 0)
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(_customerLat, _customerLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: const InfoWindow(title: 'Pickup'),
          ),
      };
    });
  }

  void _animateCameraToProvider() {
    if (_providerLat == 0) return;
    _mapCompleter.future.then((ctrl) {
      ctrl.animateCamera(
        CameraUpdate.newLatLng(LatLng(_providerLat, _providerLng)),
      );
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _bookingSub?.cancel();
    _mapCompleter.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  int get _stageIndex {
    final idx = _stages.indexOf(_currentStatus);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pricing = widget.bookingData['pricing'] as Map<String, dynamic>?;
    final fare = (pricing?['customerPays'] as num?)?.toDouble() ?? 0.0;
    final statusLabel =
        _statusLabels[_currentStatus] ?? 'Tracking your driver…';
    final mapH = MediaQuery.of(context).size.height * 0.55;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: Column(
        children: [

          // ── MAP ────────────────────────────────────────────────────────
          SizedBox(
            height: mapH,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _customerLat != 0
                        ? LatLng(_customerLat, _customerLng)
                        : const LatLng(-26.1076, 28.0567),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (ctrl) {
                    if (!_mapCompleter.isCompleted) {
                      _mapCompleter.complete(ctrl);
                    }
                  },
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: AppColors.textPrimaryLight, size: 20),
                    ),
                  ),
                ),

                // Status pill
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            statusLabel,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Driver location loading indicator
                if (_providerLat == 0)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Connecting to driver location…',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── INFO CARD ──────────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Progress stepper
                    _StageStepper(
                      stages: const [
                        'Accepted',
                        'En Route',
                        'Arrived',
                        'In Transit',
                        'Delivered',
                      ],
                      currentIndex: _stageIndex,
                    ),

                    const SizedBox(height: 14),

                    // Trip summary
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoChip(
                            icon: Icons.payments_rounded,
                            label: 'Fare',
                            value: 'R${fare.toStringAsFixed(0)}',
                            isDark: isDark,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          _InfoChip(
                            icon: Icons.straighten_rounded,
                            label: 'Distance',
                            value:
                                '${(widget.bookingData['distanceKm'] as num? ?? 0).toStringAsFixed(1)} km',
                            isDark: isDark,
                          ),
                          Container(
                            width: 1,
                            height: 32,
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          _InfoChip(
                            icon: Icons.access_time_rounded,
                            label: 'Est.',
                            value: widget.bookingData['durationText']
                                    as String? ??
                                '--',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stage stepper ─────────────────────────────────────────────────────────────

class _StageStepper extends StatelessWidget {
  final List<String> stages;
  final int currentIndex;
  const _StageStepper({required this.stages, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stageIdx = i ~/ 2;
          final done = stageIdx < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: done
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          );
        }
        final stageIdx = i ~/ 2;
        final done = stageIdx < currentIndex;
        final active = stageIdx == currentIndex;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: done
                  ? const Icon(Icons.check_rounded,
                      color: Color(0xFF0F172A), size: 12)
                  : active
                      ? Container(
                          margin: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : null,
            ),
            const SizedBox(height: 4),
            Text(
              stages[stageIdx],
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: AppColors.primary, size: 18),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
    ],
  );
}
