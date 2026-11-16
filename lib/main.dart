import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/main_navigation.dart';

void main() {
  runApp(const VeloraApp());
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VELORA',
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}
