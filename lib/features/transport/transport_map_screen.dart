import 'dart:async';
import 'dart:convert';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'transport_searching_screen.dart';

// ── Enums ────────────────────────────────────────────────────────────────────
enum _TransportStep { locating, inputting, routing }

enum _SuggestionTarget { pickup, destination }

const _kMapsApiKey = 'AIzaSyDPPa_AFGCg3LuleMmXEFyXIyw9MA2vQpk';

// Default map center (Sandton, ZA) — used before GPS fix
const _kDefaultCenter = LatLng(-26.1076, 28.0567);

// ── Screen ────────────────────────────────────────────────────────────────────

class TransportMapScreen extends StatefulWidget {
  const TransportMapScreen({super.key});

  @override
  State<TransportMapScreen> createState() => _TransportMapScreenState();
}

class _TransportMapScreenState extends State<TransportMapScreen> {
  final _mapCompleter = Completer<GoogleMapController>();
  final _sheetController = DraggableScrollableController();
  final _pickupCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  Timer? _debounce;

  _TransportStep _step = _TransportStep.locating;
  LatLng? _currentLatLng;
  LatLng? _destLatLng;
  String _pickupAddress = '';
  String _destAddress = '';
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<Map<String, String>> _suggestions = [];
  _SuggestionTarget _suggestionTarget = _SuggestionTarget.destination;
  String? _distanceText;
  String? _durationText;
  double _distanceKm = 0.0;
  double _fareAmount = 0.0;
  bool _loadingRoute = false;
  bool _booking = false;

  @override
  void initState() {
    super.initState();
    _determineLocation();
  }

