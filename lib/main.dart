import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgPrimary,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FlowDoApp());
}

class FlowDoApp extends StatelessWidget {
  const FlowDoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowDo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.bgPrimary,
        colorScheme: const ColorScheme.dark(
          primary: AppTheme.accent,
          surface: AppTheme.bgPrimary,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Color(0xF22D293A),
          contentTextStyle: TextStyle(color: AppTheme.textPrimary),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
