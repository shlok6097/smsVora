import 'package:flutter/material.dart';

import '../../data/models/conversation.dart';
import '../../data/sample_data.dart';
import '../../features/compose/compose_screen.dart';
import '../../features/contact/contact_screen.dart';
import '../../features/inbox/inbox_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/thread/thread_screen.dart';

class AppRouter {
  AppRouter._();

  static const String inbox = '/inbox';
  static const String thread = '/thread';
  static const String compose = '/compose';
  static const String contact = '/contact';
  static const String settings = '/settings';

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case inbox:
        return _slideRoute(
          const InboxScreen(),
          routeSettings,
        );

      case thread:
        final conversation = routeSettings.arguments is Conversation
            ? routeSettings.arguments as Conversation
            : SampleData.conversations.first;
        return _slideRoute(
          ThreadScreen(conversation: conversation),
          routeSettings,
        );

      case compose:
        return _slideRoute(
          const ComposeScreen(),
          routeSettings,
        );

      case contact:
        final conversation = routeSettings.arguments is Conversation
            ? routeSettings.arguments as Conversation
            : SampleData.conversations.first;
        return _slideRoute(
          ContactScreen(conversation: conversation),
          routeSettings,
        );

      case settings:
        return _slideRoute(
          const SettingsScreen(),
          routeSettings,
        );

      default:
        return _slideRoute(
          const InboxScreen(),
          routeSettings,
        );
    }
  }

  static MaterialPageRoute<dynamic> _slideRoute(
    Widget page,
    RouteSettings routeSettings,
  ) {
    return MaterialPageRoute(
      builder: (_) => page,
      settings: routeSettings,
    );
  }
}
