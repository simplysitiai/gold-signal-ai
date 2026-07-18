import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'services/storage_service.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/signal_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';

/// Gold Signal AI — XAUUSD Gold Trading Indicator
///
/// Entry point for the app. Initializes services, configures the dark gold/black
/// Material Design 3 theme, and sets up bottom navigation across 5 screens.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mobile Ads SDK
  MobileAds.instance.initialize();

  // Initialize local storage
  await StorageService().init();

  runApp(const GoldSignalAIApp());
}

class GoldSignalAIApp extends StatelessWidget {
  const GoldSignalAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigation(),
    );
  }
}

/// Main navigation scaffold with bottom navigation bar.
///
/// Hosts 5 tabs: Home, Chart, Signal, Alerts, Settings.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ChartScreen(),
    SignalScreen(),
    AlertsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        backgroundColor: AppTheme.blackLight,
        indicatorColor: AppTheme.gold.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        height: 65,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppTheme.gold),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart, color: AppTheme.gold),
            label: 'Chart',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights, color: AppTheme.gold),
            label: 'Signal',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications, color: AppTheme.gold),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: AppTheme.gold),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
