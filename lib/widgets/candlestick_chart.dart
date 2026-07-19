import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/candle.dart';
import '../utils/theme.dart';

/// Custom candlestick chart built with fl_chart.
///
/// [candleWidth] controls body thickness (user-configurable, persisted in Settings).
/// Timestamps display in local device timezone.
class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final List<double>? ema20Values;
  final List<double>? ema50Values;
  final double candleWidth; // body width in px — default 6, user can change

  const CandlestickChart({
    super.key,
    required this.candles,
    this.ema20Values,
    this.ema50Values,
    this.candleWidth = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (candles.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.goldDark.withOpacity(0.3), width: 1),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, color: AppTheme.gold, size: 40),
              SizedBox(height: 8),
              Text('No chart data available',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    double minY = double.infinity;
    double maxY = -double.infinity;
    for (final c in candles) {
      if (c.low < minY) minY = c.low;
      if (c.high > maxY) maxY = c.high;
    }
    if (ema20Values != null) {
      for (final v in ema20Values!) {
        if (v > 0 && v < minY) minY = v;
        if (v > 0 && v > maxY) maxY = v;
      }
    }
    if (ema50Values != null) {
      for (final v in ema50Values!) {
        if (v > 0 && v < minY) minY = v;
        if (v > 0 && v > maxY) maxY = v;
      }
    }
    final range = maxY - minY;
    if (range > 0) {
      minY -= range * 0.05;
      maxY += range * 0.05;
    } else {
      minY -= 10;
      maxY += 10;
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.goldDark.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLegend(),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: -0.5,
                maxX: candles.length - 0.5,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  getDrawingHorizontalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 0.5),
                  getDrawingVerticalLine: (v) => const FlLine(color: Colors.white10, strokeWidth: 0.5),
                ),
                borderData: FlBorderData(show: true, border: Border.all(color: Colors.white10, width: 1)),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) => SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 4,
                        child: Text('\$${value.toStringAsFixed(1)}',
                            style: const TextStyle(color: Colors.white60, fontSize: 9)),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: (candles.length / 5).clamp(1, candles.length).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= candles.length) return const SizedBox.shrink();
                        // Use local time for display
                        final timeStr = DateFormat('HH:mm').format(candles[index].timestamp.toLocal());
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 2,
                          child: Text(timeStr,
                              style: const TextStyle(color: Colors.white60, fontSize: 9)),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      if (touchedSpots.isEmpty) return [];
                      final mainSpot = touchedSpots.first;
                      final index = mainSpot.x.toInt();
                      if (index < 0 || index >= candles.length) return [];
                      final c = candles[index];
                      // Local time in tooltip
                      final dateStr = DateFormat('MM/dd HH:mm').format(c.timestamp.toLocal());
                      final isBull = c.isBullish;
                      final candleColorStr = isBull ? 'Bullish' : 'Bearish';
                      final tooltipText = 'Time: $dateStr\n'
                          'Type: $candleColorStr\n'
                          'O: \$${c.open.toStringAsFixed(2)}\n'
                          'H: \$${c.high.toStringAsFixed(2)}\n'
                          'L: \$${c.low.toStringAsFixed(2)}\n'
                          'C: \$${c.close.toStringAsFixed(2)}';
                      return touchedSpots.map((spot) {
                        if (spot == mainSpot) {
                          return LineTooltipItem(tooltipText,
                              const TextStyle(color: Colors.white, fontSize: 11, height: 1.4));
                        }
                        return null;
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: _buildChartBars(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppTheme.green, 'Bullish'),
        const SizedBox(width: 12),
        _legendDot(AppTheme.red, 'Bearish'),
        const SizedBox(width: 12),
        if (ema20Values != null) ...[
          _legendDot(const Color(0xFFFFA000), 'EMA 20'),
          const SizedBox(width: 12),
        ],
        if (ema50Values != null) _legendDot(const Color(0xFF42A5F5), 'EMA 50'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  List<LineChartBarData> _buildChartBars() {
    final bars = <LineChartBarData>[];

    // 1. Wicks (thin)
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final color = c.isBullish ? AppTheme.green : AppTheme.red;
      bars.add(LineChartBarData(
        spots: [FlSpot(i.toDouble(), c.low), FlSpot(i.toDouble(), c.high)],
        color: color.withOpacity(0.5),
        barWidth: 1.5,
        isCurved: false,
        dotData: const FlDotData(show: false),
      ));
    }

    // 2. Bodies (user-configurable width)
    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final color = c.isBullish ? AppTheme.green : AppTheme.red;
      double openY = c.open;
      double closeY = c.close;
      if (openY == closeY) closeY += 0.05;
      bars.add(LineChartBarData(
        spots: [FlSpot(i.toDouble(), openY), FlSpot(i.toDouble(), closeY)],
        color: color,
        barWidth: candleWidth,
        isCurved: false,
        dotData: const FlDotData(show: false),
      ));
    }

    // 3. EMA 20 overlay
    if (ema20Values != null && ema20Values!.length == candles.length) {
      final spots = <FlSpot>[];
      for (int i = 0; i < candles.length; i++) {
        if (ema20Values![i] > 0) spots.add(FlSpot(i.toDouble(), ema20Values![i]));
      }
      if (spots.isNotEmpty) {
        bars.add(LineChartBarData(
          spots: spots,
          color: const Color(0xFFFFA000),
          barWidth: 1.5,
          isCurved: true,
          dotData: const FlDotData(show: false),
        ));
      }
    }

    // 4. EMA 50 overlay
    if (ema50Values != null && ema50Values!.length == candles.length) {
      final spots = <FlSpot>[];
      for (int i = 0; i < candles.length; i++) {
        if (ema50Values![i] > 0) spots.add(FlSpot(i.toDouble(), ema50Values![i]));
      }
      if (spots.isNotEmpty) {
        bars.add(LineChartBarData(
          spots: spots,
          color: const Color(0xFF42A5F5),
          barWidth: 1.5,
          isCurved: true,
          dotData: const FlDotData(show: false),
        ));
      }
    }

    return bars;
  }
}
