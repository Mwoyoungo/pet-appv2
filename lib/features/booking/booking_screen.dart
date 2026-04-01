import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/services/stream_service.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/core/models/booking_model.dart';
import 'package:pet_app/core/providers/booking_provider.dart';
import 'package:pet_app/core/providers/auth_provider.dart';

class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({
    super.key,
    required this.providerId,
    required this.providerName,
    required this.serviceType,
    this.providerImageUrl,
  });

  final String providerId;
  final String providerName;
  final String serviceType;
  final String? providerImageUrl;

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedSlot;
  int _selectedServiceIndex = 0;
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  List<_ServiceOption> get _services {
    switch (widget.serviceType) {
      case 'walking':
        return const [
          _ServiceOption('30 Min Walk', 18.0, '30 minutes'),
          _ServiceOption('60 Min Walk', 30.0, '60 minutes'),
          _ServiceOption('Group Walk', 12.0, '45 minutes'),
        ];
      case 'daycare':
        return const [
          _ServiceOption('Half Day', 20.0, '4 hours'),
          _ServiceOption('Full Day', 35.0, '8 hours'),
          _ServiceOption('Weekly Package', 155.0, '5 full days'),
        ];
      case 'training':
        return const [
          _ServiceOption('Private Session', 80.0, '60 minutes'),
          _ServiceOption('Group Class', 35.0, '60 minutes'),
          _ServiceOption('Puppy Starter Pack', 220.0, '3 sessions'),
        ];
      case 'sitting':
        return const [
          _ServiceOption('Overnight Stay', 60.0, '12 hours'),
          _ServiceOption('Weekend Stay', 110.0, '48 hours'),
          _ServiceOption('Day Check-in', 30.0, '4 hours'),
        ];
      case 'grooming':
      default:
        return const [
          _ServiceOption('Full Grooming', 90.0, '90 – 120 min'),
          _ServiceOption('Bath & Brush', 55.0, '45 – 60 min'),
          _ServiceOption('Nail Trimming', 25.0, '15 – 20 min'),
          _ServiceOption('Teeth Brushing', 20.0, '10 – 15 min'),
        ];
    }
  }

  final _timeSlots = const [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
  ];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    if (_selectedSlot == null) {
      _showSnack('Please select a time slot');
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.go('/login');
      return;
    }

    setState(() => _loading = true);
    try {
      final services = _services;
      final service = services[_selectedServiceIndex];
      final booking = BookingModel(
        id: '',
        userId: user.uid,
        providerId: widget.providerId,
        providerName: widget.providerName,
        serviceType: widget.serviceType,
        serviceName: service.name,
        date: _selectedDate,
        timeSlot: _selectedSlot!,
        price: service.price,
        status: BookingStatus.pending,
        createdAt: DateTime.now(),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        providerImageUrl: widget.providerImageUrl,
      );

      final bookingId = await ref
          .read(bookingNotifierProvider.notifier)
          .createBooking(booking);

      // Create a Stream chat channel for this booking
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      final dateStr =
          '${months[_selectedDate.month - 1]} ${_selectedDate.day}';
      final channel = await StreamService.createBookingChannel(
        bookingId: bookingId,
        userId: user.uid,
        providerId: widget.providerId,
        providerName: widget.providerName,
        serviceName: service.name,
        date: dateStr,
        timeSlot: _selectedSlot!,
      );

      if (channel != null) {
        // Save channelId back to the booking document
        await ref
            .read(bookingNotifierProvider.notifier)
            .updateChannelId(bookingId, channel.id!);

        // Notify the provider via FCM
        _sendBookingNotification(
          bookingId: bookingId,
          providerId: widget.providerId,
          serviceName: service.name,
          date: dateStr,
          timeSlot: _selectedSlot!,
        );
      }

      if (mounted) {
        _showSuccessSheet();
      }
    } catch (e) {
      if (mounted) _showSnack('Booking failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _sendBookingNotification({
    required String bookingId,
    required String providerId,
    required String serviceName,
    required String date,
    required String timeSlot,
  }) {
    FirebaseFunctions.instance.httpsCallable('sendBookingNotification').call({
      'providerId': providerId,
      'bookingData': {
        'bookingId': bookingId,
        'serviceType': widget.serviceType,
        'serviceName': serviceName,
        'date': date,
        'timeSlot': timeSlot,
      },
    }).then((_) {}).catchError((_) {
      // Non-fatal — notification failure doesn't break the booking
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        providerName: widget.providerName,
        service: _services[_selectedServiceIndex].name,
        date: _selectedDate,
        slot: _selectedSlot!,
        onDone: () {
          Navigator.of(context).pop();
          context.go('/bookings');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final services = _services;
    // Clamp index in case serviceType changed
    if (_selectedServiceIndex >= services.length) _selectedServiceIndex = 0;
    final service = services[_selectedServiceIndex];

    return Scaffold(
      body: ResponsiveContainer(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 12,
                16,
                16,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.backgroundDark
                    : AppColors.backgroundLight,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Appointment',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.providerName,
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
                ],
              ),
            ),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Service selector ─────────────────────────────────
                    _SectionLabel('Select Service', isDark: isDark),
                    const SizedBox(height: 12),
                    ...List.generate(services.length, (i) {
                      final s = services[i];
                      final sel = _selectedServiceIndex == i;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedServiceIndex = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppColors.primary.withValues(alpha: 0.08)
                                : (isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.primary
                                      : (isDark
                                            ? AppColors.surfaceDark
                                            : AppColors.surfaceLight),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.content_cut_rounded,
                                  size: 20,
                                  color: sel
                                      ? const Color(0xFF0F172A)
                                      : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.name,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      s.duration,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'R${s.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // ── Date picker ──────────────────────────────────────
                    _SectionLabel('Select Date', isDark: isDark),
                    const SizedBox(height: 12),
                    _DatePicker(
                      selectedDate: _selectedDate,
                      isDark: isDark,
                      onDateSelected: (d) => setState(() {
                        _selectedDate = d;
                        _selectedSlot = null;
                      }),
                    ),

                    const SizedBox(height: 24),

                    // ── Time slots ───────────────────────────────────────
                    _SectionLabel('Select Time', isDark: isDark),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _timeSlots.map((slot) {
                        final sel = _selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedSlot = slot),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppColors.primary
                                  : (isDark
                                        ? AppColors.cardDark
                                        : AppColors.cardLight),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: sel
                                    ? AppColors.primary
                                    : (isDark
                                          ? AppColors.borderDark
                                          : AppColors.borderLight),
                              ),
                            ),
                            child: Text(
                              slot,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: sel
                                    ? const Color(0xFF0F172A)
                                    : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimaryLight),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // ── Notes ────────────────────────────────────────────
                    _SectionLabel('Notes (optional)', isDark: isDark),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: TextField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText:
                              'Any special requests or info about your pet...',
                          hintStyle: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Price summary ────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _PriceRow('Service', service.name, isDark: isDark),
                          const SizedBox(height: 8),
                          _PriceRow(
                            'Duration',
                            service.duration,
                            isDark: isDark,
                          ),
                          if (_selectedSlot != null) ...[
                            const SizedBox(height: 8),
                            _PriceRow('Time', _selectedSlot!, isDark: isDark),
                          ],
                          const SizedBox(height: 12),
                          Divider(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'R${service.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── Sticky confirm button ──────────────────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: (isDark ? AppColors.backgroundDark : Colors.white).withValues(
            alpha: 0.97,
          ),
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: GestureDetector(
          onTap: _loading ? null : _confirmBooking,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 58,
            decoration: BoxDecoration(
              color: _selectedSlot != null
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              boxShadow: _selectedSlot != null
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Color(0xFF0F172A),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF0F172A),
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Confirm Booking',
                          style: GoogleFonts.inter(
                            fontSize: 16,
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
    );
  }
}

// ── Success bottom sheet ─────────────────────────────────────────────────────

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.providerName,
    required this.service,
    required this.date,
    required this.slot,
    required this.onDone,
  });

  final String providerName, service, slot;
  final DateTime date;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Success icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Booking Confirmed!',
            style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Your appointment with $providerName has been requested.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          // Booking details card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.content_cut_rounded,
                  label: 'Service',
                  value: service,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: '${date.day} ${months[date.month - 1]} ${date.year}',
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.schedule_rounded,
                  label: 'Time',
                  value: slot,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: onDone,
            child: Container(
              width: double.infinity,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'View My Bookings',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, {required this.isDark});
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {required this.isDark});
  final String label, value;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
      Text(
        value,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _ServiceOption {
  const _ServiceOption(this.name, this.price, this.duration);
  final String name, duration;
  final double price;
}

class _DatePicker extends StatelessWidget {
  const _DatePicker({
    required this.selectedDate,
    required this.isDark,
    required this.onDateSelected,
  });
  final DateTime selectedDate;
  final bool isDark;
  final void Function(DateTime) onDateSelected;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final days = List.generate(14, (i) => now.add(Duration(days: i + 1)));
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Month label
        Text(
          '${months[selectedDate.month - 1]} ${selectedDate.year}',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final d = days[i];
              final sel =
                  d.day == selectedDate.day &&
                  d.month == selectedDate.month &&
                  d.year == selectedDate.year;
              final dayName = dayNames[d.weekday - 1];

              return GestureDetector(
                onTap: () => onDateSelected(d),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 52,
                  decoration: BoxDecoration(
                    color: sel
                        ? AppColors.primary
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? const Color(0xFF0F172A)
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: sel
                              ? const Color(0xFF0F172A)
                              : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
