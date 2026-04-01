import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:pet_app/core/providers/theme_provider.dart';
import 'package:pet_app/core/router/app_router.dart';
import 'package:pet_app/core/theme/app_theme.dart';
import 'package:pet_app/firebase_options.dart';

const String _streamApiKey = 'kc3jpc4tghbh';

/// Global Stream client — referenced from auth_provider and stream_service.
late final StreamChatClient streamClient;

/// Currently active channel ID — used to suppress duplicate notifications.
String? activeChannelId;

final FlutterLocalNotificationsPlugin _localNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> _setupLocalNotifications() async {
  const android = AndroidInitializationSettings('@drawable/ic_notification');
  const ios = DarwinInitializationSettings();
  await _localNotifications.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await _setupLocalNotifications();

  await _localNotifications
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
        'chat_messages',
        'Chat Messages',
        description: 'Notifications for new chat messages',
        importance: Importance.max,
      ));

  final data = message.data;
  final type = data['type'] ?? '';
  if (type != 'message.new') return;

  final senderName = data['sender_name'] ?? 'Someone';
  final channelName = data['channel_name'] ?? '';
  final messageText = data['message_text'] ?? 'sent a message';

  final title = channelName.isNotEmpty
      ? '$senderName @ $channelName'
      : 'New message from $senderName';

  final payload = json.encode({
    'channelId': data['channelId'] ?? '',
    'channelType': data['channelType'] ?? 'messaging',
  });

  await _localNotifications.show(
    message.hashCode,
    title,
    messageText,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'chat_messages',
        'Chat Messages',
        channelDescription: 'Notifications for new chat messages',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
      ),
    ),
    payload: payload,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    await _setupLocalNotifications();

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'chat_messages',
          'Chat Messages',
          description: 'Notifications for new chat messages',
          importance: Importance.max,
        ));
  }

  streamClient = StreamChatClient(_streamApiKey, logLevel: Level.INFO);

  runApp(ProviderScope(child: PetApp(streamClient: streamClient)));
}

class PetApp extends ConsumerStatefulWidget {
  const PetApp({super.key, required this.streamClient});
  final StreamChatClient streamClient;

  @override
  ConsumerState<PetApp> createState() => _PetAppState();
}

class _PetAppState extends ConsumerState<PetApp> {
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _setupForegroundNotifications();
    }
  }

  void _setupForegroundNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final data = message.data;
      if (data['type'] != 'message.new') return;
      if (data['channelId'] == activeChannelId) return;

      final senderName = data['sender_name'] ?? 'Someone';
      final channelName = data['channel_name'] ?? '';
      final messageText = data['message_text'] ?? 'sent a message';

      final title = channelName.isNotEmpty
          ? '$senderName @ $channelName'
          : 'New message from $senderName';

      final payload = json.encode({
        'channelId': data['channelId'] ?? '',
        'channelType': data['channelType'] ?? 'messaging',
      });

      await _localNotifications.show(
        message.hashCode,
        title,
        messageText,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'chat_messages',
            'Chat Messages',
            channelDescription: 'Notifications for new chat messages',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
        payload: payload,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Pet App',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.platformBrightnessOf(context) == Brightness.dark);

        return StreamChat(
          client: widget.streamClient,
          streamChatThemeData: isDark
              ? StreamChatThemeData.dark().copyWith(
                  colorTheme: StreamColorTheme.dark(
                    accentPrimary: const Color(0xFFfdd631),
                    appBg: const Color(0xFF121212),
                    barsBg: const Color(0xFF121212),
                    inputBg: const Color(0xFF1E1E1E),
                  ),
                  channelListHeaderTheme:
                      const StreamChannelListHeaderThemeData(
                    color: Color(0xFF121212),
                    titleStyle: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  channelPreviewTheme: const StreamChannelPreviewThemeData(
                    titleStyle: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w600,
                    ),
                    subtitleStyle: TextStyle(color: Color(0xFF94A3B8)),
                    avatarTheme: StreamAvatarThemeData(
                      constraints: BoxConstraints(
                        minWidth: 48,
                        maxWidth: 48,
                        minHeight: 48,
                        maxHeight: 48,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                  ownMessageTheme: StreamMessageThemeData(
                    messageBackgroundColor: Color(0xFFfdd631),
                    messageTextStyle: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                  ),
                  otherMessageTheme: StreamMessageThemeData(
                    messageBackgroundColor: Color(0xFF2A2A2A),
                    messageTextStyle: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 15,
                    ),
                  ),
                  messageInputTheme: StreamMessageInputThemeData(
                    inputBackgroundColor: const Color(0xFF1E1E1E),
                    activeBorderGradient: const LinearGradient(
                      colors: [Color(0xFFfdd631), Color(0xFFfdd631)],
                    ),
                    sendAnimationDuration: const Duration(milliseconds: 300),
                  ),
                )
              : StreamChatThemeData.light().copyWith(
                  colorTheme: StreamColorTheme.light(
                    accentPrimary: const Color(0xFFfdd631),
                  ),
                  channelListHeaderTheme:
                      const StreamChannelListHeaderThemeData(
                    color: Color(0xFFFFFFFF),
                    titleStyle: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  channelPreviewTheme: const StreamChannelPreviewThemeData(
                    titleStyle: TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                    ),
                    subtitleStyle: TextStyle(color: Color(0xFF64748B)),
                    avatarTheme: StreamAvatarThemeData(
                      constraints: BoxConstraints(
                        minWidth: 48,
                        maxWidth: 48,
                        minHeight: 48,
                        maxHeight: 48,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                  ),
                  ownMessageTheme: StreamMessageThemeData(
                    messageBackgroundColor: Color(0xFFfdd631),
                    messageTextStyle: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                  ),
                  otherMessageTheme: StreamMessageThemeData(
                    messageBackgroundColor: Color(0xFFF0F0F0),
                    messageTextStyle: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                    ),
                  ),
                  messageInputTheme: StreamMessageInputThemeData(
                    inputBackgroundColor: const Color(0xFFF0F0F0),
                    activeBorderGradient: const LinearGradient(
                      colors: [Color(0xFFfdd631), Color(0xFFfdd631)],
                    ),
                    sendAnimationDuration: const Duration(milliseconds: 300),
                  ),
                ),
          child: child!,
        );
      },
    );
  }
}