  @override
  void dispose() {
    _pickupCtrl.dispose();
    _destCtrl.dispose();
    _debounce?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Location ───────────────────────────────────────────────────────────────

  Future<void> _determineLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _step = _TransportStep.inputting);
        _showPermissionDialog();
      }
      return;
    }

    if (permission == LocationPermission.denied) {
      if (mounted) setState(() => _step = _TransportStep.inputting);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final latLng = LatLng(pos.latitude, pos.longitude);

      String address =
          '${pos.latitude.toStringAsFixed(5)}, ${pos.longitude.toStringAsFixed(5)}';
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = [
            p.street,
            p.subLocality,
            p.locality,
          ].where((e) => e != null && e.isNotEmpty).map((e) => e!).toList();
          if (parts.isNotEmpty) address = parts.join(', ');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _currentLatLng = latLng;
        _pickupAddress = address;
        _pickupCtrl.text = address;
        _step = _TransportStep.inputting;
        _markers = {_buildPickupMarker(latLng, address)};
      });

      final ctrl = await _mapCompleter.future;
      await ctrl.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15.5),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => _step = _TransportStep.inputting);
    }
  }

  // ── Marker helpers ─────────────────────────────────────────────────────────

  Marker _buildPickupMarker(LatLng pos, String label) => Marker(
    markerId: const MarkerId('pickup'),
    position: pos,
    infoWindow: InfoWindow(title: 'Pickup', snippet: label),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
  );

  Marker _buildDestMarker(LatLng pos, String label) => Marker(
    markerId: const MarkerId('destination'),
    position: pos,
    infoWindow: InfoWindow(title: 'Destination', snippet: label),
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
  );

  // ── Autocomplete ───────────────────────────────────────────────────────────

  void _onPickupChanged(String val) {
    _debounce?.cancel();
    _suggestionTarget = _SuggestionTarget.pickup;
    if (_currentLatLng != null) setState(() => _currentLatLng = null);
    _debounce = Timer(
      const Duration(milliseconds: 420),
      () => _fetchSuggestions(val),
    );
  }

  void _onDestinationChanged(String val) {
    _debounce?.cancel();
    _suggestionTarget = _SuggestionTarget.destination;
    if (_destLatLng != null) setState(() => _destLatLng = null);
    _debounce = Timer(
      const Duration(milliseconds: 420),
      () => _fetchSuggestions(val),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.trim().length < 3) {
      if (mounted) setState(() => _suggestions = []);
      return;
    }
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {'input': input, 'key': _kMapsApiKey, 'types': 'geocode'},
      );
      final res = await http.get(uri);
      debugPrint('[Transport] Autocomplete HTTP ${res.statusCode}');
      if (!mounted || res.statusCode != 200) return;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final status = data['status'] as String? ?? 'UNKNOWN';
      debugPrint('[Transport] Autocomplete API status: $status');
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[Transport] Error message: ${data['error_message']}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Places API: $status — ${data['error_message'] ?? ''}',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
      final preds = data['predictions'] as List<dynamic>? ?? [];
      debugPrint('[Transport] Got ${preds.length} suggestions');
      setState(() {
        _suggestions = preds
            .map(
              (p) => {
                'description': p['description'] as String,
                'placeId': p['place_id'] as String,
              },
            )
            .toList();
      });
    } catch (e) {
      debugPrint('[Transport] Autocomplete exception: $e');
    }
  }

  Future<LatLng?> _placeIdToLatLng(String placeId) async {
    try {
      final uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/details/json',
        {'place_id': placeId, 'key': _kMapsApiKey, 'fields': 'geometry'},
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      final loc = data['result']['geometry']['location'];
      return LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _selectSuggestion(Map<String, String> s) async {
    _debounce?.cancel();
    final latLng = await _placeIdToLatLng(s['placeId']!);
    if (!mounted) return;

    if (_suggestionTarget == _SuggestionTarget.pickup) {
      setState(() {
        _suggestions = [];
        _pickupAddress = s['description']!;
        _pickupCtrl.text = _pickupAddress;
        if (latLng != null) {
          _currentLatLng = latLng;
          _markers = {
            _buildPickupMarker(latLng, _pickupAddress),
            if (_destLatLng != null)
              _buildDestMarker(_destLatLng!, _destAddress),
          };
        }
      });
      if (latLng != null) {
        final ctrl = await _mapCompleter.future;
        ctrl.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: latLng, zoom: 15.5),
          ),
        );
      }
    } else {
      setState(() {
        _suggestions = [];
        _destAddress = s['description']!;
        _destCtrl.text = _destAddress;
        if (latLng != null) _destLatLng = latLng;
      });
    }
  }

  // ── Route ──────────────────────────────────────────────────────────────────

  Future<void> _getRoute() async {
    LatLng? origin = _currentLatLng;

    // If no GPS fix, try geocoding the typed pickup address
    if (origin == null && _pickupCtrl.text.trim().isNotEmpty) {
      try {
        final locs = await locationFromAddress(_pickupCtrl.text.trim());
        if (locs.isNotEmpty) {
          origin = LatLng(locs.first.latitude, locs.first.longitude);
        }
      } catch (_) {}
    }

    if (origin == null || _destLatLng == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter both pickup and destination.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _loadingRoute = true);

    try {
      final uri =
          Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
            'origin': '${origin.latitude},${origin.longitude}',
            'destination': '${_destLatLng!.latitude},${_destLatLng!.longitude}',
            'mode': 'driving',
            'key': _kMapsApiKey,
          });

      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final data = json.decode(res.body) as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        throw Exception('No route found (${data['status']})');
      }

      final leg = data['routes'][0]['legs'][0];
      final encodedPoly =
          data['routes'][0]['overview_polyline']['points'] as String;

      final decoded = PolylinePoints().decodePolyline(encodedPoly);
      final polyCoords = decoded
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();

      final rawMeters = (leg['distance']['value'] as num).toDouble();
      final km = rawMeters / 1000.0;
      final fare = 10.0 + (km * 8.0);

      final capturedOrigin = origin;
      setState(() {
        _distanceText = leg['distance']['text'] as String;
        _durationText = leg['duration']['text'] as String;
        _distanceKm = km;
        _fareAmount = fare;
        _markers = {
          _buildPickupMarker(capturedOrigin, _pickupCtrl.text),
          _buildDestMarker(_destLatLng!, _destAddress),
        };
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: polyCoords,
            color: AppColors.primary,
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
            jointType: JointType.round,
          ),
        };
        _step = _TransportStep.routing;
        _loadingRoute = false;
      });

      // Fit both markers in view
      final bounds = LatLngBounds(
        southwest: LatLng(
          min(capturedOrigin.latitude, _destLatLng!.latitude),
          min(capturedOrigin.longitude, _destLatLng!.longitude),
        ),
        northeast: LatLng(
          max(capturedOrigin.latitude, _destLatLng!.latitude),
          max(capturedOrigin.longitude, _destLatLng!.longitude),
        ),
      );
      final ctrl = await _mapCompleter.future;
      await ctrl.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (e) {
      if (mounted) {
        setState(() => _loadingRoute = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load route: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _resetToInput() {
    setState(() {
      _step = _TransportStep.inputting;
      _polylines = {};
      _destAddress = '';
      _destLatLng = null;
      _distanceText = null;
      _durationText = null;
      _distanceKm = 0.0;
      _fareAmount = 0.0;
      _destCtrl.clear();
      _suggestions = [];
      if (_currentLatLng != null) {
        _markers = {_buildPickupMarker(_currentLatLng!, _pickupAddress)};
      }
    });
  }

  Future<void> _bookTransport() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentLatLng == null || _destLatLng == null) return;
    setState(() => _booking = true);
    try {
      final ref = FirebaseFirestore.instance.collection('bookings').doc();
      final data = <String, dynamic>{
        'service': 'transport',
        'status': 'pending',
        'customerId': user.uid,
        'customerName': user.displayName ?? 'Customer',
        'pickupAddress': _pickupAddress,
        'destinationAddress': _destAddress,
        'pickupLat': _currentLatLng!.latitude,
        'pickupLng': _currentLatLng!.longitude,
        'destLat': _destLatLng!.latitude,
        'destLng': _destLatLng!.longitude,
        'distanceKm': _distanceKm,
        'durationText': _durationText ?? '',
        'pricing': {'customerPays': _fareAmount, 'providerEarns': _fareAmount},
        'assignedProviderId': null,
        'providerId': null,
        'broadcastStatus': '',
        'isBroadcast': true,
        'createdAt': FieldValue.serverTimestamp(),
      };
      await ref.set(data);
      if (!mounted) return;
      setState(() => _booking = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              TransportSearchingScreen(bookingId: ref.id, bookingData: data),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _booking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to book: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Location Access Required',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Location permission is permanently denied. Open app settings to enable it, or enter your pickup address manually.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Later', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: Text(
              'Open Settings',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // ── Full-screen map ──────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLatLng ?? _kDefaultCenter,
              zoom: _currentLatLng != null ? 15.5 : 11,
            ),
            onMapCreated: (c) => _mapCompleter.complete(c),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
          ),

          // ── Locating overlay ─────────────────────────────────────────
          if (_step == _TransportStep.locating)
            Container(
              color: Colors.black38,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 22,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 14),
                      Text(
                        'Getting your location…',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Back button ──────────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            child: _FloatingMapButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.of(context).pop(),
              isDark: isDark,
            ),
          ),

          // ── My-location button ───────────────────────────────────────
          if (_currentLatLng != null)
            Positioned(
              top: topPad + 12,
              right: 16,
              child: _FloatingMapButton(
                icon: Icons.my_location_rounded,
                onTap: () async {
                  final ctrl = await _mapCompleter.future;
                  ctrl.animateCamera(
                    CameraUpdate.newCameraPosition(
                      CameraPosition(target: _currentLatLng!, zoom: 15.5),
                    ),
                  );
                },
                isDark: isDark,
              ),
            ),

          // ── Input bottom sheet ───────────────────────────────────────
          if (_step == _TransportStep.inputting)
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.34,
              minChildSize: 0.18,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.34, 0.88],
              builder: (ctx, scrollCtrl) => _InputSheetContent(
                scrollController: scrollCtrl,
                sheetController: _sheetController,
                pickupCtrl: _pickupCtrl,
                destCtrl: _destCtrl,
                suggestions: _suggestions,
                canGetRoute: _destLatLng != null && _pickupCtrl.text.isNotEmpty,
                loadingRoute: _loadingRoute,
                isDark: isDark,
                onPickupChanged: _onPickupChanged,
                onDestinationChanged: _onDestinationChanged,
                onSuggestionSelected: _selectSuggestion,
                onGetRoute: _getRoute,
              ),
            ),

          // ── Route bottom bar ─────────────────────────────────────────
          if (_step == _TransportStep.routing)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _RouteBottomBar(
                distanceText: _distanceText ?? '',
                durationText: _durationText ?? '',
                fareAmount: _fareAmount,
                pickupLabel: _pickupCtrl.text,
                destLabel: _destAddress,
                isDark: isDark,
                booking: _booking,
                onChangeRoute: _resetToInput,
                onBookTransport: _bookTransport,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Floating map button ────────────────────────────────────────────────────────

class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 8),
        ],
      ),
      child: Icon(
        icon,
        size: 18,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    ),
  );
}

