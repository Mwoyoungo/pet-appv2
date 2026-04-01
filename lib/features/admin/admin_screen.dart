import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/providers/user_profile_provider.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        title: Text(
          'Admin Panel',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Container(
              color: isDark ? AppColors.cardDark : Colors.white,
              child: TabBar(
                labelStyle: GoogleFonts.inter(
                    fontWeight: FontWeight.w700, fontSize: 13),
                labelColor: AppColors.primary,
                unselectedLabelColor: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ProviderList(status: 'pending', isDark: isDark),
                  _ProviderList(status: 'approved', isDark: isDark),
                  _ProviderList(status: 'rejected', isDark: isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderList extends ConsumerWidget {
  const _ProviderList({
    required this.status,
    required this.isDark,
  });
  final String status;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isProvider', isEqualTo: true)
          .where('providerStatus', isEqualTo: status)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  status == 'pending'
                      ? Icons.hourglass_empty_rounded
                      : status == 'approved'
                          ? Icons.verified_rounded
                          : Icons.cancel_rounded,
                  size: 48,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(height: 12),
                Text(
                  'No $status providers',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final profile = UserProfile.fromFirestore(docs[i]);
            return _ProviderCard(profile: profile, isDark: isDark);
          },
        );
      },
    );
  }
}

class _ProviderCard extends ConsumerWidget {
  const _ProviderCard({
    required this.profile,
    required this.isDark,
  });
  final UserProfile profile;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = profile.providerStatus ?? 'pending';
    final statusColor = status == 'approved'
        ? const Color(0xFF22C55E)
        : status == 'rejected'
            ? AppColors.error
            : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  backgroundImage: profile.photoUrl != null
                      ? NetworkImage(profile.photoUrl!)
                      : null,
                  child: profile.photoUrl == null
                      ? Text(
                          profile.displayName.isNotEmpty
                              ? profile.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        profile.email,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                        color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info rows
            if (profile.phone != null && profile.phone!.isNotEmpty)
              _InfoRow(
                  icon: Icons.phone_outlined,
                  value: profile.phone!,
                  isDark: isDark),
            if (profile.address != null && profile.address!.isNotEmpty)
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  value: profile.address!,
                  isDark: isDark),
            if (profile.providerBio != null && profile.providerBio!.isNotEmpty)
              _InfoRow(
                  icon: Icons.info_outline_rounded,
                  value: profile.providerBio!,
                  isDark: isDark),
            if (profile.providerServiceTypes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: profile.providerServiceTypes
                    .map((s) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Text(
                            s,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],

            // Action buttons
            if (status == 'pending') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Approve',
                      color: const Color(0xFF22C55E),
                      icon: Icons.check_circle_outline_rounded,
                      onTap: () => _approve(context, ref),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Reject',
                      color: AppColors.error,
                      icon: Icons.cancel_outlined,
                      onTap: () => _reject(context, ref),
                    ),
                  ),
                ],
              ),
            ] else if (status == 'approved') ...[
              const SizedBox(height: 14),
              _ActionButton(
                label: 'Revoke Approval',
                color: AppColors.error,
                icon: Icons.remove_circle_outline_rounded,
                onTap: () => _reject(context, ref),
              ),
            ] else if (status == 'rejected') ...[
              const SizedBox(height: 14),
              _ActionButton(
                label: 'Approve',
                color: const Color(0xFF22C55E),
                icon: Icons.check_circle_outline_rounded,
                onTap: () => _approve(context, ref),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    debugPrint('ADMIN: Approve tapped for uid=${profile.uid}');
    try {
      debugPrint('ADMIN: Writing approved to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .update({'providerStatus': 'approved'});
      debugPrint('ADMIN: Firestore write success');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${profile.displayName} approved'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e, st) {
      debugPrint('ADMIN: Approve error: $e');
      debugPrint('ADMIN: Stack: $st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _reject(BuildContext context, WidgetRef ref) async {
    debugPrint('ADMIN: Reject tapped for uid=${profile.uid}');
    try {
      debugPrint('ADMIN: Writing rejected to Firestore...');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(profile.uid)
          .update({'providerStatus': 'rejected'});
      debugPrint('ADMIN: Firestore write success');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${profile.displayName} rejected'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e, st) {
      debugPrint('ADMIN: Reject error: $e');
      debugPrint('ADMIN: Stack: $st');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.value,
    required this.isDark,
  });
  final IconData icon;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
