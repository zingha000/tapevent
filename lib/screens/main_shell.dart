import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dashboard_screen.dart';
import 'riwayat_screen.dart';
import 'saya_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  final _homeKey = GlobalKey<HomeScreenState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeKey),
      const DashboardScreen(),
      const RiwayatScreen(),
      const SayaScreen(),
    ];
  }

  void _onTabChanged(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _homeKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTabChanged,
        backgroundColor: context.surface,
        indicatorColor: AppColors.primary.withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: Icon(AppIcons.home, color: context.textSecondary),
            selectedIcon: Icon(AppIcons.home, color: AppColors.primary),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.dashboard, color: context.textSecondary),
            selectedIcon: Icon(AppIcons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.history, color: context.textSecondary),
            selectedIcon: Icon(AppIcons.history, color: AppColors.primary),
            label: 'Riwayat',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.profile, color: context.textSecondary),
            selectedIcon: Icon(AppIcons.profile, color: AppColors.primary),
            label: 'Saya',
          ),
        ],
      ),
    );
  }
}