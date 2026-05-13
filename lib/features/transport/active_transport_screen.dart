import 'dart:async';
import 'dart:math' show min, max;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pet_app/core/theme/app_colors.dart';

// ── Stage model ───────────────────────────────────────────────────────────────

class _Stage {
  final String status;
  final IconData icon;
  final String title;
  final String subtitle;
  const _Stage(this.status, this.icon, this.title, this.subtitle);
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ActiveTransportScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ActiveTransportScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<ActiveTransportScreen> createState() => _ActiveTransportScreenState();
}

class _ActiveTransportScreenState extends State<ActiveTransportScreen> {
  static const _stages = [
    _Stage(
      'accepted',
      Icons.check_circle_outline_rounded,
      'Accepted',
      'Head to the pickup location',
    ),
    _Stage(
      'on_the_way',
      Icons.directions_car_rounded,
      'En Route',
      "On your way to pick up",
    ),
    _Stage(
      'arrived',
      Icons.location_on_rounded,
      'Arrived',
      'At pickup — load the pet',
    ),
    _Stage(
      'in_transit',
      Icons.pets_rounded,
      'In Transit',
      'Heading to destination',
    ),
    _Stage(
      'delivered',
      Icons.check_circle_rounded,
      'Delivered',
      'Job complete!',
    ),
  ];

  int _currentStage = 0;
  bool _updating = false;
  bool _sharingStopped = false;

  // Map
  final _mapCompleter = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  bool _boundsSet = false;

  // Positions
  double _providerLat = 0;
  double _providerLng = 0;
  double _customerLat = 0;
  double _customerLng = 0;

  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<DocumentSnapshot>? _bookingSub;

  @override
  void initState() {
    super.initState();
    _customerLat = (widget.bookingData['pickupLat'] as num?)?.toDouble() ?? 0;
    _customerLng = (widget.bookingData['pickupLng'] as num?)?.toDouble() ?? 0;
    _startGps();
    _startBookingListener();
  }

