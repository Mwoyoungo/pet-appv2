import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/services/stream_service.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/features/chat/chat_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class GroomerProfileScreen extends StatelessWidget {
  const GroomerProfileScreen({super.key, required this.groomerId});
  final String groomerId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      body: ResponsiveContainer(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Hero image with overlay nav
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Image.network(
                        'https://images.unsplash.com/photo-1516734212186-a967f81ad0d7?w=800',
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: AppColors.surfaceDark,
                          child: const Icon(
                            Icons.content_cut,
                            size: 64,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                (isDark
                                        ? AppColors.backgroundDark
                                        : AppColors.backgroundLight)
                                    .withValues(alpha: 0.9),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Nav buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 12,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _GlassBtn(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () => Navigator.of(context).maybePop(),
                            ),
                            Row(
                              children: [
                                _GlassBtn(
                                  icon: Icons.share_rounded,
                                  onTap: () {},
                                ),
                                const SizedBox(width: 8),
                                _GlassBtn(
                                  icon: Icons.favorite_border_rounded,
                                  onTap: () {},
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Image dots
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            4,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppColors.primary
                                    : Colors.white.withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content sheet
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.backgroundDark
                          : AppColors.backgroundLight,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + rating
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'The Pawsome Spa',
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on_rounded,
                                        size: 14,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        'Upper West Side, New York',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppColors.primary,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '4.9',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '128 reviews',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Trust badges
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _TrustBadge(
                                icon: Icons.verified_rounded,
                                label: 'Verified Professional',
                                isDark: isDark,
                              ),
                              const SizedBox(width: 10),
                              _TrustBadge(
                                icon: Icons.history_rounded,
                                label: '8+ Years Exp.',
                                isDark: isDark,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // About
                        Text(
                          'About',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dedicated professional groomer specializing in stress-free handling and breed-specific styling. We prioritize your pet\'s comfort and hygiene using premium organic products.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondary,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Services
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Services',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'View Catalog',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ServiceRow(
                          icon: Icons.content_cut_rounded,
                          name: 'Full Grooming',
                          duration: '90 – 120 mins',
                          price: '\$65 – \$110',
                          note: 'Depending on size',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _ServiceRow(
                          icon: Icons.shower_rounded,
                          name: 'Bath & Brush',
                          duration: '45 – 60 mins',
                          price: '\$40 – \$75',
                          note: 'Includes blow dry',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),

                        // Reviews
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reviews',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'See all',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ReviewCard(isDark: isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Sticky bottom CTA
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.backgroundDark : Colors.white)
                      .withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).padding.bottom + 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final currentUid =
                              FirebaseAuth.instance.currentUser?.uid;
                          if (currentUid == null) {
                            context.go('/login');
                            return;
                          }
                          final channel =
                              await StreamService.getOrCreateDirectChannel(
                            currentUserId: currentUid,
                            otherUserId: groomerId,
                            otherUserName: 'Groomer',
                          );
                          if (channel != null && context.mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StreamChannel(
                                  channel: channel,
                                  child: const ChatScreen(),
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 20,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Chat',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/booking',
                          extra: {
                            'providerId': groomerId,
                            'providerName': 'The Pawsome Spa',
                            'serviceType': 'grooming',
                          },
                        ),
                        child: Container(
                          height: 54,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Book Appointment',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBtn extends StatelessWidget {
  const _GlassBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({
    required this.icon,
    required this.label,
    required this.isDark,
  });
  final IconData icon;
  final String label;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.icon,
    required this.name,
    required this.duration,
    required this.price,
    required this.note,
    required this.isDark,
  });
  final IconData icon;
  final String name, duration, price, note;
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
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                duration,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            Text(
              note,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.isDark});
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: const NetworkImage(
                'https://i.pravatar.cc/80?img=12',
              ),
              backgroundColor: AppColors.surfaceDark,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marcus Thompson',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  children: List.generate(
                    5,
                    (_) => const Icon(
                      Icons.star_rounded,
                      color: AppColors.primary,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          '"The best experience my Golden Retriever has ever had. He came out looking like a show dog and was so happy. Truly premium service!"',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}
