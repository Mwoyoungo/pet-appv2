import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'chat_screen.dart';
import 'user_picker_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  late final StreamChannelListController _controller;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final client = StreamChat.of(context).client;
    final currentUserId = client.state.currentUser?.id ?? '';

    _controller = StreamChannelListController(
      client: client,
      filter: Filter.in_('members', [currentUserId]),
      channelStateSort: const [SortOption.desc('last_message_at')],
      limit: 20,
    );
    _controller.doInitialLoad();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => context.go('/'),
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
          'Messages',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UserPickerScreen()),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.edit_rounded),
      ),
      body: StreamChannelListView(
        controller: _controller,
        onChannelTap: (channel) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StreamChannel(
                channel: channel,
                child: const ChatScreen(),
              ),
            ),
          );
        },
      ),
    );
  }
}
