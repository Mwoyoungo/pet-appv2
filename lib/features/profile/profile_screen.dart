import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/core/providers/auth_provider.dart';
import 'package:pet_app/core/providers/user_profile_provider.dart';

const _kPlacesApiKey = String.fromEnvironment(
  'PLACES_API_KEY',
  defaultValue: 'AIzaSyBEoSMqK92ssKk95xH5ZLFgEt04pFDjHEw',
);

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      body: ResponsiveContainer(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: profileAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (profile) {
              if (profile == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🐾', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text(
                        'Please log in to view your profile',
                        style: GoogleFonts.inter(fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: const Color(0xFF0F172A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Sign In',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return _ProfileContent(profile: profile, isDark: isDark);
            },
          ),
        ),
      ),
    );
  }
}

// ── Main profile content ─────────────────────────────────────────────────────

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.isDark});
  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        // ── Hero header ──────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: _ProfileHero(profile: profile, isDark: isDark),
        ),

        // ── Stats row ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: _StatsRow(isDark: isDark, uid: profile.uid),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 28)),

        // ── Pet card ────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _PetCard(profile: profile, isDark: isDark),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Menu items ───────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _MenuSection(isDark: isDark, profile: profile, ref: ref),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ── Hero header ──────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.isDark});
  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          height: 240,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                const Color(0xFFFF9B21),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Blobs
        Positioned(
          top: -30,
          right: -20,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 10,
          left: -40,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Content
        Positioned.fill(
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Back button
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            width: 38,
                            height: 38,
                            color: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Avatar
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: profile.photoUrl != null
                          ? ClipOval(
                              child: Image.network(
                                profile.photoUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Center(
                              child: Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.inter(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _pickAndUploadPhoto(context, profile),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  profile.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.email,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadPhoto(BuildContext context, UserProfile profile) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 600,
    );
    if (picked == null) return;

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/profile.jpg');
      await ref.putData(
        await picked.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'photoUrl': url});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo updated!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ── Stats row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.isDark, required this.uid});
  final bool isDark;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Transform.translate(
          offset: const Offset(0, -20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                _StatCell(value: '$count', label: 'Bookings', isDark: isDark),
                _Divider(),
                const _StatCell(value: '0', label: 'Favourites', isDark: false),
                _Divider(),
                const _StatCell(value: '0', label: 'Reviews', isDark: false),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    color: AppColors.borderDark.withValues(alpha: 0.4),
  );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    required this.isDark,
  });
  final String value, label;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondaryDark,
          ),
        ),
      ],
    ),
  );
}

// ── Pet card ─────────────────────────────────────────────────────────────────

class _PetCard extends StatelessWidget {
  const _PetCard({required this.profile, required this.isDark});
  final UserProfile profile;
  final bool isDark;

