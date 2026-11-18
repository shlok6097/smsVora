import 'package:flutter/material.dart';

import 'core/ml/tinybert_service.dart';
import 'core/navigation/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/conversation_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TinyBertService.instance.initialize();
  await NotificationService.instance.initialize(
    onOpenConversation: (convId) {
      final conv = ConversationRepository.instance.getConversation(convId);
      if (conv != null) {
        AppRouter.navigatorKey.currentState?.pushNamed(
          AppRouter.thread,
          arguments: conv,
        );
      }
    },
    onReplySubmitted: (convId, replyText) {
      ConversationRepository.instance.addOutgoingReply(convId, replyText);
    },
  );

  runApp(const SmsVoraApp());
}

class SmsVoraApp extends StatelessWidget {
  const SmsVoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smsVora',
      navigatorKey: AppRouter.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.inbox,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
