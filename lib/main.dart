import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://aujmkljqdkgqcrpvycis.supabase.co',
    publishableKey: 'sb_publishable_OxKqzjRhPAHOMn6GRKlNWg_6gyYVEBC',
  );

  runApp(const TapEventApp());
}

final supabase = Supabase.instance.client;

class TapEventApp extends StatelessWidget {
  const TapEventApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapEvent',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}