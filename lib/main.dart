import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:workmanager/workmanager.dart';

import 'services/storage_service.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';
import 'screens/home_screen.dart';
import 'screens/chart_screen.dart';
import 'screens/signal_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/settings_screen.dart';
import 'background/alert_background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await StorageService().init();

  // Register WorkManager background task for price alerts
  // This runs even when the app is closed or the phone is locked
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  // Schedule periodic alert check every 15 minutes (minimum WorkManager interval)
  await Workmanager().registerPeriodicTask(
    'price-alert-check',
    kAlertCheckTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );

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

  void _onSymbolChanged(String symbol) async {
    await StorageService().setSelectedSymbol(symbol);
    setState(() => _activeSymbol = symbol);
  }

  @override
  Widget build(BuildContext context) {
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
