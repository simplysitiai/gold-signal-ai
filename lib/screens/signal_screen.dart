import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/signal_engine.dart';
import '../services/indicator_service.dart';
import '../models/indicator_data.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/signal_card.dart';
import '../widgets/indicator_card.dart';
import '../widgets/symbol_selector.dart';

/// Signal screen — full signal engine output with detailed indicator breakdown.
///
/// Supports switching between any supported instrument via the symbol selector.
/// Displays:
/// - The BUY/SELL/WAIT signal with confidence score
/// - Individual indicator cards (EMA, RSI, MACD, Bollinger Bands, ATR, S/R)
/// - A "Rewarded Analysis" button (watch an ad for deeper analysis)
/// - Disclaimer text
class SignalScreen extends StatefulWidget {
  const SignalScreen({super.key});

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  bool _isLoading = true;
  String? _errorMessage;
  TradingSignal? _signal;
  List<Candle> _candles = [];
  String _activeSymbol = AppConstants.defaultSymbol;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoaded = false;
  bool _premiumAnalysisUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  Future<void> _loadSymbol() async {
    final sym = await _storage.getSelectedSymbol();
    setState(() => _activeSymbol = sym);
    _loadSignal();
  }

  void _onSymbolChanged(String symbol) {
    setState(() => _activeSymbol = symbol);
    _loadSignal();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => setState(() {
          _rewardedAd = ad;
          _rewardedAdLoaded = true;
        }),
        onAdFailedToLoad: (error) => debugPrint('Rewarded ad failed: $error'),
      ),
    );
  }

  Future<void> _loadSignal() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final candles = await _api.getTimeSeries(
        interval: '1h',
        outputsize: 200,
        symbol: _activeSymbol,
      );
      final signal = SignalEngine.analyze(candles);

      setState(() {
        _candles = candles;
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

  void _showRewardedAd() {
    if (_rewardedAd == null) return;

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        setState(() => _premiumAnalysisUnlocked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deep analysis unlocked!'),
            backgroundColor: AppTheme.green,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == _activeSymbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: Text('$displaySymbol Signal'),
        actions: [
          SymbolSelector(compact: true, onSymbolChanged: _onSymbolChanged),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _loadSignal,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Main signal card
        if (_signal != null) SignalCard(signal: _signal!),
        const SizedBox(height: 16),

        // Rewarded ad section
        if (!_premiumAnalysisUnlocked) ...[
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Icon(Icons.lock_outline, color: AppTheme.gold, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'Deep Analysis Locked',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Watch a short ad to unlock detailed indicator breakdown',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _rewardedAdLoaded ? _showRewardedAd : null,
                    icon: const Icon(Icons.play_circle_outline),
                    label: const Text('Watch Ad to Unlock'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.gold,
                      foregroundColor: AppTheme.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Detailed indicator breakdown
        if (_candles.length >= 50) ...[
          const Text(
            'INDICATOR BREAKDOWN',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          _buildDetailedIndicators(),
        ] else ...[
          Card(
            color: AppTheme.surface,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Not enough candle data for full indicator analysis.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Premium analysis (if unlocked)
        if (_premiumAnalysisUnlocked && _candles.length >= 50) ...[
          _buildPremiumAnalysis(),
          const SizedBox(height: 16),
        ],

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.red.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.red.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  appDisclaimer,
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build detailed indicator cards from the candle data
  Widget _buildDetailedIndicators() {
    final data = IndicatorService.calculateAll(_candles);
    final fmt = (double v) => v.toStringAsFixed(2);

    return Column(
      children: [
        // EMA
        IndicatorCard(
          title: 'EMA 20 vs EMA 50',
          value: '${fmt(data.ema20)} / ${fmt(data.ema50)}',
          subtitle: data.emaBullishCross ? 'Bullish Cross' : 'Bearish Cross',
          indicatorColor: data.emaBullishCross ? AppTheme.green : AppTheme.red,
        ),
        const SizedBox(height: 8),

        // RSI
        IndicatorCard(
          title: 'RSI (14)',
          value: data.rsi.toStringAsFixed(1),
          subtitle: data.rsiOversold
              ? 'Oversold'
              : data.rsiOverbought
                  ? 'Overbought'
                  : 'Neutral',
          indicatorColor: data.rsiOversold
              ? AppTheme.green
              : data.rsiOverbought
                  ? AppTheme.red
                  : AppTheme.gold,
          child: _buildRsiBar(data.rsi),
        ),
        const SizedBox(height: 8),

        // MACD
        IndicatorCard(
          title: 'MACD (12, 26, 9)',
          value: '${fmt(data.macdLine)}',
          subtitle: 'Signal: ${fmt(data.macdSignal)}',
          indicatorColor: data.macdBullishCross ? AppTheme.green : AppTheme.red,
        ),
        const SizedBox(height: 8),

        // Bollinger Bands
        IndicatorCard(
          title: 'Bollinger Bands (20, 2)',
          value: '${fmt(data.bbMiddle)}',
          subtitle: 'U: ${fmt(data.bbUpper)} L: ${fmt(data.bbLower)}',
          indicatorColor: AppTheme.gold,
          child: _buildBollingerBar(data),
        ),
        const SizedBox(height: 8),

        // ATR
        IndicatorCard(
          title: 'ATR (14)',
          value: fmt(data.atr),
          subtitle: 'Volatility',
          indicatorColor: AppTheme.goldDark,
        ),
        const SizedBox(height: 8),

        // Support & Resistance
        IndicatorCard(
          title: 'Support / Resistance',
          value: '${fmt(data.support)}',
          subtitle: 'R: ${fmt(data.resistance)}',
          indicatorColor: Colors.blue,
        ),
      ],
    );
  }

  /// RSI visual bar (0-100 scale)
  Widget _buildRsiBar(double rsi) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (rsi / 100).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation(
              rsi < 30 ? AppTheme.green : rsi > 70 ? AppTheme.red : AppTheme.gold,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Oversold (30)', style: TextStyle(color: Colors.white24, fontSize: 9)),
            Text('Overbought (70)', style: TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  /// Bollinger Bands visual bar
  Widget _buildBollingerBar(IndicatorData data) {
    final range = data.bbUpper - data.bbLower;
    if (range == 0) return const SizedBox.shrink();

    // Calculate position of current price within the bands
    final lastClose = _candles.last.close;
    final pos = ((lastClose - data.bbLower) / range * 100).clamp(0.0, 100.0);

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pos / 100,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Lower: ${data.bbLower.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white24, fontSize: 9)),
            Text('Upper: ${data.bbUpper.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  /// Premium deep analysis section
  Widget _buildPremiumAnalysis() {
    final data = IndicatorService.calculateAll(_candles);
    final fmt = (double v) => v.toStringAsFixed(2);

    return Card(
      color: AppTheme.gold.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'DEEP ANALYSIS',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Trend analysis
            _buildAnalysisRow('Trend', data.emaBullishCross ? 'Bullish' : 'Bearish'),
            _buildAnalysisRow('Momentum', data.rsi < 30
                ? 'Oversold (reversal likely)'
                : data.rsi > 70
                    ? 'Overbought (reversal likely)'
                    : 'Neutral'),
            _buildAnalysisRow('Volatility', data.atr > 5
                ? 'High (${fmt(data.atr)})'
                : 'Low (${fmt(data.atr)})'),
            _buildAnalysisRow('BB Position', data.bbUpper > 0 && _candles.isNotEmpty
                ? 'Price at ${((_candles.last.close - data.bbLower) / (data.bbUpper - data.bbLower) * 100).clamp(0, 100).toStringAsFixed(0)}% of range'
                : 'N/A'),
            _buildAnalysisRow('Key Level', _candles.isNotEmpty
                ? 'Support: ${fmt(data.support)} | Resistance: ${fmt(data.resistance)}'
                : 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white38, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to load signal data',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSignal,
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
}
