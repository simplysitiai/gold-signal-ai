import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

/// Price card showing current price, daily OHLC, and change for any instrument.
class PriceCard extends StatelessWidget {
  final double price;
  final double dailyChange;
  final double dailyChangePercent;
  final double dailyHigh;
  final double dailyLow;
  final double dailyOpen;
  final double? spread;
  final String? symbolDisplay; // Dynamic — shows active symbol

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
  });

  @override
  Widget build(BuildContext context) {
    final priceFormatter = NumberFormat('#,##0.00####', 'en_US');
    final changeFormatter = NumberFormat('+#,##0.00####;-#,##0.00####', 'en_US');

    final isPositive = dailyChange >= 0;
    final changeColor = isPositive ? AppTheme.green : AppTheme.red;
    final changeIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    final String changeSign = isPositive ? '+' : '';
    final String changePercentText = '$changeSign${dailyChangePercent.toStringAsFixed(2)}%';
    final String changeValText = changeFormatter.format(dailyChange);

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
                Text(
                  '\$${priceFormatter.format(price)}',
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 30,
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
                        fontSize: 13,
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
                  child: _buildGridItem(
                    label: 'DAILY HIGH',
                    value: '\$${priceFormatter.format(dailyHigh)}',
                    icon: Icons.arrow_upward,
                    iconColor: AppTheme.green,
                  ),
                ),
                Container(height: 40, width: 1, color: Colors.white10),
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
                Container(height: 40, width: 1, color: Colors.white10),
                Expanded(
                  child: _buildGridItem(
                    label: 'SPREAD',
                    value: spread != null ? '${spread!.toStringAsFixed(4)}' : 'N/A',
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
