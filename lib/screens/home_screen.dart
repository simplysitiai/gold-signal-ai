import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/price_card.dart';
import '../widgets/symbol_selector.dart';

/// Home screen — fast price dashboard only.
/// Signal analysis has been moved to the Signal tab to keep Home loading fast.
class HomeScreen extends StatefulWidget {
  final String activeSymbol;
  final void Function(String) onSymbolChanged;

  const HomeScreen({
    super.key,
    required this.activeSymbol,
    required this.onSymbolChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _isPremium = false;
  String? _errorMessage;
  late String _activeSymbol;

  // Price data
  double _price = 0;
  double _dailyChange = 0;
  double _dailyChangePercent = 0;
  double _dailyHigh = 0;
  double _dailyLow = 0;
  double _dailyOpen = 0;
  int _refreshInterval = AppConstants.defaultRefreshInterval;

  // Auto-refresh timer
  Timer? _refreshTimer;

  // AdMob banner
  BannerAd? _bannerAd;
  bool _bannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _activeSymbol = widget.activeSymbol;
    _loadPremium();
    _applyRefreshInterval();
    _loadBannerAd();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSymbol != widget.activeSymbol) {
      setState(() => _activeSymbol = widget.activeSymbol);
      _loadData();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _bannerAdLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('Banner ad failed: $error');
        },
      ),
    );
    _bannerAd!.load();
  }

  Future<void> _loadPremium() async {
    final premium = await _storage.isPremium();
    setState(() => _isPremium = premium);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Run both fast calls in parallel
      final results = await Future.wait([
        _api.getRealTimePrice(symbol: _activeSymbol),
        _api.getQuote(symbol: _activeSymbol),
      ]);

      final priceData = results[0];
      final quote = results[1];

      setState(() {
        _price = double.parse(priceData['price'].toString());
        _dailyOpen = double.parse(quote['open'].toString());
        _dailyHigh = double.parse(quote['high'].toString());
        _dailyLow = double.parse(quote['low'].toString());
        _dailyChange = double.parse((quote['change'] ?? '0').toString());
        _dailyChangePercent =
            double.parse((quote['percent_change'] ?? '0').toString());
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _startAutoRefresh(int intervalMinutes) {
    _refreshTimer?.cancel();
    if (intervalMinutes == 0) return;
    _refreshTimer =
        Timer.periodic(Duration(minutes: intervalMinutes), (_) => _loadData());
  }

  Future<void> _applyRefreshInterval() async {
    final interval = await _storage.getRefreshInterval();
    setState(() => _refreshInterval = interval);
    _startAutoRefresh(interval);
    _loadData();
  }

  void _onSymbolChanged(String symbol) {
    widget.onSymbolChanged(symbol);
  }

  @override
  Widget build(BuildContext context) {
    final inst = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == _activeSymbol,
      orElse: () => AppConstants.availableSymbols.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.monetization_on, color: AppTheme.gold, size: 24),
            const SizedBox(width: 8),
            Text(
              AppConstants.appName,
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          SymbolSelector(
            selectedSymbol: _activeSymbol,
            compact: true,
            onSymbolChanged: _onSymbolChanged,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _loadData,
            tooltip: 'Refresh now',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppTheme.gold))
            : _errorMessage != null
                ? _buildError()
                : _buildContent(inst),
      ),
      bottomNavigationBar: !_isPremium && _bannerAdLoaded && _bannerAd != null
          ? SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.red, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load price data',
                style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.gold,
                foregroundColor: AppTheme.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(dynamic inst) {
    final isPositive = _dailyChange >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main price card
        PriceCard(
          symbolDisplay: inst.display,
          symbolKey: inst.symbol,
          price: _price,
          dailyChange: _dailyChange,
          dailyChangePercent: _dailyChangePercent,
          dailyHigh: _dailyHigh,
          dailyLow: _dailyLow,
          dailyOpen: _dailyOpen,
        ),
        const SizedBox(height: 16),

        // Quick stats row
        Row(
          children: [
            _statTile('HIGH', _dailyHigh.toStringAsFixed(inst.decimals), AppTheme.green),
            const SizedBox(width: 8),
            _statTile('LOW', _dailyLow.toStringAsFixed(inst.decimals), AppTheme.red),
            const SizedBox(width: 8),
            _statTile(
              'CHANGE',
              '${isPositive ? '+' : ''}${_dailyChangePercent.toStringAsFixed(2)}%',
              isPositive ? AppTheme.green : AppTheme.red,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Signal tab CTA card
        GestureDetector(
          onTap: () {
            // Signal is tab index 2 — notify parent to switch
            // We use a workaround via symbol changed callback naming trick
            // The NavigationBar handles this via its own state
          },
          child: Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.gold.withOpacity(0.4)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.insights, color: AppTheme.gold, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trading Signal & Analysis',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'BUY / SELL / WAIT signal with EMA, RSI, MACD and more',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: AppTheme.gold, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Price alerts CTA card
        Card(
          color: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.goldDark.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_active,
                      color: AppTheme.goldDark, size: 28),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Alerts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Get notified even when app is closed',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: AppTheme.goldDark, size: 16),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.red.withOpacity(0.15)),
          ),
          child: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Educational use only. Not financial advice. Trade at your own risk.',
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(value,
                  style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
