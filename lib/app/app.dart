import 'package:flutter/material.dart';

import '../core/navigation/main_navigation.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/screens/auth_gate.dart';

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VELORA',
      theme: AppTheme.lightTheme,
      home: AuthGate(signedInBuilder: (_) => const MainNavigation()),
    );
  }
}
