import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Price card showing current price, daily OHLC, and change for any instrument.
///
/// Uses per-symbol decimal precision:
///   Gold/BTC    → 2 decimals  (e.g. 3,342.55)
///   Forex major → 5 decimals  (e.g. 1.14237)
///   JPY pairs   → 3 decimals  (e.g. 158.412)
class PriceCard extends StatelessWidget {
  final double price;
  final double dailyChange;
  final double dailyChangePercent;
  final double dailyHigh;
  final double dailyLow;
  final double dailyOpen;
  final double? spread;
  final String? symbolDisplay; // e.g. "EURUSD"
  final String? symbolKey;     // API key e.g. "EUR/USD" — used for decimal lookup

  const PriceCard({
    super.key,
    required this.price,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.dailyHigh,
    required this.dailyLow,
    required this.dailyOpen,
    this.spread,
    this.symbolDisplay,
    this.symbolKey,
  });

  /// Return the appropriate number of decimals for this instrument
  int get _decimals => AppConstants.decimalsForSymbol(symbolKey ?? '');

  String _fmtPrice(double v) => v.toStringAsFixed(_decimals);

  @override
  Widget build(BuildContext context) {
    final isPositive = dailyChange >= 0;
    final changeColor = isPositive ? AppTheme.green : AppTheme.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    final String changeSign = isPositive ? '+' : '';
    final String changePercentText = '$changeSign${dailyChangePercent.toStringAsFixed(2)}%';
    // For change value, use same decimals as price
    final String changeValText =
        '${dailyChange >= 0 ? "+" : ""}${dailyChange.toStringAsFixed(_decimals)}';

    final displayLabel = symbolDisplay ?? AppConstants.defaultSymbolDisplay;

    return Card(
      elevation: 4,
      shadowColor: Colors.black45,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Symbol row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.goldDark.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.show_chart, color: AppTheme.gold, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      displayLabel,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: AppTheme.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Price + change
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    _fmtPrice(price),
                    style: const TextStyle(
                      color: AppTheme.gold,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(changeIcon, color: changeColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$changeValText ($changePercentText)',
                      style: TextStyle(
                        color: changeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // OHLC grid
            Row(
              children: [
                Expanded(
                  child: _gridItem('DAILY HIGH', _fmtPrice(dailyHigh), Icons.arrow_upward, AppTheme.green),
                ),
                Container(height: 40, width: 1, color: Colors.white10),
                Expanded(
                  child: _gridItem('DAILY LOW', _fmtPrice(dailyLow), Icons.arrow_downward, AppTheme.red),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _gridItem('DAILY OPEN', _fmtPrice(dailyOpen), Icons.door_front_door_outlined, Colors.grey),
                ),
                Container(height: 40, width: 1, color: Colors.white10),
                Expanded(
                  child: _gridItem(
                    'SPREAD',
                    spread != null ? spread!.toStringAsFixed(_decimals) : 'N/A',
                    Icons.unfold_more,
                    AppTheme.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gridItem(String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor.withOpacity(0.7), size: 12),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
