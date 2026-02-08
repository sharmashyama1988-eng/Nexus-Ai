
import 'package:flutter/material.dart';
import 'package:nexus_ai/services/storage_service.dart';
import 'package:nexus_ai/ui/auth_screen.dart';
import 'package:nexus_ai/ui/home_screen.dart';
import 'package:nexus_ai/utils/constants.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init();
  runApp(const NexusAIApp());
}

class NexusAIApp extends StatelessWidget {
  const NexusAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.accent,
          surface: AppColors.sidebar,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
        useMaterial3: true,
      ),
      home: const AuthScreen(),
    );
  }
}
