import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/shared/widgets/provider_list_widgets.dart';

class DaycareListScreen extends StatefulWidget {
  const DaycareListScreen({super.key});
  @override
  State<DaycareListScreen> createState() => _DaycareListScreenState();
}

class _DaycareListScreenState extends State<DaycareListScreen> {
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
                  Text(
                    'Daycare',
                    style: GoogleFonts.inter(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: ProviderSearchField(
                controller: _searchCtrl,
                hint: 'Search daycare...',
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
                    .where('providerServiceTypes', arrayContains: 'Daycare')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.primary));
                  }
                  final docs = (snapshot.data?.docs ?? []).where((doc) {
                    if (_query.isEmpty) return true;
                    final d = doc.data() as Map<String, dynamic>;
                    return (d['displayName'] as String? ?? '')
                        .toLowerCase()
                        .contains(_query);
                  }).toList();

                  if (docs.isEmpty) {
                    return const ProviderEmptyState(
                      icon: Icons.home_work_rounded,
                      message:
                          'No daycare providers yet.\nBe the first to offer daycare!',
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
                      final price = prices['Daycare'] != null
                          ? 'R${prices['Daycare']}'
                          : (d['providerRate'] as String? ?? '');
                      return ProviderTile(
                        uid: uid,
                        name: d['displayName'] as String? ?? 'Provider',
                        photoUrl: d['photoUrl'] as String?,
                        bio: d['providerBio'] as String? ?? '',
                        price: price,
                        serviceType: 'Daycare',
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
