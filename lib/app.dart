import 'package:flutter/material.dart';

import 'constants/app_constants.dart';
import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

class MallDashApp extends StatelessWidget {
  const MallDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const LoginScreen(),
    );
  }
}
