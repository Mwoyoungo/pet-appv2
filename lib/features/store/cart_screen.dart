import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/providers/cart_provider.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder(CartState cart) async {
    if (_addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your delivery address'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _placing = true);
    try {
      // Fetch store to get ownerId and deliveryFee
      final storeDoc = await FirebaseFirestore.instance
          .collection('stores')
          .doc(cart.storeId)
          .get();
      final storeData = storeDoc.data() ?? <String, dynamic>{};
      final ownerId = storeData['ownerId'] as String? ?? '';
      final deliveryFee =
          (storeData['deliveryFee'] as num?)?.toDouble() ?? 0.0;
      final subtotal = cart.subtotal;
      final total = subtotal + deliveryFee;

      final items = cart.items.values
          .map((i) => {
                'productId': i.productId,
                'name': i.name,
                'price': i.price,
                'quantity': i.quantity,
                'imageUrl': i.imageUrl,
              })
          .toList();

      await FirebaseFirestore.instance.collection('storeOrders').add({
        'customerId': uid,
        'storeId': cart.storeId,
        'ownerId': ownerId,
        'storeName': cart.storeName,
        'items': items,
        'subtotal': subtotal,
        'deliveryFee': deliveryFee,
        'total': total,
        'deliveryAddress': _addressCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed! The store will confirm shortly.'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/orders');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cart = ref.watch(cartProvider);
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveContainer(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top),
            // Header
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Your Cart',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (!cart.isEmpty)
                    GestureDetector(
                      onTap: () =>
                          ref.read(cartProvider.notifier).clearCart(),
                      child: Text(
                        'Clear',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            if (cart.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.shopping_cart_outlined,
                          size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Your cart is empty',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Browse stores and add some items',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () => context.go('/store-list'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            'Browse Stores',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name
                      Text(
                        'From: ${cart.storeName}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Cart items
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: cart.items.values
                              .toList()
                              .asMap()
                              .entries
                              .map((e) {
                            final i = e.key;
                            final item = e.value;
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      // Product image
                                      ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        child: item.imageUrl != null
                                            ? Image.network(
                                                item.imageUrl!,
                                                width: 52,
                                                height: 52,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) =>
                                                        _ItemPlaceholder(),
                                              )
                                            : _ItemPlaceholder(),
                                      ),
                                      const SizedBox(width: 12),
                                      // Name + price
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              'R${item.price.toStringAsFixed(2)} each',
                                              style: GoogleFonts.inter(
                                                fontSize: 12,
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Quantity controls
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .decreaseItem(item.productId),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                  Icons.remove_rounded,
                                                  size: 16,
                                                  color: AppColors.primary),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 32,
                                            child: Text(
                                              '${item.quantity}',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => ref
                                                .read(cartProvider.notifier)
                                                .incrementItem(
                                                    item.productId),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: AppColors.primary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                  Icons.add_rounded,
                                                  size: 16,
                                                  color:
                                                      Color(0xFF0F172A)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (i < cart.items.length - 1)
                                  Divider(
                                      height: 1,
                                      indent: 16,
                                      color: borderColor),
                              ],
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Delivery address
                      Text(
                        'Delivery Address',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _addressCtrl,
                          style: GoogleFonts.inter(fontSize: 14),
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Enter your full delivery address',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: AppColors.primary, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Notes
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: TextField(
                          controller: _notesCtrl,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText:
                                'Special instructions (optional)',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                            prefixIcon: Icon(Icons.notes_rounded,
                                color: AppColors.primary, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Order summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(
                              label: 'Subtotal',
                              value: 'R${cart.subtotal.toStringAsFixed(2)}',
                              isDark: isDark,
                            ),
                            const SizedBox(height: 8),
                            _SummaryRow(
                              label: 'Delivery fee',
                              value: 'Loading...',
                              isDark: isDark,
                            ),
                            const Divider(height: 20),
                            _SummaryRow(
                              label: 'Total',
                              value: 'R${cart.subtotal.toStringAsFixed(2)}+',
                              isDark: isDark,
                              bold: true,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Place order button
                      GestureDetector(
                        onTap: _placing ? null : () => _placeOrder(cart),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _placing
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF0F172A),
                                    ),
                                  )
                                : Text(
                                    'Place Order',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
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
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 52,
        height: 52,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.inventory_2_rounded,
            color: AppColors.primary, size: 24),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
      {required this.label,
      required this.value,
      required this.isDark,
      this.bold = false});
  final String label, value;
  final bool isDark, bold;

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: bold ? null : textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? AppColors.primary : null,
          ),
        ),
      ],
    );
  }
}
