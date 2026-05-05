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
  StreamChannelListController? _controller;
  bool _initialized = false;
  bool _isConnecting = true;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initController();
  }

  Future<void> _initController() async {
    final client = StreamChat.of(context).client;

    // Wait for user to be connected to Stream (up to 15 seconds)
    debugPrint('ChatListScreen: Waiting for Stream user connection...');
    var connectionAttempts = 0;
    const maxConnectionAttempts = 30;

    while (connectionAttempts < maxConnectionAttempts) {
      final currentUserId = client.state.currentUser?.id;
      if (currentUserId != null && currentUserId.isNotEmpty) {
        debugPrint('ChatListScreen: Stream user found: $currentUserId');
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      connectionAttempts++;
    }

    if (!mounted) return;

    final currentUserId = client.state.currentUser?.id;
    if (currentUserId == null || currentUserId.isEmpty) {
      debugPrint('ChatListScreen: ERROR - No Stream user after waiting');
      setState(() {
        _error =
            'Chat connection failed. Please check your internet and retry.';
        _isConnecting = false;
      });
      return;
    }

    debugPrint('ChatListScreen: Creating controller for user: $currentUserId');

    _controller = StreamChannelListController(
      client: client,
      filter: Filter.in_('members', [currentUserId]),
      channelStateSort: const [SortOption.desc('last_message_at')],
      limit: 20,
    );

    // Try loading channels with retry
    var attempts = 0;
    const maxAttempts = 3;

    while (attempts < maxAttempts) {
      try {
        await _controller!.doInitialLoad();
        if (mounted) {
          setState(() => _isConnecting = false);
        }
        debugPrint('ChatListScreen: Channels loaded successfully');
        return;
      } on StreamChatError catch (e) {
        attempts++;
        debugPrint('ChatListScreen: Attempt $attempts failed: ${e.message}');

        if (attempts >= maxAttempts) {
          if (mounted) {
            setState(() {
              _error = e.message;
              _isConnecting = false;
            });
          }
          return;
        }

        await Future.delayed(Duration(seconds: attempts));
      } catch (e) {
        debugPrint('ChatListScreen: Error loading channels: $e');
        if (mounted) {
          setState(() {
            _error = e.toString();
            _isConnecting = false;
          });
        }
        return;
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });
    await _initController();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
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
      floatingActionButton: _isConnecting || _error != null
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserPickerScreen()),
              ),
              backgroundColor: AppColors.primary,
              foregroundColor: const Color(0xFF0F172A),
              child: const Icon(Icons.edit_rounded),
            ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isConnecting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Connecting to chat...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading channels',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _retry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return StreamChannelListView(
      controller: _controller!,
      onChannelTap: (channel) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                StreamChannel(channel: channel, child: const ChatScreen()),
          ),
        );
      },
    );
  }
}