  Future<void> _startGps() async {
    // Ensure permission is granted
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever ||
        perm == LocationPermission.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission required for live tracking.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Seed with an immediate fix
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _providerLat = pos.latitude;
        _providerLng = pos.longitude;
      });
      await _writeLocation(pos.latitude, pos.longitude);
      _updateMarkers();
    } catch (e) {
      debugPrint('GPS seed error: $e');
    }

    // Continuous stream — fires every 10 m moved
    _gpsSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((pos) {
          if (!mounted) return;
          setState(() {
            _providerLat = pos.latitude;
            _providerLng = pos.longitude;
          });
          _writeLocation(pos.latitude, pos.longitude);
          _updateMarkers();
        }, onError: (e) => debugPrint('GPS stream error: $e'));
  }

  Future<void> _writeLocation(double lat, double lng) async {
    if (_sharingStopped) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('provider_locations')
          .doc(uid)
          .set({
            'lat': lat,
            'lng': lng,
            'bookingId': widget.bookingId,
            'isAvailable': false,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {}
  }

  void _updateMarkers() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor = isDark
        ? BitmapDescriptor.hueYellow
        : BitmapDescriptor.hueOrange;
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('provider'),
          position: LatLng(_providerLat, _providerLng),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          infoWindow: const InfoWindow(title: 'You'),
        ),
        if (_customerLat != 0)
          Marker(
            markerId: const MarkerId('customer'),
            position: LatLng(_customerLat, _customerLng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: const InfoWindow(title: 'Pickup'),
          ),
      };
    });
    if (!_boundsSet && _providerLat != 0 && _customerLat != 0) {
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_boundsSet) return;
    _boundsSet = true;
    _mapCompleter.future.then((ctrl) {
      ctrl.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              min(_providerLat, _customerLat),
              min(_providerLng, _customerLng),
            ),
            northeast: LatLng(
              max(_providerLat, _customerLat),
              max(_providerLng, _customerLng),
            ),
          ),
          80,
        ),
      );
    });
  }

  void _startBookingListener() {
    _bookingSub = FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final status =
              (snap.data() as Map<String, dynamic>)['status'] as String?;
          if (status == 'cancelled') {
            _stopSharing();
            _bookingSub?.cancel();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Customer cancelled the request.'),
                backgroundColor: AppColors.error,
              ),
            );
            Navigator.of(context).popUntil((r) => r.isFirst);
          }
        });
  }

  Future<void> _stopSharing() async {
    if (_sharingStopped) return;
    _sharingStopped = true;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('provider_locations')
          .doc(uid)
          .update({
            'bookingId': FieldValue.delete(),
            'isAvailable': true,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  Future<void> _advanceStage() async {
    if (_updating || _currentStage >= _stages.length - 1) return;
    setState(() => _updating = true);
    final next = _stages[_currentStage + 1];

    // When arriving at pickup, update the destination marker to the drop-off
    if (next.status == 'in_transit') {
      final destLat = (widget.bookingData['destLat'] as num?)?.toDouble() ?? 0;
      final destLng = (widget.bookingData['destLng'] as num?)?.toDouble() ?? 0;
      if (destLat != 0) {
        setState(() {
          _customerLat = destLat;
          _customerLng = destLng;
          _boundsSet = false;
        });
        _updateMarkers();
      }
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .update({
            'status': next.status,
            'updatedAt': FieldValue.serverTimestamp(),
          });
      setState(() {
        _currentStage++;
        _updating = false;
      });
    } catch (_) {
      if (mounted) setState(() => _updating = false);
      return;
    }

    if (_currentStage == _stages.length - 1) {
      await _stopSharing();
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Job complete! Well done."),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _cancelJob() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Cancel job?',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure? The customer will be notified.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _stopSharing();
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(widget.bookingId)
        .update({'status': 'cancelled'});
    if (!mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _bookingSub?.cancel();
    _stopSharing();
    _mapCompleter.future.then((c) => c.dispose()).catchError((_) {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stage = _stages[_currentStage];
    final isDone = _currentStage == _stages.length - 1;
    final mapH = MediaQuery.of(context).size.height * 0.42;
    final pricing = widget.bookingData['pricing'] as Map<String, dynamic>?;
    final fare = (pricing?['providerEarns'] as num?)?.toDouble() ?? 0.0;

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
                    target: _providerLat != 0
                        ? LatLng(_providerLat, _providerLng)
                        : const LatLng(-26.1076, 28.0567),
                    zoom: 14,
                  ),
                  markers: _markers,
                  myLocationEnabled: false,
                  zoomControlsEnabled: false,
                  onMapCreated: (ctrl) {
                    if (!_mapCompleter.isCompleted) {
                      _mapCompleter.complete(ctrl);
                    }
                    if (_providerLat != 0 && _customerLat != 0) _fitBounds();
                  },
                ),
                // Status pill
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
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
                            'Job active — ${stage.title}',
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
              ],
            ),
          ),

          // ── CONTROLS ──────────────────────────────────────────────────
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Stage card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  stage.icon,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      stage.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimaryLight,
                                      ),
                                    ),
                                    Text(
                                      stage.subtitle,
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
                              Text(
                                'R${fare.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Progress dots
                          Row(
                            children: List.generate(_stages.length, (i) {
                              final active = i == _currentStage;
                              final done = i < _currentStage;
                              return Expanded(
                                child: Container(
                                  height: 4,
                                  margin: EdgeInsets.only(
                                    right: i < _stages.length - 1 ? 4 : 0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: done || active
                                        ? AppColors.primary
                                        : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.borderLight),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Destination summary
                    _DestCard(
                      pickupAddress:
                          widget.bookingData['pickupAddress'] as String? ??
                          'Pickup',
                      destAddress:
                          widget.bookingData['destinationAddress'] as String? ??
                          'Destination',
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),

                    // Advance / complete button
                    ElevatedButton(
                      onPressed: (_updating || isDone) ? null : _advanceStage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDone
                            ? AppColors.success
                            : AppColors.primary,
                        foregroundColor: isDone
                            ? Colors.white
                            : const Color(0xFF0F172A),
                        elevation: 0,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _updating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0F172A),
                              ),
                            )
                          : Text(
                              isDone ? 'Job Complete ✓' : _nextButtonLabel(),
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),

                    TextButton(
                      onPressed: _cancelJob,
                      child: Text(
                        'Cancel job',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),

                    SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _nextButtonLabel() {
    if (_currentStage >= _stages.length - 1) return 'Complete';
    final next = _stages[_currentStage + 1];
    return switch (next.status) {
      'on_the_way' => 'Start Trip',
      'arrived' => 'Arrived at Pickup',
      'in_transit' => 'Pet On Board',
      'delivered' => 'Mark Delivered',
      _ => 'Next Step',
    };
  }
}

// ── Destination card ──────────────────────────────────────────────────────────

class _DestCard extends StatelessWidget {
  final String pickupAddress;
  final String destAddress;
  final bool isDark;
  const _DestCard({
    required this.pickupAddress,
    required this.destAddress,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    ),
    child: Column(
      children: [
        _Row(dot: AppColors.success, label: pickupAddress, isDark: isDark),
        Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Column(
            children: List.generate(
              3,
              (_) => Container(
                width: 2,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 2),
                color: (isDark ? AppColors.borderDark : AppColors.borderLight)
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        _Row(dot: AppColors.error, label: destAddress, isDark: isDark),
      ],
    ),
  );
}

class _Row extends StatelessWidget {
  final Color dot;
  final String label;
  final bool isDark;
  const _Row({required this.dot, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
