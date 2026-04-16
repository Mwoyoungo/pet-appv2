import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/providers/theme_provider.dart';
import 'package:pet_app/core/utils/responsive.dart';
import 'package:pet_app/core/router/app_router.dart';
import 'package:pet_app/shared/widgets/bottom_nav_bar.dart';
import 'package:pet_app/shared/widgets/service_category_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _navIndex = 0;
  final _searchController = TextEditingController();

  final _services = const [
    _ServiceItem(Icons.emergency_rounded, 'Emergency\nClinics & Vets', true, 'emergency'),
    _ServiceItem(Icons.content_cut_rounded, 'Groomers', false, 'groomers'),
    _ServiceItem(Icons.night_shelter_rounded, 'Pet Sitter', false, 'sitters'),
    _ServiceItem(Icons.directions_run_rounded, 'Pet Walker', false, 'walkers'),
    _ServiceItem(Icons.festival_rounded, 'Daycare', false, 'daycare'),
    _ServiceItem(Icons.sports_score_rounded, 'Trainers', false, 'trainers'),
    _ServiceItem(Icons.shopping_bag_rounded, 'Pet Store & Adoption', false, 'store'),
    _ServiceItem(Icons.local_shipping_rounded, 'Pet Transpo', false, 'transport'),
    _ServiceItem(Icons.psychology_rounded, 'Behaviorist', false, 'behaviorist'),
    _ServiceItem(Icons.pool_rounded, 'Hydrotherapy', false, 'hydrotherapy'),
    _ServiceItem(Icons.shield_outlined, 'Pet Insurance', false, 'insurance'),
    _ServiceItem(Icons.night_shelter_rounded, 'Pet Boarding', false, 'boarding'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceTap(_ServiceItem item) {
    if (item.route == 'emergency') {
      context.push('/clinic/1');
    } else if (item.route == 'groomers') {
      context.push(AppRoutes.groomersList);
    } else if (item.route == 'sitters') {
      context.push(AppRoutes.sittersList);
    } else if (item.route == 'walkers') {
      context.push(AppRoutes.walkersList);
    } else if (item.route == 'daycare') {
      context.push(AppRoutes.daycareList);
    } else if (item.route == 'trainers') {
      context.push(AppRoutes.trainersList);
    } else if (item.route == 'store') {
      context.push(AppRoutes.storeList);
    } else if (item.route == 'transport') {
      context.push(AppRoutes.transportList);
    } else if (item.route == 'behaviorist') {
      context.push(AppRoutes.behavioristList);
    } else if (item.route == 'hydrotherapy') {
      context.push(AppRoutes.hydrotherapyList);
    } else if (item.route == 'insurance') {
      context.push(AppRoutes.petInsurance);
    } else if (item.route == 'boarding') {
      context.push(AppRoutes.boardingList);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);

    return Scaffold(
      body: ResponsiveContainer(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Status bar spacer
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 8,
                  ),
                ),

                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          isDark: isDark,
                        ),
                        const Spacer(),
                        Column(
                          children: [
                            Text(
                              'CURRENT LOCATION',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  'Sandton, ZA',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.expand_more_rounded,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        _CircleIconButton(
                          icon: Icons.notifications_none_rounded,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Pet Profile Card ─────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: _PetProfileCard(isDark: isDark),
                  ),
                ),

                // ── Search Bar ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _SearchBar(
                      controller: _searchController,
                      isDark: isDark,
                    ),
                  ),
                ),

                // ── Services Grid ────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Explore Services',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'SEE ALL',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1,
                        ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final item = _services[i];
                      return ServiceCategoryCard(
                        icon: item.icon,
                        label: item.label,
                        highlighted: item.highlighted,
                        comingSoon: item.route == null,
                        onTap: () => _onServiceTap(item),
                      );
                    }, childCount: _services.length),
                  ),
                ),
              ],
            ),

            // ── Bottom Nav ───────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: AppBottomNavBar(
                currentIndex: _navIndex,
                onTap: (i) {
                  setState(() => _navIndex = i);
                  if (i == 1) context.push(AppRoutes.chatList);
                  if (i == 2) context.push(AppRoutes.myBookings);
                  if (i == 3) context.push(AppRoutes.profile);
                },
              ),
            ),

            // ── Dark Mode Toggle ─────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 20,
              child: _DarkModeToggle(
                isDark: themeMode == ThemeMode.dark,
                onToggle: () => ref.read(themeProvider.notifier).toggle(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.isDark});
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20),
    );
  }
}

class _PetProfileCard extends StatelessWidget {
  const _PetProfileCard({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Glow blob
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            children: [
              // Avatar
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    'assets/banner.jpeg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.primary,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Pet ',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    TextSpan(
                      text: 'App',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _QuickAction(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Update',
                  ),
                  const SizedBox(width: 28),
                  _QuickAction(
                    icon: Icons.visibility_rounded,
                    label: 'Prototype',
                  ),
                  const SizedBox(width: 28),
                  _QuickAction(icon: Icons.settings_rounded, label: 'Settings'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.isDark});
  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search for services...',
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.primary,
            size: 22,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}

class _DarkModeToggle extends StatelessWidget {
  const _DarkModeToggle({required this.isDark, required this.onToggle});
  final bool isDark;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(
          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          size: 18,
          color: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem(this.icon, this.label, this.highlighted, this.route);
  final IconData icon;
  final String label;
  final bool highlighted;
  final String? route;
}
