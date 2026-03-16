import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'constants/app_constants.dart';
import 'providers/theme_provider.dart';
import 'screens/auth_landing_screen.dart';
import 'services/push_notification_service.dart';
import 'theme/app_theme.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class MallDashApp extends ConsumerStatefulWidget {
  const MallDashApp({super.key});

  @override
  ConsumerState<MallDashApp> createState() => _MallDashAppState();
}

class _MallDashAppState extends ConsumerState<MallDashApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService.instance.onAppReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).valueOrNull ?? ThemeMode.light;
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      home: const AuthLandingScreen(),
    );
  }
}
