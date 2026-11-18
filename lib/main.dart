import 'package:flutter/material.dart';

import 'core/ml/tinybert_service.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TinyBertService.instance.initialize();
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
