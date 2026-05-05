import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pet_app/core/theme/app_colors.dart';
import 'package:pet_app/main.dart' show activeChannelId;
import 'package:stream_chat_flutter/stream_chat_flutter.dart';

/// Full-screen chat view for a single channel.
/// Must be wrapped with [StreamChannel] by the caller.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final channel = StreamChannel.of(context).channel;
    activeChannelId = channel.id;
  }

  @override
  void dispose() {
    activeChannelId = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const StreamChannelHeader(),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              messageBuilder: (context, details, messages, defaultMessage) {
                return defaultMessage.copyWith(
                  attachmentBuilders: [
                    VoiceAttachmentBuilder(isDark: isDark),
                    ...StreamAttachmentWidgetBuilder.defaultBuilders(
                      message: details.message,
                    ),
                  ],
                );
              },
            ),
          ),
          const StreamMessageInput(
            enableVoiceRecording: true,
            sendVoiceRecordingAutomatically: true,
          ),
        ],
      ),
    );
  }
}

/// Custom voice/audio attachment builder for Stream SDK
class VoiceAttachmentBuilder extends StreamAttachmentWidgetBuilder {
  final bool isDark;
  const VoiceAttachmentBuilder({required this.isDark});

  @override
  Widget build(
    BuildContext context,
    Message message,
    Map<String, List<Attachment>> attachments,
  ) {
    final audioAttachments = attachments['audio'] ?? attachments['voicenote'];
    if (audioAttachments == null || audioAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return VoiceAttachmentWidget(
      attachment: audioAttachments.first,
      isDark: isDark,
    );
  }

  @override
  bool canHandle(Message message, Map<String, List<Attachment>> attachments) {
    return (attachments['audio'] != null && attachments['audio']!.isNotEmpty) ||
        (attachments['voicenote'] != null &&
            attachments['voicenote']!.isNotEmpty);
  }
}

/// Custom voice/audio attachment widget
class VoiceAttachmentWidget extends StatefulWidget {
  final Attachment attachment;
  final bool isDark;

  const VoiceAttachmentWidget({
    super.key,
    required this.attachment,
    required this.isDark,
  });

  @override
  State<VoiceAttachmentWidget> createState() => _VoiceAttachmentWidgetState();
}

class _VoiceAttachmentWidgetState extends State<VoiceAttachmentWidget> {
  late AudioPlayer _player;
  bool _isPlaying = false;
  bool _isBufferring = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    
    // Listen to player state changes
    _player.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isBufferring = state.processingState == ProcessingState.buffering ||
              state.processingState == ProcessingState.loading;
        });
        
        // Reset when finished
        if (state.processingState == ProcessingState.completed) {
          _player.stop();
          _player.seek(Duration.zero);
        }
      }
    });

    // Listen to position changes
    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    // Listen to duration changes
    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    final url = widget.attachment.assetUrl ?? widget.attachment.imageUrl;
    if (url == null) return;

    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        if (_player.processingState == ProcessingState.idle) {
          await _player.setUrl(url);
        }
        await _player.play();
      }
    } catch (e) {
      debugPrint('Failed to play audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to play voice message')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If assetUrl is null, the attachment is still uploading
    final isUploading = widget.attachment.assetUrl == null;

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (isUploading || _isBufferring)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                IconButton(
                  icon: Icon(_isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                  onPressed: _togglePlayback,
                  color: AppColors.primary,
                  iconSize: 28,
                ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: widget.isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    thumbColor: AppColors.primary,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble() > 0
                        ? _duration.inMilliseconds.toDouble()
                        : 1.0,
                    onChanged: (v) {
                      _player.seek(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(
                  Icons.mic_rounded,
                  size: 14,
                  color: widget.isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  _isPlaying ? 'Playing...' : 'Voice message',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDuration(
                    (_isPlaying || _position != Duration.zero)
                        ? _position.inSeconds
                        : (widget.attachment.extraData['duration'] as int? ?? 0),
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: widget.isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }
}

/// Thread/reply page
class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.parent});
  final Message parent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: const StreamChannelHeader(),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              parentMessage: parent,
              messageBuilder: (context, details, messages, defaultMessage) {
                return defaultMessage.copyWith(
                  attachmentBuilders: [
                    VoiceAttachmentBuilder(isDark: isDark),
                    ...StreamAttachmentWidgetBuilder.defaultBuilders(
                      message: details.message,
                    ),
                  ],
                );
              },
            ),
          ),
          const StreamMessageInput(
            enableVoiceRecording: true,
            sendVoiceRecordingAutomatically: true,
          ),
        ],
      ),
    );
  }
}
