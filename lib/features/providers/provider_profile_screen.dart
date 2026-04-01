import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/services/stream_service.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/features/chat/chat_screen.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({
    super.key,
    required this.providerUid,
    required this.serviceType,
  });

  final String providerUid;
  final String serviceType;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(providerUid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor:
                isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
            body: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Text('Provider not found',
                  style: GoogleFonts.inter(fontSize: 16)),
            ),
          );
        }

        final d = snapshot.data!.data() as Map<String, dynamic>;
        final name = d['displayName'] as String? ?? 'Provider';
        final bio = d['providerBio'] as String? ?? '';
        final photoUrl = d['photoUrl'] as String?;
        final services = List<String>.from(d['providerServiceTypes'] ?? []);
        final rawPrices = Map<String, dynamic>.from(d['providerPrices'] ?? {});
        final prices = rawPrices.map((k, v) => MapEntry(k, (v as num).toInt()));
        final textSecondary = isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight;

        return Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // ── Header image / avatar ─────────────────────────────
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Container(
                          height: 240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.85),
                                const Color(0xFFFF9B21),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                )
                              : Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: GoogleFonts.inter(
                                      fontSize: 80,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).padding.top + 12,
                          left: 16,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Content ───────────────────────────────────────────
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
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 130),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name
                          Text(
                            name,
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Service type chips
                          if (services.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: services
                                  .map(
                                    (s) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        s,
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),

                          if (bio.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              'About',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              bio,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textSecondary,
                                height: 1.6,
                              ),
                            ),
                          ],

                          // ── Pricing ───────────────────────────────────
                          if (prices.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Pricing',
                              style: GoogleFonts.inter(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...prices.entries.map(
                              (e) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.cardDark
                                      : AppColors.cardLight,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      e.key,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'R${e.value}',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Sticky bottom CTA ─────────────────────────────────────
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.of(context).padding.bottom + 12,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark
                            ? AppColors.backgroundDark
                            : Colors.white)
                        .withValues(alpha: 0.97),
                    border: Border(
                      top: BorderSide(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Chat button
                      Expanded(
                        child: _CTAButton(
                          label: 'Chat',
                          icon: Icons.chat_bubble_outline_rounded,
                          isDark: isDark,
                          isPrimary: false,
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
                              otherUserId: providerUid,
                              otherUserName: name,
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
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Book button
                      Expanded(
                        flex: 2,
                        child: _CTAButton(
                          label: 'Book Appointment',
                          icon: Icons.calendar_today_rounded,
                          isDark: isDark,
                          isPrimary: true,
                          onTap: () => context.push(
                            '/booking',
                            extra: {
                              'providerId': providerUid,
                              'providerName': name,
                              'serviceType': serviceType.toLowerCase(),
                              'providerImageUrl': photoUrl,
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CTAButton extends StatelessWidget {
  const _CTAButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.isPrimary,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool isDark;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isPrimary
                  ? const Color(0xFF0F172A)
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isPrimary
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
  }
}
