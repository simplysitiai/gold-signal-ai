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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
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

/// Main navigation — holds the single source of truth for the active symbol.
/// All tabs receive the same symbol and call onSymbolChanged to update all tabs together.
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  String _activeSymbol = AppConstants.defaultSymbol;
  bool _symbolLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
  }

  Future<void> _loadSymbol() async {
    final sym = await StorageService().getSelectedSymbol();
    setState(() {
      _activeSymbol = sym;
      _symbolLoaded = true;
    });
  }

  /// Called by any tab when user picks a new symbol.
  /// Persists to storage and rebuilds all tabs with the new symbol.
  void _onSymbolChanged(String symbol) async {
    await StorageService().setSelectedSymbol(symbol);
    setState(() => _activeSymbol = symbol);
  }

  @override
  Widget build(BuildContext context) {
    // Don't render screens until symbol is loaded (avoids flash with wrong symbol)
    if (!_symbolLoaded) {
      return Scaffold(
        backgroundColor: AppTheme.black,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.gold),
        ),
      );
    }

    final screens = [
      HomeScreen(activeSymbol: _activeSymbol, onSymbolChanged: _onSymbolChanged),
      ChartScreen(activeSymbol: _activeSymbol, onSymbolChanged: _onSymbolChanged),
      SignalScreen(activeSymbol: _activeSymbol, onSymbolChanged: _onSymbolChanged),
      AlertsScreen(activeSymbol: _activeSymbol, onSymbolChanged: _onSymbolChanged),
      SettingsScreen(onSymbolChanged: _onSymbolChanged),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
