import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/signal_engine.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/price_card.dart';
import '../widgets/signal_card.dart';
import '../widgets/symbol_selector.dart';

/// Home screen — displays current price info and a quick signal summary.
///
/// Supports switching between multiple instruments (XAUUSD, EURUSD, BTCUSD, etc.)
/// via the symbol selector in the app bar. Auto-refreshes every 30 seconds.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  bool _isPremium = false;
  String? _errorMessage;
  String _activeSymbol = AppConstants.defaultSymbol;

  // Price data
  double _price = 0;
  double _dailyChange = 0;
  double _dailyChangePercent = 0;
  double _dailyHigh = 0;
  double _dailyLow = 0;
  double _dailyOpen = 0;

  // Signal data
  TradingSignal? _signal;

  // Auto-refresh timer
  Timer? _refreshTimer;

  // AdMob banner
  BannerAd? _bannerAd;
  bool _bannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
    _applyRefreshInterval();
    _loadBannerAd();
    _loadPremium();
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

  Future<void> _loadSymbol() async {
    final sym = await _storage.getSelectedSymbol();
    setState(() => _activeSymbol = sym);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final quote = await _api.getQuote(symbol: _activeSymbol);
      final priceData = await _api.getRealTimePrice(symbol: _activeSymbol);
      final candles = await _api.getTimeSeries(interval: '1h', outputsize: 200, symbol: _activeSymbol);
      final signal = SignalEngine.analyze(candles);

      setState(() {
        _price = double.parse(priceData['price'].toString());
        _dailyOpen = double.parse(quote['open'].toString());
        _dailyHigh = double.parse(quote['high'].toString());
        _dailyLow = double.parse(quote['low'].toString());
        _dailyChange = double.parse((quote['change'] ?? '0').toString());
        _dailyChangePercent = double.parse((quote['percent_change'] ?? '0').toString());
        _signal = signal;
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
    _refreshTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) => _loadData());
  }

  Future<void> _applyRefreshInterval() async {
    final interval = await _storage.getRefreshInterval();
    _startAutoRefresh(interval);
  }

  void _onSymbolChanged(String symbol) {
    setState(() => _activeSymbol = symbol);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
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
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
            : _errorMessage != null
                ? _buildErrorView()
                : _buildContent(),
      ),
      bottomNavigationBar: _buildBannerAd(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Symbol selector + current instrument label
        Center(child: SymbolSelector(onSymbolChanged: _onSymbolChanged)),
        const SizedBox(height: 16),

        // Price card
        Builder(builder: (context) {
          final instrument = AppConstants.availableSymbols.firstWhere(
            (i) => i.symbol == _activeSymbol,
            orElse: () => AppConstants.availableSymbols.first,
          );
          return PriceCard(
            price: _price,
            dailyChange: _dailyChange,
            dailyChangePercent: _dailyChangePercent,
            dailyHigh: _dailyHigh,
            dailyLow: _dailyLow,
            dailyOpen: _dailyOpen,
            symbolDisplay: instrument.display,
            symbolKey: instrument.symbol,
          );
        }),
        const SizedBox(height: 16),

        // Quick signal summary
        if (_signal != null) ...[
          const Text(
            'LATEST SIGNAL',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          SignalCard(signal: _signal!),
        ],

        const SizedBox(height: 16),

        // Disclaimer
        _buildDisclaimer(),
      ],
    );
  }

  Widget _buildErrorView() {
    return ListView(
      padding: const EdgeInsets.all(32),
      children: [
        const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
        const SizedBox(height: 16),
        Text(
          'Failed to load data',
          style: TextStyle(color: Colors.white70, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage!,
          style: const TextStyle(color: Colors.white38, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
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
    );
  }

  Widget _buildDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.white38, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              appDisclaimer,
              style: const TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Show AdMob banner ad for non-premium users
  Widget? _buildBannerAd() {
    if (_isPremium || !_bannerAdLoaded || _bannerAd == null) {
      return null;
    }
    return Container(
      color: AppTheme.blackLight,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
