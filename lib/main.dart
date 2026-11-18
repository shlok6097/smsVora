import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';

void main() {
  runApp(const SmsVoraApp());
}

class SmsVoraApp extends StatelessWidget {
  const SmsVoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smsVora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRouter.inbox,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
