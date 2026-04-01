import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: const StreamChannelHeader(),
      body: const Column(
        children: [
          Expanded(child: StreamMessageListView()),
          StreamMessageInput(),
        ],
      ),
    );
  }
}

/// Thread/reply page
class ThreadPage extends StatelessWidget {
  const ThreadPage({super.key, required this.parent});
  final Message parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const StreamChannelHeader(),
      body: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              parentMessage: parent,
            ),
          ),
          const StreamMessageInput(),
        ],
      ),
    );
  }
}
