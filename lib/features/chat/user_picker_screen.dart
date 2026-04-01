import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/core/services/stream_service.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'chat_screen.dart';

class UserPickerScreen extends StatefulWidget {
  const UserPickerScreen({super.key});

  @override
  State<UserPickerScreen> createState() => _UserPickerScreenState();
}

class _UserPickerScreenState extends State<UserPickerScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _loadingUid;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _startChat(Map<String, dynamic> userData, String uid) async {
    setState(() => _loadingUid = uid);

    final currentUid = FirebaseAuth.instance.currentUser!.uid;
    final name = (userData['displayName'] as String?) ?? 'User';

    final channel = await StreamService.getOrCreateDirectChannel(
      currentUserId: currentUid,
      otherUserId: uid,
      otherUserName: name,
    );

    if (!mounted) return;
    setState(() => _loadingUid = null);

    if (channel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open chat. Try again.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StreamChannel(
          channel: channel,
          child: const ChatScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: const EdgeInsets.only(left: 12),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
          ),
        ),
        title: Text(
          'New Chat',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Search bar ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search people...',
                hintStyle: GoogleFonts.inter(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                filled: true,
                fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // ── User list ─────────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.inter(fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = (snapshot.data?.docs ?? [])
                    .where((doc) => doc.id != currentUid)
                    .where((doc) {
                  if (_query.isEmpty) return true;
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['displayName'] as String? ?? '').toLowerCase();
                  final email =
                      (data['email'] as String? ?? '').toLowerCase();
                  return name.contains(_query) || email.contains(_query);
                }).toList()
                  ..sort((a, b) {
                    final na = ((a.data() as Map)['displayName'] as String? ?? '').toLowerCase();
                    final nb = ((b.data() as Map)['displayName'] as String? ?? '').toLowerCase();
                    return na.compareTo(nb);
                  });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline_rounded,
                          size: 56,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _query.isEmpty
                              ? 'No other users found'
                              : 'No results for "$_query"',
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

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    indent: 72,
                    color:
                        isDark ? AppColors.borderDark : AppColors.borderLight,
                  ),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final data = doc.data() as Map<String, dynamic>;
                    final uid = doc.id;
                    final name = (data['displayName'] as String?) ?? 'User';
                    final email = (data['email'] as String?) ?? '';
                    final photoUrl = data['photoUrl'] as String?;
                    final isProvider = data['isProvider'] == true;
                    final isLoading = _loadingUid == uid;

                    return ListTile(
                      onTap: isLoading ? null : () => _startChat(data, uid),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary,
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              )
                            : null,
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                          if (isProvider)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Provider',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        email,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      trailing: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.chat_bubble_outline_rounded,
                              size: 20,
                              color: AppColors.primary,
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
