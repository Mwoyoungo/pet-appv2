import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/models/product_model.dart';
import 'package:pet_app/core/models/store_model.dart';
import 'package:pet_app/core/providers/cart_provider.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';

class StoreDetailScreen extends ConsumerStatefulWidget {
  const StoreDetailScreen({super.key, required this.storeId});
  final String storeId;

  @override
  ConsumerState<StoreDetailScreen> createState() =>
      _StoreDetailScreenState();
}

class _StoreDetailScreenState extends ConsumerState<StoreDetailScreen> {
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveContainer(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .doc(widget.storeId)
              .snapshots(),
          builder: (context, storeSnap) {
            if (!storeSnap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            final store = StoreModel.fromFirestore(storeSnap.data!);

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('stores')
                  .doc(widget.storeId)
                  .collection('products')
                  .snapshots(),
              builder: (context, productsSnap) {
                final allProducts = (productsSnap.data?.docs ?? [])
                    .map((d) =>
                        ProductModel.fromFirestore(d, widget.storeId))
                    .toList();

                // Build category list
                final categories = [
                  'All',
                  ...{for (final p in allProducts) p.category},
                ];

                final filtered = _selectedCategory == 'All'
                    ? allProducts
                    : allProducts
                        .where((p) => p.category == _selectedCategory)
                        .toList();

                return Stack(
                  children: [
                    CustomScrollView(
                      slivers: [
                        // ── Store hero ──────────────────────────
                        SliverAppBar(
                          expandedHeight: 220,
                          pinned: true,
                          backgroundColor:
                              isDark ? AppColors.backgroundDark : Colors.white,
                          leading: Padding(
                            padding: const EdgeInsets.all(8),
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).maybePop(),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: Colors.white,
                                    size: 16),
                              ),
                            ),
                          ),
                          flexibleSpace: FlexibleSpaceBar(
                            background: store.imageUrl != null
                                ? Image.network(
                                    store.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _GradientBanner(),
                                  )
                                : _GradientBanner(),
                          ),
                        ),

                        // ── Store info ───────────────────────────
                        SliverToBoxAdapter(
                          child: Container(
                            color: isDark
                                ? AppColors.backgroundDark
                                : AppColors.backgroundLight,
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        store.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    if (!store.isOpen)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Closed',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (store.description != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    store.description!,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      height: 1.5,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    if (store.rating > 0) ...[
                                      const Icon(Icons.star_rounded,
                                          color: AppColors.primary, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${store.rating.toStringAsFixed(1)} (${store.reviewCount})',
                                        style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(width: 16),
                                    ],
                                    Icon(Icons.delivery_dining_rounded,
                                        size: 14,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      store.deliveryFee == 0
                                          ? 'Free delivery'
                                          : 'R${store.deliveryFee.toStringAsFixed(0)} delivery',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Icon(Icons.access_time_rounded,
                                        size: 14,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondaryLight),
                                    const SizedBox(width: 4),
                                    Text(
                                      store.deliveryTime,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
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
                        ),

                        // ── Category filter ──────────────────────
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: categories.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (_, i) {
                                final cat = categories[i];
                                final selected = cat == _selectedCategory;
                                return GestureDetector(
                                  onTap: () => setState(
                                      () => _selectedCategory = cat),
                                  child: AnimatedContainer(
                                    duration:
                                        const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.surfaceDark
                                              : AppColors.surfaceLight),
                                      borderRadius:
                                          BorderRadius.circular(50),
                                    ),
                                    child: Text(
                                      cat,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: selected
                                            ? const Color(0xFF0F172A)
                                            : (isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors
                                                    .textSecondaryLight),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 16)),

                        // ── Product grid ─────────────────────────
                        filtered.isEmpty
                            ? SliverToBoxAdapter(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(top: 60),
                                  child: Center(
                                    child: Text(
                                      'No products in this category yet.',
                                      style: GoogleFonts.inter(
                                          fontSize: 14),
                                    ),
                                  ),
                                ),
                              )
                            : SliverPadding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 120),
                                sliver: SliverGrid(
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (ctx, i) => _ProductCard(
                                      product: filtered[i],
                                      store: store,
                                      isDark: isDark,
                                    ),
                                    childCount: filtered.length,
                                  ),
                                ),
                              ),
                      ],
                    ),

                    // ── Floating cart button ─────────────────────
                    if (!cart.isEmpty)
                      Positioned(
                        bottom: 24,
                        left: 20,
                        right: 20,
                        child: GestureDetector(
                          onTap: () => context.push('/cart'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A)
                                        .withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${cart.totalItems}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'View Cart',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Text(
                                  'R${cart.subtotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _GradientBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFD631), Color(0xFFFF9B21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.shopping_bag_rounded,
              size: 64, color: Colors.white),
        ),
      );
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({
    required this.product,
    required this.store,
    required this.isDark,
  });
  final ProductModel product;
  final StoreModel store;
  final bool isDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final qty = cart.quantityOf(product.id);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            child: product.imageUrl != null
                ? Image.network(
                    product.imageUrl!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _ProductPlaceholder(isDark: isDark),
                  )
                : _ProductPlaceholder(isDark: isDark),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (product.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      product.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'R${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      // Add / quantity control
                      if (!product.inStock)
                        Text(
                          'Out of stock',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (qty == 0)
                        GestureDetector(
                          onTap: () {
                            if (ref.read(cartProvider.notifier).wouldClearCart(store.id)) {
                              _showClearCartDialog(context, ref, product);
                            } else {
                              ref
                                  .read(cartProvider.notifier)
                                  .addItem(product, store.id, store.name);
                            }
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.add_rounded,
                                size: 18, color: Color(0xFF0F172A)),
                          ),
                        )
                      else
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .decreaseItem(product.id),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.remove_rounded,
                                    size: 14, color: AppColors.primary),
                              ),
                            ),
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$qty',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => ref
                                  .read(cartProvider.notifier)
                                  .addItem(product, store.id, store.name),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.add_rounded,
                                    size: 14, color: Color(0xFF0F172A)),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog(
      BuildContext context, WidgetRef ref, ProductModel product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Start new cart?'),
        content: Text(
          'Your cart has items from ${store.name}. '
          'Adding this item will clear your current cart.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(cartProvider.notifier).clearCart();
              ref
                  .read(cartProvider.notifier)
                  .addItem(product, store.id, store.name);
            },
            child: const Text('Start New Cart',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  const _ProductPlaceholder({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) => Container(
        height: 120,
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        child: const Center(
          child: Icon(Icons.inventory_2_rounded,
              size: 36, color: AppColors.primary),
        ),
      );
}
