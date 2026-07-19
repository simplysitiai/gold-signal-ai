import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/candle.dart';
import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/signal_engine.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/signal_card.dart';
import '../widgets/symbol_selector.dart';

/// Signal screen — the exact same signal logic that used to live on Home tab.
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

class _SignalScreenState extends State<SignalScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  late String _activeSymbol;

  // Signal data — same fields as the original Home tab signal
  TradingSignal? _signal;
  bool _signalLoading = false;
  String? _errorMessage;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _rewardedAdLoaded = false;

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _activeSymbol = widget.activeSymbol;
    _loadRewardedAd();
    _loadSignal();
    // Auto-refresh every 5 minutes
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
        _errorMessage = null;
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

  // Exact same _loadSignal that was on the original Home tab
  Future<void> _loadSignal() async {
    if (mounted) setState(() { _signalLoading = true; _errorMessage = null; });
    try {
      final candles = await _api.getTimeSeries(
        interval: '1h',
        outputsize: 200,
        symbol: _activeSymbol,
      );
      final signal = SignalEngine.analyze(candles);
      if (mounted) setState(() { _signal = signal; _signalLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _signalLoading = false; _errorMessage = e.toString(); });
    }
  }

  void _showRewardedAd() {
    _rewardedAd?.show(
      onUserEarnedReward: (ad, reward) {
        if (mounted) {
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
            icon: _signalLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppTheme.gold, strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _signalLoading ? null : _loadSignal,
            tooltip: 'Refresh Signal',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.gold,
        onRefresh: _loadSignal,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Signal card — same as original Home tab ────────────────
            if (_signalLoading)
              const Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: AppTheme.gold, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Analysing signal…',
                            style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )
            else if (_signal != null)
              SignalCard(signal: _signal!)
            else
              Card(
                color: AppTheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: AppTheme.gold.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(Icons.insights_outlined,
                          color: AppTheme.gold, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage != null
                            ? 'Failed to load signal'
                            : 'No signal yet',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage ?? 'Tap refresh to analyse',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadSignal,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Signal'),
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

            // ── Rewarded ad unlock ─────────────────────────────────────
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
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
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
                      label: Text(
                          _rewardedAdLoaded ? 'Watch Ad to Unlock' : 'Loading ad…'),
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

            // ── Disclaimer ─────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.white38, size: 16),
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
      ),
    );
  }
}
