import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/services/stream_service.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/features/chat/chat_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class WalkerProfileScreen extends StatelessWidget {
  const WalkerProfileScreen({super.key, required this.walkerId});
  final String walkerId;

  // Fake data keyed by ID for the demo
  static const _data = {
    '1': _WalkerInfo(
      name: 'James Okafor',
      location: 'Midtown, New York',
      imageUrl:
          'https://images.unsplash.com/photo-1601979031925-424e53b6caaa?w=800',
      avatarUrl: 'https://i.pravatar.cc/200?img=11',
      rating: 4.9,
      reviewCount: 214,
      about:
          'Passionate and reliable dog walker with 6 years of experience. '
          'I treat every dog as my own — from energetic puppies to senior pups. '
          'All walks include real-time GPS tracking and a post-walk report card.',
      badge1: 'GPS Tracked',
      badge2: 'Insured & Bonded',
      reviewerName: 'Amara Dube',
      reviewerAvatar: 'https://i.pravatar.cc/80?img=5',
      reviewText:
          '"James is incredible with my Labrador. He always sends photos mid-walk and my dog absolutely loves him. Highly recommended!"',
    ),
    '2': _WalkerInfo(
      name: 'Leila Nkosi',
      location: 'Brooklyn, New York',
      imageUrl:
          'https://images.unsplash.com/photo-1587300003388-59208cc962cb?w=800',
      avatarUrl: 'https://i.pravatar.cc/200?img=47',
      rating: 5.0,
      reviewCount: 97,
      about:
          'Certified animal behaviourist and dog walker. I specialise in anxious '
          'and reactive dogs, providing a calm and safe walking experience. '
          'Individual attention guaranteed on every walk.',
      badge1: 'Fear-Free Certified',
      badge2: '5 Years Exp.',
      reviewerName: 'Sipho Mokoena',
      reviewerAvatar: 'https://i.pravatar.cc/80?img=8',
      reviewText:
          '"My reactive rescue dog has made such progress since walking with Leila. She truly understands dogs. A 5-star walker!"',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final info = _data[walkerId] ?? _data['1']!;

    return Scaffold(
      body: ResponsiveContainer(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Hero image ────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Image.network(
                        info.imageUrl,
                        height: 300,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 300,
                          color: AppColors.surfaceDark,
                          child: const Icon(Icons.directions_run,
                              size: 64, color: AppColors.primary),
                        ),
                      ),
                      // Gradient
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
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            _GlassBtn(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onTap: () =>
                                  Navigator.of(context).maybePop(),
                            ),
                            Row(
                              children: [
                                _GlassBtn(
                                    icon: Icons.share_rounded,
                                    onTap: () {}),
                                const SizedBox(width: 8),
                                _GlassBtn(
                                    icon: Icons.favorite_border_rounded,
                                    onTap: () {}),
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
                            3,
                            (i) => Container(
                              width: 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == 0
                                    ? AppColors.primary
                                    : Colors.white
                                        .withValues(alpha: 0.4),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Content sheet ─────────────────────────────────────────
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
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + rating
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    info.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 14,
                                          color: textSecondary),
                                      const SizedBox(width: 3),
                                      Text(
                                        info.location,
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.primary,
                                          size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        info.rating
                                            .toStringAsFixed(1),
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
                                  '${info.reviewCount} reviews',
                                  style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: textSecondary),
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
                                  icon: Icons.gps_fixed_rounded,
                                  label: info.badge1,
                                  isDark: isDark),
                              const SizedBox(width: 10),
                              _TrustBadge(
                                  icon: Icons.verified_rounded,
                                  label: info.badge2,
                                  isDark: isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // About
                        Text('About',
                            style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Text(
                          info.about,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textSecondary,
                              height: 1.6),
                        ),
                        const SizedBox(height: 24),

                        // Walk options
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Walk Options',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            Text('View Schedule',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ServiceRow(
                          icon: Icons.timer_rounded,
                          name: '30 Min Walk',
                          duration: 'Solo, on-leash walk',
                          price: '\$18',
                          note: 'Per session',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _ServiceRow(
                          icon: Icons.directions_walk_rounded,
                          name: '60 Min Walk',
                          duration: 'Extended solo walk',
                          price: '\$30',
                          note: 'Per session',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 10),
                        _ServiceRow(
                          icon: Icons.group_rounded,
                          name: 'Group Walk',
                          duration: 'Up to 4 dogs',
                          price: '\$12',
                          note: 'Per dog',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),

                        // Reviews
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Reviews',
                                style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            Text('See all',
                                style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _ReviewCard(
                          avatarUrl: info.reviewerAvatar,
                          name: info.reviewerName,
                          text: info.reviewText,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Sticky bottom CTA ─────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: (isDark
                          ? AppColors.backgroundDark
                          : Colors.white)
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
                            otherUserId: walkerId,
                            otherUserName: info.name,
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
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline_rounded,
                                  size: 20,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight),
                              const SizedBox(width: 8),
                              Text('Chat',
                                  style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700)),
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
                            'providerId': walkerId,
                            'providerName': info.name,
                            'serviceType': 'walking',
                          },
                        ),
                        child: Container(
                          height: 54,
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
                          child: Center(
                            child: Text(
                              'Book a Walk',
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

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WalkerInfo {
  const _WalkerInfo({
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.avatarUrl,
    required this.rating,
    required this.reviewCount,
    required this.about,
    required this.badge1,
    required this.badge2,
    required this.reviewerName,
    required this.reviewerAvatar,
    required this.reviewText,
  });
  final String name, location, imageUrl, avatarUrl, about;
  final String badge1, badge2, reviewerName, reviewerAvatar, reviewText;
  final double rating;
  final int reviewCount;
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
  const _TrustBadge(
      {required this.icon, required this.label, required this.isDark});
  final IconData icon;
  final String label;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
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
            color:
                isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(alpha: isDark ? 0.2 : 0.04),
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
              child:
                  Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(duration,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text(note,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    )),
              ],
            ),
          ],
        ),
      );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.avatarUrl,
    required this.name,
    required this.text,
    required this.isDark,
  });
  final String avatarUrl, name, text;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: NetworkImage(avatarUrl),
                  backgroundColor: AppColors.surfaceDark,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    Row(
                      children: List.generate(
                        5,
                        (_) => const Icon(Icons.star_rounded,
                            color: AppColors.primary, size: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              text,
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
