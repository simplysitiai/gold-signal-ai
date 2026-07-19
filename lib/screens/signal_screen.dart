import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../models/indicator_data.dart';
import '../services/api_service.dart';
import '../services/signal_engine.dart';
import '../services/indicator_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/signal_card.dart';
import '../widgets/indicator_card.dart';
import '../widgets/symbol_selector.dart';

/// Signal screen — full signal engine output with indicator breakdown.
/// Completely rebuilt to fix blank screen bug.
class SignalScreen extends StatefulWidget {
  final String activeSymbol;
  final void Function(String) onSymbolChanged;

  const SignalScreen({
    super.key,
    required this.activeSymbol,
    required this.onSymbolChanged,
  });

  @override
  State<SignalScreen> createState() => _SignalScreenState();
}

class _SignalScreenState extends State<SignalScreen>
    with AutomaticKeepAliveClientMixin {
  final ApiService _api = ApiService();

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  TradingSignal? _signal;
  IndicatorData? _indicators;
  List<Candle> _candles = [];
  late String _activeSymbol;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoaded = false;
  bool _premiumAnalysisUnlocked = false;

  // Auto-refresh every 5 minutes
  Timer? _refreshTimer;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _activeSymbol = widget.activeSymbol;
    _loadRewardedAd();
    _loadSignal();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _loadSignal(),
    );
  }

  @override
  void didUpdateWidget(covariant SignalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSymbol != widget.activeSymbol) {
      setState(() {
        _activeSymbol = widget.activeSymbol;
        _signal = null;
        _indicators = null;
        _candles = [];
        _hasLoaded = false;
      });
      _loadSignal();
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) setState(() { _rewardedAd = ad; _rewardedAdLoaded = true; });
        },
        onAdFailedToLoad: (error) => debugPrint('Rewarded ad failed: $error'),
      ),
    );
  }

  Future<void> _loadSignal() async {
    if (_isLoading) return;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final candles = await _api.getTimeSeries(
        interval: '1h',
        outputsize: 200,
        symbol: _activeSymbol,
      );

      if (candles.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = 'No candle data returned from API.\nCheck your API key in Settings.';
            _isLoading = false;
            _hasLoaded = true;
          });
        }
        return;
      }

      final signal = SignalEngine.analyze(candles);
      final indicators = candles.length >= 20
          ? IndicatorService.calculateAll(candles)
          : null;

      if (mounted) {
        setState(() {
          _candles = candles;
          _signal = signal;
          _indicators = indicators;
          _isLoading = false;
          _hasLoaded = true;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load signal data.\n\n${e.toString()}';
          _isLoading = false;
          _hasLoaded = true;
        });
      }
    }
  }

  void _showRewardedAd() {
    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
          setState(() => _premiumAnalysisUnlocked = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deep analysis unlocked!'),
              backgroundColor: AppTheme.green,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final inst = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == _activeSymbol,
      orElse: () => AppConstants.availableSymbols.first,
    );

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: Text('${inst.display} Signal'),
        actions: [
          SymbolSelector(
            selectedSymbol: _activeSymbol,
            compact: true,
            onSymbolChanged: widget.onSymbolChanged,
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppTheme.gold, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _isLoading ? null : _loadSignal,
            tooltip: 'Refresh Signal',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // First load — show spinner
    if (!_hasLoaded && _isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.gold),
            const SizedBox(height: 16),
            Text(
              'Analyzing ${_activeSymbol.replaceAll('/', '')}...',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null && _signal == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, color: AppTheme.red, size: 56),
              const SizedBox(height: 16),
              const Text('Signal unavailable',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _loadSignal,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: AppTheme.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Loaded — show content (with optional refresh indicator overlay)
    return RefreshIndicator(
      color: AppTheme.gold,
      onRefresh: _loadSignal,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Main signal card ───────────────────────────────────────────
          if (_signal != null) SignalCard(signal: _signal!),
          const SizedBox(height: 16),

          // ── Rewarded ad unlock section ─────────────────────────────────
          if (!_premiumAnalysisUnlocked)
            _buildUnlockCard(),
          if (!_premiumAnalysisUnlocked) const SizedBox(height: 16),

          // ── Indicator breakdown ────────────────────────────────────────
          if (_indicators != null) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'INDICATOR BREAKDOWN',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            _buildIndicators(_indicators!),
            const SizedBox(height: 16),
          ],

          // ── Premium analysis ───────────────────────────────────────────
          if (_premiumAnalysisUnlocked && _indicators != null) ...[
            _buildPremiumAnalysis(_indicators!),
            const SizedBox(height: 16),
          ],

          // ── Disclaimer ─────────────────────────────────────────────────
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
                    appDisclaimer,
                    style: TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnlockCard() {
    return Card(
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
            const Text('Deep Analysis Locked',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text(
              'Watch a short ad to unlock full indicator details',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _rewardedAdLoaded ? _showRewardedAd : null,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(_rewardedAdLoaded ? 'Watch Ad to Unlock' : 'Loading ad...'),
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

  Widget _buildIndicators(IndicatorData data) {
    String fmt(double v) => v.toStringAsFixed(2);

    return Column(
      children: [
        IndicatorCard(
          title: 'EMA 20 vs EMA 50',
          value: '${fmt(data.ema20)} / ${fmt(data.ema50)}',
          subtitle: data.emaBullishCross ? 'Bullish Cross ↑' : 'Bearish Cross ↓',
          indicatorColor: data.emaBullishCross ? AppTheme.green : AppTheme.red,
        ),
        const SizedBox(height: 8),
        IndicatorCard(
          title: 'RSI (14)',
          value: data.rsi.toStringAsFixed(1),
          subtitle: data.rsiOversold
              ? 'Oversold — potential BUY'
              : data.rsiOverbought
                  ? 'Overbought — potential SELL'
                  : 'Neutral zone',
          indicatorColor: data.rsiOversold
              ? AppTheme.green
              : data.rsiOverbought
                  ? AppTheme.red
                  : AppTheme.gold,
          child: _rsiBar(data.rsi),
        ),
        const SizedBox(height: 8),
        IndicatorCard(
          title: 'MACD (12, 26, 9)',
          value: fmt(data.macdLine),
          subtitle: 'Signal: ${fmt(data.macdSignal)}  |  Hist: ${fmt(data.macdHistogram)}',
          indicatorColor: data.macdBullishCross ? AppTheme.green : AppTheme.red,
        ),
        const SizedBox(height: 8),
        IndicatorCard(
          title: 'Bollinger Bands (20, 2σ)',
          value: fmt(data.bbMiddle),
          subtitle: 'Upper: ${fmt(data.bbUpper)}  |  Lower: ${fmt(data.bbLower)}',
          indicatorColor: data.bbPercentB < 0.2
              ? AppTheme.green
              : data.bbPercentB > 0.8
                  ? AppTheme.red
                  : AppTheme.gold,
        ),
        const SizedBox(height: 8),
        IndicatorCard(
          title: 'ATR (14)',
          value: fmt(data.atr),
          subtitle: 'Average True Range — volatility measure',
          indicatorColor: AppTheme.gold,
        ),
        const SizedBox(height: 8),
        IndicatorCard(
          title: 'Support & Resistance',
          value: 'S: ${fmt(data.support)}',
          subtitle: 'R: ${fmt(data.resistance)}',
          indicatorColor: AppTheme.gold,
        ),
      ],
    );
  }

  Widget _rsiBar(double rsi) {
    final clamped = rsi.clamp(0.0, 100.0);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation<Color>(
                rsi < 30
                    ? AppTheme.green
                    : rsi > 70
                        ? AppTheme.red
                        : AppTheme.gold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumAnalysis(IndicatorData data) {
    String fmt(double v) => v.toStringAsFixed(2);
    final signal = _signal;
    if (signal == null) return const SizedBox.shrink();

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.star, color: AppTheme.gold, size: 18),
              const SizedBox(width: 6),
              const Text('PREMIUM ANALYSIS',
                  style: TextStyle(
                      color: AppTheme.gold,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2)),
            ]),
            const SizedBox(height: 12),
            _premiumRow('Signal', signal.signalName),
            _premiumRow('Confidence', '${signal.confidence.toStringAsFixed(0)}%'),
            _premiumRow('EMA Trend', data.emaBullishCross ? 'Bullish' : 'Bearish'),
            _premiumRow('RSI Reading', data.rsi.toStringAsFixed(1)),
            _premiumRow('MACD Cross', data.macdBullishCross ? 'Bullish' : 'Bearish'),
            _premiumRow('BB Position', data.bbPercentB < 0.2
                ? 'Near Support'
                : data.bbPercentB > 0.8
                    ? 'Near Resistance'
                    : 'Mid-range'),
            _premiumRow('Support', fmt(data.support)),
            _premiumRow('Resistance', fmt(data.resistance)),
            _premiumRow('ATR Volatility', fmt(data.atr)),
          ],
        ),
      ),
    );
  }

  Widget _premiumRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
