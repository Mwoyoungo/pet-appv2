import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pet_app/core/models/product_model.dart';
import 'package:pet_app/core/models/store_model.dart';
import 'package:pet_app/core/models/store_order_model.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/utils/responsive.dart';

class MyStoreScreen extends StatefulWidget {
  const MyStoreScreen({super.key});

  @override
  State<MyStoreScreen> createState() => _MyStoreScreenState();
}

class _MyStoreScreenState extends State<MyStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final uid = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: ResponsiveContainer(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('stores')
              .where('ownerId', isEqualTo: uid)
              .limit(1)
              .snapshots(),
          builder: (context, snap) {
            final hasStore =
                snap.hasData && snap.data!.docs.isNotEmpty;
            final store = hasStore
                ? StoreModel.fromFirestore(snap.data!.docs.first)
                : null;

            return Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
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
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'My Store',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                if (!hasStore)
                  Expanded(
                    child: _CreateStorePrompt(isDark: isDark, uid: uid!),
                  )
                else
                  Expanded(
                    child: Column(
                      children: [
                        // Store summary card
                        _StoreSummaryCard(
                            store: store!, isDark: isDark),
                        const SizedBox(height: 8),
                        // Tab bar
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark
                                : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            indicator: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            labelColor: const Color(0xFF0F172A),
                            unselectedLabelColor: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            labelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w700, fontSize: 13),
                            unselectedLabelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w500, fontSize: 13),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Products'),
                              Tab(text: 'Orders'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: TabBarView(
                            controller: _tabCtrl,
                            children: [
                              _ProductsTab(
                                  store: store, isDark: isDark),
                              _OrdersTab(
                                  storeId: store.id, isDark: isDark),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Create store prompt ───────────────────────────────────────────────────────

class _CreateStorePrompt extends StatelessWidget {
  const _CreateStorePrompt({required this.isDark, required this.uid});
  final bool isDark;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.store_rounded,
                  color: AppColors.primary, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Open Your Pet Store',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a store, list your products, and start receiving orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    _StoreFormSheet(isDark: isDark, uid: uid),
              ),
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
                  child: Text(
                    'Create Store',
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

// ── Store summary card ────────────────────────────────────────────────────────

class _StoreSummaryCard extends StatelessWidget {
  const _StoreSummaryCard({required this.store, required this.isDark});
  final StoreModel store;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD631), Color(0xFFFF9B21)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Store image / avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: store.imageUrl != null
                  ? Image.network(store.imageUrl!,
                      width: 52, height: 52, fit: BoxFit.cover)
                  : Container(
                      width: 52,
                      height: 52,
                      color: Colors.black.withValues(alpha: 0.15),
                      child: const Icon(Icons.store_rounded,
                          color: Colors.white, size: 28),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    store.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF0F172A).withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            // Open/closed toggle
            GestureDetector(
              onTap: () {
                FirebaseFirestore.instance
                    .collection('stores')
                    .doc(store.id)
                    .update({'isOpen': !store.isOpen});
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: store.isOpen
                      ? Colors.green.withValues(alpha: 0.9)
                      : Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  store.isOpen ? 'Open' : 'Closed',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Edit store button
            GestureDetector(
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => _StoreFormSheet(
                    isDark: isDark,
                    uid: store.ownerId,
                    existing: store),
              ),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit_rounded,
                    size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Products tab ──────────────────────────────────────────────────────────────

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.store, required this.isDark});
  final StoreModel store;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('stores')
          .doc(store.id)
          .collection('products')
          .snapshots(),
      builder: (context, snap) {
        final products = (snap.data?.docs ?? [])
            .map((d) => ProductModel.fromFirestore(d, store.id))
            .toList();

        return Stack(
          children: [
            products.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 52, color: AppColors.primary),
                        const SizedBox(height: 12),
                        Text(
                          'No products yet',
                          style: GoogleFonts.inter(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap + to add your first product',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: products.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _ProductRow(
                      product: products[i],
                      store: store,
                      isDark: isDark,
                    ),
                  ),

            // FAB — add product
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _ProductFormSheet(
                      storeId: store.id, ownerId: store.ownerId, isDark: isDark),
                ),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF0F172A), size: 28),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow(
      {required this.product, required this.store, required this.isDark});
  final ProductModel product;
  final StoreModel store;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: product.imageUrl != null
                ? Image.network(product.imageUrl!,
                    width: 56, height: 56, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ProductImgPlaceholder())
                : _ProductImgPlaceholder(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  product.category,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                Text(
                  'R${product.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          // In-stock toggle
          GestureDetector(
            onTap: () => FirebaseFirestore.instance
                .collection('stores')
                .doc(store.id)
                .collection('products')
                .doc(product.id)
                .update({'inStock': !product.inStock}),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: product.inStock
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                product.inStock ? 'In Stock' : 'Out',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color:
                      product.inStock ? AppColors.primary : Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Edit
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => _ProductFormSheet(
                  storeId: store.id,
                  ownerId: store.ownerId,
                  isDark: isDark,
                  existing: product),
            ),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDark
                    : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit_rounded,
                  size: 16, color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 4),
          // Delete
          GestureDetector(
            onTap: () => _confirmDelete(context, product, store.id),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 16, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, ProductModel product, String storeId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('Remove "${product.name}" from your store?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('stores')
                  .doc(storeId)
                  .collection('products')
                  .doc(product.id)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ProductImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 56,
        height: 56,
        color: AppColors.primary.withValues(alpha: 0.1),
        child: const Icon(Icons.inventory_2_rounded,
            color: AppColors.primary, size: 24),
      );
}

// ── Orders tab ────────────────────────────────────────────────────────────────

class _OrdersTab extends StatelessWidget {
  const _OrdersTab({required this.storeId, required this.isDark});
  final String storeId;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('storeOrders')
          .where('storeId', isEqualTo: storeId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        final orders = (snap.data?.docs ?? [])
            .map((d) => StoreOrderModel.fromFirestore(d))
            .toList();

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long_outlined,
                    size: 52, color: AppColors.primary),
                const SizedBox(height: 12),
                Text(
                  'No orders yet',
                  style: GoogleFonts.inter(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) =>
              _OrderRow(order: orders[i], isDark: isDark),
        );
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.isDark});
  final StoreOrderModel order;
  final bool isDark;

  Color get _statusColor {
    switch (order.status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? AppColors.cardDark : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.items
                      .map((i) => '${i.quantity}x ${i.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  order.statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_rounded, size: 12, color: textSecondary),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  order.deliveryAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.inter(fontSize: 12, color: textSecondary),
                ),
              ),
              Text(
                'R${order.total.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          // Advance status button
          if (order.nextStatusLabel != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => FirebaseFirestore.instance
                        .collection('storeOrders')
                        .doc(order.id)
                        .update({'status': order.nextStatus}),
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          order.nextStatusLabel!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (order.status == 'pending') ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => FirebaseFirestore.instance
                        .collection('storeOrders')
                        .doc(order.id)
                        .update({'status': 'cancelled'}),
                    child: Container(
                      height: 36,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Center(
                        child: Text(
                          'Decline',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Store form bottom sheet ───────────────────────────────────────────────────

class _StoreFormSheet extends StatefulWidget {
  const _StoreFormSheet(
      {required this.isDark, required this.uid, this.existing});
  final bool isDark;
  final String uid;
  final StoreModel? existing;

  @override
  State<_StoreFormSheet> createState() => _StoreFormSheetState();
}

class _StoreFormSheetState extends State<_StoreFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _addrCtrl;
  late final TextEditingController _feeCtrl;
  late final TextEditingController _timeCtrl;
  String? _imageUrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _addrCtrl = TextEditingController(text: s?.address ?? '');
    _feeCtrl = TextEditingController(
        text: s?.deliveryFee != null
            ? s!.deliveryFee.toStringAsFixed(0)
            : '');
    _timeCtrl = TextEditingController(text: s?.deliveryTime ?? '30-45 min');
    _imageUrl = s?.imageUrl;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addrCtrl.dispose();
    _feeCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 900);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('stores/${widget.uid}/banner.jpg');
      await ref.putData(
        await picked.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _addrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store name and address are required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'ownerId': widget.uid,
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'address': _addrCtrl.text.trim(),
        'deliveryFee':
            double.tryParse(_feeCtrl.text.trim()) ?? 0.0,
        'deliveryTime': _timeCtrl.text.trim(),
        'imageUrl': _imageUrl,
        'isOpen': widget.existing?.isOpen ?? true,
        'rating': widget.existing?.rating ?? 0.0,
        'reviewCount': widget.existing?.reviewCount ?? 0,
      };

      if (widget.existing == null) {
        await FirebaseFirestore.instance.collection('stores').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.existing!.id)
            .update(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: EdgeInsets.fromLTRB(
          12, 0, 12, MediaQuery.of(context).viewInsets.bottom + 12),
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
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existing == null ? 'Create Store' : 'Edit Store',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            // Banner image picker
            GestureDetector(
              onTap: _pickImage,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _imageUrl != null
                    ? Image.network(_imageUrl!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover)
                    : Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded,
                                size: 36, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Add Store Banner',
                              style: GoogleFonts.inter(
                                  fontSize: 13, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            _Field(ctrl: _nameCtrl, hint: 'Store name *', icon: Icons.store_rounded, isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: _descCtrl, hint: 'Description', icon: Icons.description_rounded, isDark: isDark, maxLines: 2),
            const SizedBox(height: 10),
            _Field(ctrl: _addrCtrl, hint: 'Address / area *', icon: Icons.location_on_outlined, isDark: isDark),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _feeCtrl,
                    hint: 'Delivery fee (R)',
                    icon: Icons.delivery_dining_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    ctrl: _timeCtrl,
                    hint: 'Est. time (e.g. 30 min)',
                    icon: Icons.access_time_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
                              color: Color(0xFF0F172A)))
                      : Text(
                          widget.existing == null
                              ? 'Create Store'
                              : 'Save Changes',
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

// ── Product form bottom sheet ─────────────────────────────────────────────────

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet(
      {required this.storeId, required this.ownerId, required this.isDark, this.existing});
  final String storeId;
  final String ownerId;
  final bool isDark;
  final ProductModel? existing;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _catCtrl;
  String? _imageUrl;
  bool _inStock = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
        text: p?.price != null ? p!.price.toStringAsFixed(2) : '');
    _catCtrl = TextEditingController(text: p?.category ?? '');
    _imageUrl = p?.imageUrl;
    _inStock = p?.inStock ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _catCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 75, maxWidth: 600);
    if (picked == null) return;
    setState(() => _saving = true);
    try {
      final docId = widget.existing?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('stores/${widget.ownerId}/products/$docId.jpg');
      await ref.putData(
        await picked.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await ref.getDownloadURL();
      setState(() => _imageUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product name is required')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final data = {
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': double.tryParse(_priceCtrl.text.trim()) ?? 0.0,
        'category': _catCtrl.text.trim().isEmpty
            ? 'General'
            : _catCtrl.text.trim(),
        'imageUrl': _imageUrl,
        'inStock': _inStock,
      };
      final ref = FirebaseFirestore.instance
          .collection('stores')
          .doc(widget.storeId)
          .collection('products');
      if (widget.existing == null) {
        await ref.add(data);
      } else {
        await ref.doc(widget.existing!.id).update(data);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textSecondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: EdgeInsets.fromLTRB(
          12, 0, 12, MediaQuery.of(context).viewInsets.bottom + 12),
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
                  color: isDark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.existing == null ? 'Add Product' : 'Edit Product',
              style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            // Product image
            GestureDetector(
              onTap: _pickImage,
              child: _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(_imageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover),
                    )
                  : Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_rounded,
                              size: 28, color: AppColors.primary),
                          const SizedBox(height: 6),
                          Text('Add Product Image',
                              style: GoogleFonts.inter(
                                  fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            _Field(ctrl: _nameCtrl, hint: 'Product name *', icon: Icons.inventory_2_outlined, isDark: isDark),
            const SizedBox(height: 10),
            _Field(ctrl: _descCtrl, hint: 'Description', icon: Icons.description_outlined, isDark: isDark, maxLines: 2),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _Field(
                    ctrl: _priceCtrl,
                    hint: 'Price (R)',
                    icon: Icons.attach_money_rounded,
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Field(
                    ctrl: _catCtrl,
                    hint: 'Category',
                    icon: Icons.category_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('In Stock',
                    style:
                        GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF0F172A)))
                      : Text(
                          widget.existing == null
                              ? 'Add Product'
                              : 'Save Changes',
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

// ── Shared field widget ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.ctrl,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.maxLines = 1,
    this.keyboardType,
  });
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final bool isDark;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color:
                  isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
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
                horizontal: 16, vertical: 12),
          ),
        ),
      );
}
