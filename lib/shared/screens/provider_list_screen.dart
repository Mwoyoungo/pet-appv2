import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/shared/widgets/provider_list_widgets.dart';

/// Generic provider list screen reused by all service types.
class ProviderListScreen extends StatefulWidget {
  const ProviderListScreen({
    super.key,
    required this.title,
    required this.serviceType,
    required this.emptyIcon,
    required this.emptyMessage,
    this.subtitle = '',
  });

  final String title;
  final String subtitle;
  final String serviceType;
  final IconData emptyIcon;
  final String emptyMessage;

  const ProviderListScreen.grooming({super.key})
      : title = 'Groomers',
        subtitle = '',
        serviceType = 'Grooming',
        emptyIcon = Icons.content_cut_rounded,
        emptyMessage = 'No groomers yet.\nBe the first to list grooming services!';

  const ProviderListScreen.sitting({super.key})
      : title = 'Pet Sitters',
        subtitle = '',
        serviceType = 'Sitting',
        emptyIcon = Icons.home_rounded,
        emptyMessage = 'No pet sitters yet.\nBe the first to list sitting services!';

  const ProviderListScreen.walking({super.key})
      : title = 'Pet Walkers',
        subtitle = '',
        serviceType = 'Walking',
        emptyIcon = Icons.directions_walk_rounded,
        emptyMessage = 'No pet walkers yet.\nBe the first to list walking services!';

  const ProviderListScreen.daycare({super.key})
      : title = 'Daycare',
        subtitle = '',
        serviceType = 'Daycare',
        emptyIcon = Icons.festival_rounded,
        emptyMessage = 'No daycare providers yet.\nBe the first to list daycare services!';

  const ProviderListScreen.training({super.key})
      : title = 'Trainers',
        subtitle = '',
        serviceType = 'Training',
        emptyIcon = Icons.sports_score_rounded,
        emptyMessage = 'No trainers yet.\nBe the first to list training services!';

  const ProviderListScreen.behaviorist({super.key})
      : title = 'Behaviorists',
        subtitle = 'Expert pet behaviour consultants',
        serviceType = 'Behaviorist',
        emptyIcon = Icons.psychology_rounded,
        emptyMessage = 'No behaviorists yet.\nBe the first to offer behaviorist services!';

  const ProviderListScreen.transport({super.key})
      : title = 'Pet Transport',
        subtitle = 'Safe & reliable pet transport',
        serviceType = 'Transport',
        emptyIcon = Icons.local_shipping_rounded,
        emptyMessage = 'No transport providers yet.\nBe the first to list transport services!';

  const ProviderListScreen.hydrotherapy({super.key})
      : title = 'Animal Hydrotherapy',
        subtitle = 'Water-based therapy for your pet',
        serviceType = 'Hydrotherapy',
        emptyIcon = Icons.pool_rounded,
        emptyMessage = 'No hydrotherapy providers yet.\nBe the first to list hydrotherapy services!';

  const ProviderListScreen.boarding({super.key})
      : title = 'Pet Boarding',
        subtitle = 'Safe overnight care for your pet',
        serviceType = 'Boarding',
        emptyIcon = Icons.night_shelter_rounded,
        emptyMessage = 'No boarding providers yet.\nBe the first to list boarding services!';

  @override
  State<ProviderListScreen> createState() => _ProviderListScreenState();
}

class _ProviderListScreenState extends State<ProviderListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveContainer(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  ProviderIconBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    isDark: isDark,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (widget.subtitle.isNotEmpty)
                        Text(
                          widget.subtitle,
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ProviderSearchField(
                controller: _searchCtrl,
                hint: 'Search ${widget.title.toLowerCase()}...',
                isDark: isDark,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('isProvider', isEqualTo: true)
                    .where('providerStatus', isEqualTo: 'approved')
                    .where('providerServiceTypes',
                        arrayContains: widget.serviceType)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    if (_query.isEmpty) return true;
                    final d = doc.data() as Map<String, dynamic>;
                    return (d['displayName'] as String? ?? '')
                        .toLowerCase()
                        .contains(_query);
                  }).toList();

                  if (docs.isEmpty) {
                    return ProviderEmptyState(
                      icon: widget.emptyIcon,
                      message: widget.emptyMessage,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final d = docs[i].data() as Map<String, dynamic>;
                      final uid = docs[i].id;
                      final prices = Map<String, dynamic>.from(
                          d['providerPrices'] ?? {});
                      final price = prices[widget.serviceType] != null
                          ? 'R${prices[widget.serviceType]}'
                          : (d['providerRate'] as String? ?? '');
                      return ProviderTile(
                        uid: uid,
                        name: d['displayName'] as String? ?? widget.title,
                        photoUrl: d['photoUrl'] as String?,
                        bio: d['providerBio'] as String? ?? '',
                        price: price,
                        serviceType: widget.serviceType,
                        isDark: isDark,
                        rating: (d['rating'] as num?)?.toDouble() ?? 0.0,
                        reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
