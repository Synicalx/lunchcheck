import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage/hive_helper.dart';
import 'core/notifications/notification_helper.dart';
import 'core/state/app_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize storage and notifications
  await HiveHelper.init();
  await NotificationHelper.init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppStateProvider(),
      child: const LunchCheckApp(),
    ),
  );
}

class LunchCheckApp extends StatelessWidget {
  const LunchCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LunchCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AppStateProvider>(
        builder: (context, provider, _) {
          if (provider.settings.isOnboarded) {
            return const DashboardScreen();
          } else {
            return const OnboardingScreen();
          }
        },
      ),
    );
  }
}