  String get _petEmoji {
    switch ((profile.petType ?? '').toLowerCase()) {
      case 'cat':
        return '🐱';
      case 'bird':
        return '🦜';
      case 'rabbit':
        return '🐰';
      default:
        return '🐶';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPet = profile.petName != null && profile.petName!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(_petEmoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: hasPet
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.petName!,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (profile.petBreed != null) profile.petBreed!,
                          if (profile.petAge != null) '${profile.petAge} old',
                        ].join(' · '),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  )
                : Text(
                    'Add your pet details',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
          ),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (_) =>
                  _EditProfileSheet(profile: profile, isDark: isDark),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                hasPet ? 'Edit' : 'Add',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu section ─────────────────────────────────────────────────────────────

class _MenuSection extends StatelessWidget {
  const _MenuSection({
    required this.isDark,
    required this.profile,
    required this.ref,
  });
  final bool isDark;
  final UserProfile profile;
  final WidgetRef ref;

  void _showProviderSheet(
    BuildContext context,
    UserProfile profile,
    WidgetRef ref,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProviderSheet(profile: profile, isDark: isDark, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          items: [
            _MenuItem(
              icon: Icons.calendar_today_rounded,
              iconColor: AppColors.primary,
              label: 'My Bookings',
              onTap: () => context.push('/bookings'),
            ),
            _MenuItem(
              icon: Icons.store_rounded,
              iconColor: const Color(0xFFFF9B21),
              label: 'My Store',
              onTap: () => context.push('/my-store'),
            ),
            if (profile.isAdmin)
              _MenuItem(
                icon: Icons.admin_panel_settings_rounded,
                iconColor: const Color(0xFFEF4444),
                label: 'Admin Panel',
                onTap: () => context.push('/admin'),
              ),
            _MenuItem(
              icon: Icons.favorite_rounded,
              iconColor: const Color(0xFFEF4444),
              label: 'Saved Providers',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.notifications_outlined,
              iconColor: const Color(0xFF8B5CF6),
              label: 'Notifications',
              onTap: () {},
            ),
          ],
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        Text(
          'Preferences',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          items: [
            _MenuItem(
              icon: Icons.dark_mode_outlined,
              iconColor: const Color(0xFF6366F1),
              label: 'Appearance',
              trailing: Text(
                'Dark',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.language_rounded,
              iconColor: const Color(0xFF06B6D4),
              label: 'Language',
              trailing: Text(
                'English',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              onTap: () {},
            ),
          ],
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // ── Provider toggle ───────────────────────────────────────────
        GestureDetector(
          onTap: () => _showProviderSheet(context, profile, ref),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: profile.isApprovedProvider
                    ? [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.05),
                      ]
                    : profile.isPendingApproval
                        ? [
                            const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            const Color(0xFFF59E0B).withValues(alpha: 0.05),
                          ]
                        : profile.isRejectedProvider
                            ? [
                                AppColors.error.withValues(alpha: 0.12),
                                AppColors.error.withValues(alpha: 0.04),
                              ]
                            : [
                                const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                              ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: profile.isApprovedProvider
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : profile.isPendingApproval
                        ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                        : profile.isRejectedProvider
                            ? AppColors.error.withValues(alpha: 0.3)
                            : const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: profile.isApprovedProvider
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : profile.isPendingApproval
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.15)
                            : profile.isRejectedProvider
                                ? AppColors.error.withValues(alpha: 0.12)
                                : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    profile.isApprovedProvider
                        ? Icons.verified_rounded
                        : profile.isPendingApproval
                            ? Icons.hourglass_top_rounded
                            : profile.isRejectedProvider
                                ? Icons.cancel_rounded
                                : Icons.add_business_rounded,
                    color: profile.isApprovedProvider
                        ? AppColors.primary
                        : profile.isPendingApproval
                            ? const Color(0xFFF59E0B)
                            : profile.isRejectedProvider
                                ? AppColors.error
                                : const Color(0xFF8B5CF6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.isApprovedProvider
                            ? 'Active Provider'
                            : profile.isPendingApproval
                                ? 'Pending Approval'
                                : profile.isRejectedProvider
                                    ? 'Application Rejected'
                                    : 'Become a Provider',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        profile.isApprovedProvider
                            ? 'You are listed as a service provider'
                            : profile.isPendingApproval
                                ? 'Your application is under review'
                                : profile.isRejectedProvider
                                    ? 'Tap to update and resubmit'
                                    : 'Offer your services to pet owners',
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
                Icon(
                  Icons.chevron_right_rounded,
                  color: profile.isApprovedProvider
                      ? AppColors.primary
                      : profile.isPendingApproval
                          ? const Color(0xFFF59E0B)
                          : profile.isRejectedProvider
                              ? AppColors.error
                              : const Color(0xFF8B5CF6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Support',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 12),
        _MenuCard(
          items: [
            _MenuItem(
              icon: Icons.help_outline_rounded,
              iconColor: const Color(0xFF10B981),
              label: 'Help & Support',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.privacy_tip_outlined,
              iconColor: const Color(0xFF64748B),
              label: 'Privacy Policy',
              onTap: () {},
            ),
          ],
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        // Sign out
        GestureDetector(
          onTap: () async {
            await ref.read(authProvider.notifier).signOut();
            if (context.mounted) context.go('/login');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sign Out',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items, required this.isDark});
  final List<_MenuItem> items;
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.cardDark : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    ),
    child: Column(
      children: items.asMap().entries.map((e) {
        final i = e.key;
        final item = e.value;
        return Column(
          children: [
            GestureDetector(
              onTap: item.onTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 18),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.label,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (item.trailing != null) ...[
                      item.trailing!,
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              Divider(
                height: 1,
                indent: 66,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
          ],
        );
      }).toList(),
    ),
  );
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.trailing,
  });
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
}

// ── Edit Profile Bottom Sheet ────────────────────────────────────────────────

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet({required this.profile, required this.isDark});
  final UserProfile profile;
  final bool isDark;

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _petNameCtrl;
  late final TextEditingController _petBreedCtrl;
  late final TextEditingController _petAgeCtrl;
  String _petType = 'Dog';
  bool _saving = false;

  final _petTypes = ['Dog', 'Cat', 'Bird', 'Rabbit', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.profile.displayName);
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.profile.address ?? '');
    _petNameCtrl = TextEditingController(text: widget.profile.petName ?? '');
    _petBreedCtrl = TextEditingController(text: widget.profile.petBreed ?? '');
    _petAgeCtrl = TextEditingController(text: widget.profile.petAge ?? '');
    _petType = widget.profile.petType ?? 'Dog';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _petNameCtrl.dispose();
    _petBreedCtrl.dispose();
    _petAgeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.profile.copyWith(
        displayName: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        petName: _petNameCtrl.text.trim(),
        petBreed: _petBreedCtrl.text.trim(),
        petAge: _petAgeCtrl.text.trim(),
        petType: _petType,
      );
      await ref.read(profileNotifierProvider.notifier).updateProfile(updated);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      margin: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),

            // ── Personal info ─────────────────────────────────────────
            _SheetLabel('Your Details', isDark: isDark),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _nameCtrl,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _phoneCtrl,
              hint: 'Phone number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _addressCtrl,
              hint: 'Address',
              icon: Icons.location_on_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: 20),

            // ── Pet info ──────────────────────────────────────────────
            _SheetLabel('Your Pet', isDark: isDark),
            const SizedBox(height: 10),
            // Pet type chips
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _petTypes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final t = _petTypes[i];
                  final sel = _petType == t;
                  return GestureDetector(
                    onTap: () => setState(() => _petType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: sel
                            ? AppColors.primary
                            : (isDark
                                  ? AppColors.surfaceDark
                                  : AppColors.surfaceLight),
                        borderRadius: BorderRadius.circular(50),
                        border: sel
                            ? null
                            : Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                              ),
                      ),
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: sel
                              ? const Color(0xFF0F172A)
                              : (isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _petNameCtrl,
              hint: 'Pet name',
              icon: Icons.pets_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _petBreedCtrl,
              hint: 'Breed',
              icon: Icons.category_outlined,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
            _SheetField(
              ctrl: _petAgeCtrl,
              hint: 'Age (e.g. 2 years)',
              icon: Icons.cake_outlined,
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // ── Save button ───────────────────────────────────────────
            GestureDetector(
              onTap: _saving ? null : _save,
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
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : Text(
                          'Save Changes',
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
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.label, {required this.isDark});
  final String label;
  final bool isDark;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: isDark
          ? AppColors.textSecondaryDark
          : AppColors.textSecondaryLight,
    ),
  );
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
  });
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

class _AddressAutocompleteField extends StatefulWidget {
  const _AddressAutocompleteField({
    required this.controller,
    required this.isDark,
  });
  final TextEditingController controller;
  final bool isDark;

  @override
  State<_AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState extends State<_AddressAutocompleteField> {
  List<String> _suggestions = [];
  Timer? _debounce;
  bool _showSuggestions = false;

  Future<void> _fetchSuggestions(String input) async {
    if (input.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    if (_kPlacesApiKey == 'YOUR_GOOGLE_PLACES_API_KEY') {
      // No API key configured — skip autocomplete
      return;
    }
    try {
      final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
        'input': input,
        'key': _kPlacesApiKey,
        'types': 'address',
      });
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final predictions = data['predictions'] as List<dynamic>? ?? [];
        setState(() {
          _suggestions = predictions
              .map((p) => p['description'] as String)
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: '123 Main St, Sandton',
              hintStyle: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              prefixIcon: const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
            onChanged: (val) {
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                _fetchSuggestions(val);
              });
            },
            onTap: () {
              if (_suggestions.isNotEmpty) {
                setState(() => _showSuggestions = true);
              }
            },
          ),
        ),
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _suggestions.map((s) {
                return GestureDetector(
                  onTap: () {
                    widget.controller.text = s;
                    setState(() {
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            s,
                            style: GoogleFonts.inter(fontSize: 13),
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  const _SheetField({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.borderLight,
      ),
    ),
    child: TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    ),
  );
}

// ── Provider setup bottom sheet ──────────────────────────────────────────────

class _ProviderSheet extends ConsumerStatefulWidget {
  const _ProviderSheet({
    required this.profile,
    required this.isDark,
    required this.ref,
  });
  final UserProfile profile;
  final bool isDark;
  final WidgetRef ref;

  @override
  ConsumerState<_ProviderSheet> createState() => _ProviderSheetState();
}

class _ProviderSheetState extends ConsumerState<_ProviderSheet> {
  late final TextEditingController _bioCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late List<String> _selectedServices;
  late Map<String, TextEditingController> _priceControllers;
  bool _saving = false;

  static const _allServices = [
    'Grooming', 'Walking', 'Daycare', 'Training', 'Sitting',
    'Behaviorist', 'Transport', 'Hydrotherapy', 'Boarding',
  ];

  @override
  void initState() {
    super.initState();
    _bioCtrl = TextEditingController(text: widget.profile.providerBio ?? '');
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.profile.address ?? '');
    _selectedServices = List.from(widget.profile.providerServiceTypes);
    _priceControllers = {
      for (final s in _allServices)
        s: TextEditingController(
          text: widget.profile.providerPrices[s]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    for (final c in _priceControllers.values) { c.dispose(); }
    super.dispose();
  }

  Future<void> _save() async {
    final phone = _phoneCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Phone number is required'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Address is required'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    if (_selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Select at least one service'),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _saving = true);
    final prices = <String, int>{};
    for (final s in _selectedServices) {
      final val = int.tryParse(_priceControllers[s]?.text.trim() ?? '');
      if (val != null && val > 0) prices[s] = val;
    }
    try {
      await ref.read(profileNotifierProvider.notifier).updateProviderInfo(
        widget.profile.uid,
        bio: _bioCtrl.text.trim(),
        serviceTypes: _selectedServices,
        prices: prices,
        phone: phone,
        address: address,
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Application submitted! Awaiting admin approval.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .toggleProvider(widget.profile.uid, false);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      margin: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(32),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 20),
            Text(
              widget.profile.isProvider
                  ? 'Provider Settings'
                  : 'Become a Provider',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Other pet owners will be able to book you for these services.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),

            // Phone number
            _SheetLabel('Phone number *', isDark: isDark),
            const SizedBox(height: 8),
            _SheetTextField(
              controller: _phoneCtrl,
              hint: '+27 82 000 0000',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Address with autocomplete
            _SheetLabel('Service address *', isDark: isDark),
            const SizedBox(height: 8),
            _AddressAutocompleteField(
              controller: _addressCtrl,
              isDark: isDark,
            ),
            const SizedBox(height: 16),

            // Services offered
            Text(
              'Services you offer',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allServices.map((s) {
                final sel = _selectedServices.contains(s);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (sel) {
                      _selectedServices.remove(s);
                    } else {
                      _selectedServices.add(s);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.primary
                          : (isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight),
                      borderRadius: BorderRadius.circular(50),
                      border: sel
                          ? null
                          : Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                    ),
                    child: Text(
                      s,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: sel
                            ? const Color(0xFF0F172A)
                            : (isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bio
            _SheetLabel('Your bio', isDark: isDark),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: TextField(
                controller: _bioCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tell pet owners about yourself...',
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Per-service prices in Rands
            if (_selectedServices.isNotEmpty) ...[
              _SheetLabel('Your prices (in Rands)', isDark: isDark),
              const SizedBox(height: 10),
              ..._selectedServices.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    ),
                  ),
                  child: TextField(
                    controller: _priceControllers[s],
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '$s price',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 14, right: 4),
                        child: Text(
                          'R',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              )),
            ],
            const SizedBox(height: 24),

            // Save button
            GestureDetector(
              onTap: _saving ? null : _save,
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
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF0F172A),
                          ),
                        )
                      : Text(
                          'Save Provider Profile',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                ),
              ),
            ),
            if (widget.profile.isProvider) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _saving ? null : _disable,
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Stop Offering Services',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Firestore booking count helper ───────────────────────────────────────────
class FirestoreBookingCount {
  static Stream<int> stream(String uid) {
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.length);
  }
}
