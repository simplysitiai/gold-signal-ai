import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gold_signal_ai/utils/theme.dart';
import 'package:gold_signal_ai/utils/constants.dart';

/// A card widget showing current XAUUSD price info.
///
/// Displays the current price in large gold text, the daily change (with green/red coloring),
/// and a grid of daily high, daily low, daily open, and spread.
class PriceCard extends StatelessWidget {
  final double price;
  final double dailyChange;
  final double dailyChangePercent;
  final double dailyHigh;
  final double dailyLow;
  final double dailyOpen;
  final double? spread;

  const PriceCard({
    super.key,
    required this.price,
    required this.dailyChange,
    required this.dailyChangePercent,
    required this.dailyHigh,
    required this.dailyLow,
    required this.dailyOpen,
    this.spread,
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,##0.00', 'en_US');
    final percentFormatter = NumberFormat('+0.00%;-0.00%', 'en_US');
    final changeFormatter = NumberFormat('+#,##0.00;-#,##0.00', 'en_US');

    final isPositive = dailyChange >= 0;
    final changeColor = isPositive ? AppTheme.green : AppTheme.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    // Formatting dailyChangePercent (passed as double e.g. 0.35 for 0.35%, or maybe 0.0035.
    // Usually, in API/signal systems dailyChangePercent is passed directly as percentage, e.g. 0.45 for 0.45%.
    // Let's divide by 100 if we use percentFormatter, or just format directly as string with '%' to be safe.
    // Let's format dailyChangePercent directly:
    final String changeSign = isPositive ? '+' : '';
    final String changePercentText = '$changeSign${dailyChangePercent.toStringAsFixed(2)}%';
    final String changeValText = changeFormatter.format(dailyChange);

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
            // Symbol and Title Row
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
                      child: const Icon(Icons.monetization_on, color: AppTheme.gold, size: 20),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      AppConstants.symbolDisplay,
                      style: TextStyle(
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

            // Large Price and Daily Change Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${priceFormatter.format(price)}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
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
                        fontSize: 14,
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

            // Grid of High, Low, Open, Spread
            Row(
              children: [
                Expanded(
                  child: _buildGridItem(
                    label: 'DAILY HIGH',
                    value: '\$${priceFormatter.format(dailyHigh)}',
                    icon: Icons.arrow_upward,
                    iconColor: AppTheme.green,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white10,
                ),
                Expanded(
                  child: _buildGridItem(
                    label: 'DAILY LOW',
                    value: '\$${priceFormatter.format(dailyLow)}',
                    icon: Icons.arrow_downward,
                    iconColor: AppTheme.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildGridItem(
                    label: 'DAILY OPEN',
                    value: '\$${priceFormatter.format(dailyOpen)}',
                    icon: Icons.door_front_door_outlined,
                    iconColor: Colors.grey,
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white10,
                ),
                Expanded(
                  child: _buildGridItem(
                    label: 'SPREAD',
                    value: spread != null ? '${spread!.toStringAsFixed(2)} pips' : 'N/A',
                    icon: Icons.unfold_more,
                    iconColor: AppTheme.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds an individual item for the metrics grid inside the price card.
  Widget _buildGridItem({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor.withOpacity(0.7), size: 12),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