// ── Input bottom sheet content ─────────────────────────────────────────────────

class _InputSheetContent extends StatefulWidget {
  const _InputSheetContent({
    required this.scrollController,
    required this.sheetController,
    required this.pickupCtrl,
    required this.destCtrl,
    required this.suggestions,
    required this.canGetRoute,
    required this.loadingRoute,
    required this.isDark,
    required this.onPickupChanged,
    required this.onDestinationChanged,
    required this.onSuggestionSelected,
    required this.onGetRoute,
  });

  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final TextEditingController pickupCtrl;
  final TextEditingController destCtrl;
  final List<Map<String, String>> suggestions;
  final bool canGetRoute;
  final bool loadingRoute;
  final bool isDark;
  final ValueChanged<String> onPickupChanged;
  final ValueChanged<String> onDestinationChanged;
  final ValueChanged<Map<String, String>> onSuggestionSelected;
  final VoidCallback onGetRoute;

  @override
  State<_InputSheetContent> createState() => _InputSheetContentState();
}

class _InputSheetContentState extends State<_InputSheetContent> {
  final _pickupFocus = FocusNode();
  final _destFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    void expandSheet() {
      widget.sheetController.animateTo(
        0.88,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    _pickupFocus.addListener(() {
      if (_pickupFocus.hasFocus) expandSheet();
    });
    _destFocus.addListener(() {
      if (_destFocus.hasFocus) expandSheet();
    });
  }

  @override
  void dispose() {
    _pickupFocus.dispose();
    _destFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pet Transport',
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Where are we picking up?',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Route visual + fields
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Connector column
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 44,
                      color:
                          (isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight)
                              .withValues(alpha: 0.7),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Input fields
              Expanded(
                child: Column(
                  children: [
                    _LocationInputField(
                      controller: widget.pickupCtrl,
                      hint: 'Pickup location',
                      isDark: isDark,
                      focusNode: _pickupFocus,
                      onChanged: widget.onPickupChanged,
                    ),
                    const SizedBox(height: 8),
                    _LocationInputField(
                      controller: widget.destCtrl,
                      hint: 'Where to?',
                      isDark: isDark,
                      focusNode: _destFocus,
                      onChanged: widget.onDestinationChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Autocomplete suggestions
          if (widget.suggestions.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Column(
                children: widget.suggestions.asMap().entries.map((e) {
                  final i = e.key;
                  final s = e.value;
                  return Column(
                    children: [
                      InkWell(
                        onTap: () => widget.onSuggestionSelected(s),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 17,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  s['description']!,
                                  style: GoogleFonts.inter(fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (i < widget.suggestions.length - 1)
                        Divider(
                          height: 1,
                          indent: 41,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Get Route button
          GestureDetector(
            onTap: widget.canGetRoute && !widget.loadingRoute
                ? widget.onGetRoute
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 54,
              decoration: BoxDecoration(
                color: widget.canGetRoute
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                boxShadow: widget.canGetRoute
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: widget.loadingRoute
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Color(0xFF0F172A),
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.route_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.canGetRoute
                                ? 'Get Route'
                                : 'Enter a destination first',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
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

// ── Location input field ───────────────────────────────────────────────────────

class _LocationInputField extends StatelessWidget {
  const _LocationInputField({
    required this.controller,
    required this.hint,
    required this.isDark,
    this.focusNode,
    this.onChanged,
  });
  final TextEditingController controller;
  final String hint;
  final bool isDark;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        style: GoogleFonts.inter(fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
        ),
      ),
    );
  }
}

// ── Route bottom bar ───────────────────────────────────────────────────────────

class _RouteBottomBar extends StatelessWidget {
  const _RouteBottomBar({
    required this.distanceText,
    required this.durationText,
    required this.fareAmount,
    required this.pickupLabel,
    required this.destLabel,
    required this.isDark,
    required this.booking,
    required this.onChangeRoute,
    required this.onBookTransport,
  });
  final String distanceText;
  final String durationText;
  final double fareAmount;
  final String pickupLabel;
  final String destLabel;
  final bool isDark;
  final bool booking;
  final VoidCallback onChangeRoute;
  final Future<void> Function() onBookTransport;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Distance, duration & fare chips
          Row(
            children: [
              Expanded(
                child: _RouteInfoChip(
                  icon: Icons.straighten_rounded,
                  label: 'Distance',
                  value: distanceText,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RouteInfoChip(
                  icon: Icons.access_time_rounded,
                  label: 'Est. Time',
                  value: durationText,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RouteInfoChip(
                  icon: Icons.payments_rounded,
                  label: 'Fare',
                  value: 'R${fareAmount.toStringAsFixed(0)}',
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Route summary card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _RouteLegRow(
                  dot: AppColors.success,
                  label: pickupLabel,
                  isDark: isDark,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
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
                _RouteLegRow(
                  dot: AppColors.error,
                  label: destLabel,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Change route
              GestureDetector(
                onTap: onChangeRoute,
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Change',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Book transport
              Expanded(
                child: GestureDetector(
                  onTap: booking ? null : onBookTransport,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: booking
                          ? AppColors.primary.withValues(alpha: 0.6)
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: booking
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF0F172A),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Color(0xFF0F172A),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Book — R${fareAmount.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteInfoChip extends StatelessWidget {
  const _RouteInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
    ),
    child: Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RouteLegRow extends StatelessWidget {
  const _RouteLegRow({
    required this.dot,
    required this.label,
    required this.isDark,
  });
  final Color dot;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: dot,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}
