import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';

class DaycareDetailScreen extends StatelessWidget {
  const DaycareDetailScreen({super.key, required this.daycareId});
  final String daycareId;

  static const _data = {
    '1': _DaycareInfo(
      name: 'Happy Paws Daycare\n& Resort',
      address: '45 Park Ave, Pet Valley  •  0.7 miles away',
      imageUrl:
          'https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800',
      capacity: '30 dogs / day',
      amenities: 'Indoor + Outdoor Play',
      providerId: '1',
      providerName: 'Happy Paws Daycare',
    ),
    '2': _DaycareInfo(
      name: 'Sunny Tails\nPet Resort',
      address: '88 Barkway Drive  •  1.4 miles away',
      imageUrl:
          'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800',
      capacity: '20 dogs / day',
      amenities: 'Pool + Grooming + Webcam',
      providerId: '2',
      providerName: 'Sunny Tails Pet Resort',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final info = _data[daycareId] ?? _data['1']!;

    return Scaffold(
      body: ResponsiveContainer(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Sticky Nav ────────────────────────────────────────────
                SliverAppBar(
                  pinned: true,
                  backgroundColor:
                      (isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight)
                          .withValues(alpha: 0.85),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  flexibleSpace: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _NavBtn(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () =>
                              Navigator.of(context).maybePop(),
                        ),
                        Row(
                          children: [
                            _NavBtn(
                                icon: Icons.favorite_border_rounded,
                                color: AppColors.primary,
                                onTap: () {}),
                            const SizedBox(width: 8),
                            _NavBtn(
                                icon: Icons.share_rounded, onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Hero Image ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Image.network(
                            info.imageUrl,
                            height: 220,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 220,
                              color: AppColors.surfaceDark,
                              child: const Icon(Icons.festival,
                                  size: 64, color: AppColors.primary),
                            ),
                          ),
                          // Open badge
                          Positioned(
                            top: 16,
                            left: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(50),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success
                                        .withValues(alpha: 0.4),
                                    blurRadius: 12,
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
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Now Open',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
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
                ),

                // ── Title ─────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          info.name,
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              size: 15,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                info.address,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── CTAs ──────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Column(
                      children: [
                        // Book a Day
                        GestureDetector(
                          onTap: () => context.push(
                            '/booking',
                            extra: {
                              'providerId': info.providerId,
                              'providerName': info.providerName,
                              'serviceType': 'daycare',
                            },
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 18),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.event_available_rounded,
                                    color: Color(0xFF0F172A), size: 22),
                                const SizedBox(width: 10),
                                Text(
                                  'BOOK A DAY',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Get Directions
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16),
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
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Icon(Icons.directions_rounded,
                                    size: 22,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight),
                                const SizedBox(width: 10),
                                Text('Get Directions',
                                    style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Operating Hours ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _InfoCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.schedule_rounded,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Drop-off Hours',
                                      style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Open Now',
                                    style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.success)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _HoursRow('Mon – Fri',
                              '07:00 AM – 07:00 PM', isDark),
                          _HoursRow(
                              'Saturday', '08:00 AM – 05:00 PM', isDark),
                          _HoursRow(
                              'Sunday', 'Closed', isDark,
                              isLast: true, highlight: false),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Facility info ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MiniCard(
                            icon: Icons.group_rounded,
                            title: 'Capacity',
                            subtitle: info.capacity,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniCard(
                            icon: Icons.stars_rounded,
                            title: 'Amenities',
                            subtitle: info.amenities,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pricing ───────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _InfoCard(
                      isDark: isDark,
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments_rounded,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text('Pricing',
                                  style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _PriceRow('Half Day (4 hrs)', '\$20',
                              isDark: isDark),
                          _PriceRow('Full Day (8 hrs)', '\$35',
                              isDark: isDark),
                          _PriceRow('Weekly Package (5 days)', '\$155',
                              isDark: isDark, isLast: true),
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Map placeholder ───────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: Stack(
                        children: [
                          Container(
                            height: 150,
                            color: isDark
                                ? AppColors.surfaceDark
                                : const Color(0xFFE8F0E8),
                            child: Center(
                              child: Icon(Icons.map_rounded,
                                  size: 64,
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.4),
                                      blurRadius: 16,
                                    ),
                                  ],
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.black
                                        : Colors.white,
                                    width: 3,
                                  ),
                                ),
                                child: const Icon(Icons.festival_rounded,
                                    color: Color(0xFF0F172A), size: 26),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    child: Text(
                      'All dogs must be up-to-date on vaccinations. '
                      'Please bring vaccination records on your first visit.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _DaycareInfo {
  const _DaycareInfo({
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.capacity,
    required this.amenities,
    required this.providerId,
    required this.providerName,
  });
  final String name, address, imageUrl, capacity, amenities;
  final String providerId, providerName;
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap, this.color});
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08), blurRadius: 8),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child, required this.isDark});
  final Widget child;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 12,
            ),
          ],
        ),
        child: child,
      );
}

class _HoursRow extends StatelessWidget {
  const _HoursRow(this.day, this.hours, this.isDark,
      {this.isLast = false, this.highlight = true});
  final String day, hours;
  final bool isDark, isLast, highlight;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(day,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
                Text(hours,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: highlight ? AppColors.primary : null,
                    )),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
        ],
      );
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
  });
  final IconData icon;
  final String title, subtitle;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 8),
            Text(title,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                )),
          ],
        ),
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.price,
      {required this.isDark, this.isLast = false});
  final String label, price;
  final bool isDark, isLast;
  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
                Text(price,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    )),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
        ],
      );
}
