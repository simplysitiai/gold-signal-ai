import 'package:flutter/material.dart';

import '../models/candle.dart';
import '../services/api_service.dart';
import '../services/indicator_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/candlestick_chart.dart';
import '../widgets/symbol_selector.dart';

/// Chart screen — displays a candlestick chart with selectable timeframes.
///
/// Users can switch between any supported instrument and between 1m, 5m,
/// 15m, 30m, 1H, 4H, and 1D intervals. EMA 20 and EMA 50 overlay lines are
/// drawn on the chart. Also shows a compact indicator summary below.
class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  int _selectedIntervalIndex = 4; // Default to 1H
  String _activeSymbol = AppConstants.defaultSymbol;
  List<Candle> _candles = [];
  List<double> _ema20Values = [];
  List<double> _ema50Values = [];
  double _candleWidth = AppConstants.defaultCandleWidth;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
  }

  Future<void> _loadSymbol() async {
    final sym = await _storage.getSelectedSymbol();
    setState(() => _activeSymbol = sym);
    final cw = await _storage.getCandleWidth();
    setState(() => _candleWidth = cw);
    _loadChartData();
  }

  void _onSymbolChanged(String symbol) {
    setState(() => _activeSymbol = symbol);
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final interval = AppConstants.intervals[_selectedIntervalIndex];
      final candles = await _api.getTimeSeries(
        interval: interval,
        outputsize: 150,
        symbol: _activeSymbol,
      );

      // Calculate EMA overlays
      final closes = candles.map((c) => c.close).toList();
      final ema20 = IndicatorService.calculateEMA(closes, AppConstants.emaShortPeriod);
      final ema50 = IndicatorService.calculateEMA(closes, AppConstants.emaLongPeriod);

      // Align EMA values to candle indices
      List<double> alignedEma20 = [];
      List<double> alignedEma50 = [];

      final offset20 = candles.length - ema20.length;
      final offset50 = candles.length - ema50.length;

      for (int i = 0; i < candles.length; i++) {
        if (i >= offset20 && (i - offset20) < ema20.length) {
          alignedEma20.add(ema20[i - offset20]);
        } else {
          alignedEma20.add(0);
        }

        if (i >= offset50 && (i - offset50) < ema50.length) {
          alignedEma50.add(ema50[i - offset50]);
        } else {
          alignedEma50.add(0);
        }
      }

      setState(() {
        _candles = candles;
        _ema20Values = alignedEma20;
        _ema50Values = alignedEma50;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
        title: Text('$displaySymbol Chart'),
        actions: [
          SymbolSelector(compact: true, onSymbolChanged: _onSymbolChanged),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: _loadChartData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Timeframe selector
          _buildTimeframeSelector(),
          const SizedBox(height: 8),

          // Chart or loading/error
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
                : _errorMessage != null
                    ? _buildErrorView()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            CandlestickChart(
                              candles: _candles,
                              ema20Values: _ema20Values,
                              ema50Values: _ema50Values,
                              candleWidth: _candleWidth,
                            ),
                            const SizedBox(height: 16),
                            _buildIndicatorSummary(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  /// Horizontal scrollable timeframe selector buttons
  Widget _buildTimeframeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(AppConstants.intervals.length, (index) {
            final isSelected = index == _selectedIntervalIndex;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedIntervalIndex = index);
                  _loadChartData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.gold : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppTheme.gold : AppTheme.goldDark.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    AppConstants.intervalLabels[index],
                    style: TextStyle(
                      color: isSelected ? AppTheme.black : Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Compact indicator summary below the chart
  Widget _buildIndicatorSummary() {
    if (_candles.isEmpty) return const SizedBox.shrink();

    final data = IndicatorService.calculateAll(_candles);
    final fmt = (double v) => v.toStringAsFixed(2);

    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INDICATOR VALUES',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _buildIndicatorRow('EMA 20', fmt(data.ema20),
                data.emaBullishCross ? AppTheme.green : AppTheme.red),
            _buildIndicatorRow('EMA 50', fmt(data.ema50),
                data.emaBullishCross ? AppTheme.green : AppTheme.red),
            _buildIndicatorRow('RSI (14)', data.rsi.toStringAsFixed(1),
                data.rsiOversold ? AppTheme.green : (data.rsiOverbought ? AppTheme.red : AppTheme.gold)),
            _buildIndicatorRow('MACD', '${fmt(data.macdLine)} / ${fmt(data.macdSignal)}',
                data.macdBullishCross ? AppTheme.green : AppTheme.red),
            _buildIndicatorRow('BB Upper', fmt(data.bbUpper), Colors.white70),
            _buildIndicatorRow('BB Lower', fmt(data.bbLower), Colors.white70),
            _buildIndicatorRow('ATR', fmt(data.atr), AppTheme.gold),
            _buildIndicatorRow('Support', fmt(data.support), AppTheme.green),
            _buildIndicatorRow('Resistance', fmt(data.resistance), AppTheme.red),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor, fontSize: 13, fontWeight: FontWeight.w600)),
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
              'Failed to load chart data',
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
              onPressed: _loadChartData,
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
