import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/signal_engine.dart';
import '../services/indicator_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/signal_card.dart';
import '../widgets/indicator_card.dart';

/// Signal screen — full signal engine output with detailed indicator breakdown.
///
/// Fetches candlestick data, runs the signal engine, and displays:
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

  bool _isLoading = true;
  String? _errorMessage;
  TradingSignal? _signal;
  List<Candle> _candles = [];

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoaded = false;
  bool _premiumAnalysisUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadSignal();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
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
      final candles = await _api.getTimeSeries(interval: '1h', outputsize: 200);
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
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('AI Signal'),
        actions: [
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
          // If not enough data, show locked state
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
            const Text('0', style: TextStyle(color: Colors.white24, fontSize: 9)),
            const Text('30', style: TextStyle(color: AppTheme.green, fontSize: 9)),
            const Text('50', style: TextStyle(color: Colors.white38, fontSize: 9)),
            const Text('70', style: TextStyle(color: AppTheme.red, fontSize: 9)),
            const Text('100', style: TextStyle(color: Colors.white24, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  /// Bollinger Bands visual showing price position between bands
  Widget _buildBollingerBar(data) {
    final bbWidth = data.bbUpper - data.bbLower;
    final position = bbWidth > 0 ? (data.currentPrice - data.bbLower) / bbWidth : 0.5;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: position.clamp(0.0, 1.0),
        backgroundColor: Colors.white10,
        valueColor: const AlwaysStoppedAnimation(AppTheme.gold),
        minHeight: 6,
      ),
    );
  }

  /// Premium deep analysis section (unlocked via rewarded ad)
  Widget _buildPremiumAnalysis() {
    final data = IndicatorService.calculateAll(_candles);
    final fmt = (double v) => v.toStringAsFixed(2);

    return Card(
      color: AppTheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'DEEP ANALYSIS',
                  style: TextStyle(
                    color: AppTheme.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAnalysisRow('EMA Spread', '${fmt((data.ema20 - data.ema50).abs())} pts'),
            _buildAnalysisRow('MACD Histogram', '${fmt(data.macdHistogram)} (${data.macdHistogram > 0 ? "bullish" : "bearish"})'),
            _buildAnalysisRow('Bollinger %B', '${(data.bbPercentB * 100).toStringAsFixed(1)}%'),
            _buildAnalysisRow('S/R Range', '${fmt(data.resistance - data.support)} pts'),
            _buildAnalysisRow('ATR / Price', '${(data.atr / data.currentPrice * 100).toStringAsFixed(3)}%'),
            _buildAnalysisRow('Price vs Support', '${fmt(data.currentPrice - data.support)} pts above'),
            _buildAnalysisRow('Price vs Resistance', '${fmt(data.resistance - data.currentPrice)} pts below'),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: AppTheme.gold, fontSize: 13, fontWeight: FontWeight.w600)),
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
            Text('Failed to generate signal', style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_errorMessage ?? '', style: const TextStyle(color: Colors.white38, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadSignal,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.black),
            ),
          ],
        ),
      ),
    );
  }
}
