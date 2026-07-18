import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:gold_signal_ai/models/candle.dart';
import 'package:gold_signal_ai/utils/theme.dart';

/// A custom candlestick chart widget built using fl_chart.
///
/// Takes a list of [candles] and renders them as candlesticks (vertical bars for bodies
/// and lines for wicks). Supports optional [ema20Values] and [ema50Values] as line overlays.
class CandlestickChart extends StatelessWidget {
  final List<Candle> candles;
  final List<double>? ema20Values;
  final List<double>? ema50Values;

  const CandlestickChart({
    super.key,
    required this.candles,
    this.ema20Values,
    this.ema50Values,
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
              Text(
                'No chart data available',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // Determine min/max values for Y-axis auto-scaling
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final candle in candles) {
      if (candle.low < minY) minY = candle.low;
      if (candle.high > maxY) maxY = candle.high;
    }

    if (ema20Values != null) {
      for (final val in ema20Values!) {
        if (val > 0 && val < minY) minY = val;
        if (val > 0 && val > maxY) maxY = val;
      }
    }

    if (ema50Values != null) {
      for (final val in ema50Values!) {
        if (val > 0 && val < minY) minY = val;
        if (val > 0 && val > maxY) maxY = val;
      }
    }

    // Add 5% padding to top and bottom to avoid candles hugging the edges
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
          // Technical indicators indicator overlay legend
          _buildLegend(),
          const SizedBox(height: 12),
          // Chart viewport
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
                  getDrawingHorizontalLine: (value) => const FlLine(
                    color: Colors.white10,
                    strokeWidth: 0.5,
                  ),
                  getDrawingVerticalLine: (value) => const FlLine(
                    color: Colors.white10,
                    strokeWidth: 0.5,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.white10,
                    width: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 55,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(
                            '\$${value.toStringAsFixed(1)}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 18,
                      interval: (candles.length / 5).clamp(1, candles.length).toDouble(),
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= candles.length) {
                          return const SizedBox.shrink();
                        }
                        final candle = candles[index];
                        final timeStr = DateFormat('HH:mm').format(candle.timestamp);
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 2,
                          child: Text(
                            timeStr,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    // Tooltip styling uses defaults in fl_chart 0.67+
                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                      if (touchedSpots.isEmpty) return [];

                      // Identify index by matching any spot
                      final mainSpot = touchedSpots.first;
                      final index = mainSpot.x.toInt();
                      if (index < 0 || index >= candles.length) return [];

                      final candle = candles[index];
                      final dateStr = DateFormat('MM/dd HH:mm').format(candle.timestamp);

                      final isBull = candle.isBullish;
                      final candleColorStr = isBull ? 'Bullish' : 'Bearish';

                      final tooltipText = 'Time: $dateStr\n'
                          'Type: $candleColorStr\n'
                          'O: \$${candle.open.toStringAsFixed(2)}\n'
                          'H: \$${candle.high.toStringAsFixed(2)}\n'
                          'L: \$${candle.low.toStringAsFixed(2)}\n'
                          'C: \$${candle.close.toStringAsFixed(2)}\n'
                          'Vol: ${candle.volume.toStringAsFixed(0)}';

                      return touchedSpots.map((spot) {
                        if (spot == mainSpot) {
                          return LineTooltipItem(
                            tooltipText,
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              height: 1.4,
                            ),
                          );
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

  /// Builds all chart bars: wicks, bodies, and optional EMA overlay lines.
  List<LineChartBarData> _buildChartBars() {
    final List<LineChartBarData> bars = [];

    // 1. Draw Wicks (from Low to High)
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final color = candle.isBullish ? AppTheme.green : AppTheme.red;
      bars.add(
        LineChartBarData(
          spots: [
            FlSpot(i.toDouble(), candle.low),
            FlSpot(i.toDouble(), candle.high),
          ],
          color: color.withOpacity(0.5),
          barWidth: 1.5,
          isCurved: false,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    // 2. Draw Bodies (from Open to Close)
    for (int i = 0; i < candles.length; i++) {
      final candle = candles[i];
      final color = candle.isBullish ? AppTheme.green : AppTheme.red;
      
      // Prevent flat bodies (open == close) from rendering empty by adding a tiny offset
      double openY = candle.open;
      double closeY = candle.close;
      if (openY == closeY) {
        closeY += 0.05;
      }

      bars.add(
        LineChartBarData(
          spots: [
            FlSpot(i.toDouble(), openY),
            FlSpot(i.toDouble(), closeY),
          ],
          color: color,
          barWidth: 6.0, // Thicker bar to represent the body
          isCurved: false,
          dotData: const FlDotData(show: false),
        ),
      );
    }

    // 3. Draw EMA 20 Overlay Line
    if (ema20Values != null && ema20Values!.length == candles.length) {
      final List<FlSpot> ema20Spots = [];
      for (int i = 0; i < candles.length; i++) {
        final val = ema20Values![i];
        if (val > 0) {
          ema20Spots.add(FlSpot(i.toDouble(), val));
        }
      }
      if (ema20Spots.isNotEmpty) {
        bars.add(
          LineChartBarData(
            spots: ema20Spots,
            color: Colors.cyan,
            barWidth: 1.5,
            isCurved: true,
            curveSmoothness: 0.1,
            dotData: const FlDotData(show: false),
          ),
        );
      }
    }

    // 4. Draw EMA 50 Overlay Line
    if (ema50Values != null && ema50Values!.length == candles.length) {
      final List<FlSpot> ema50Spots = [];
      for (int i = 0; i < candles.length; i++) {
        final val = ema50Values![i];
        if (val > 0) {
          ema50Spots.add(FlSpot(i.toDouble(), val));
        }
      }
      if (ema50Spots.isNotEmpty) {
        bars.add(
          LineChartBarData(
            spots: ema50Spots,
            color: AppTheme.gold,
            barWidth: 1.5,
            isCurved: true,
            curveSmoothness: 0.1,
            dotData: const FlDotData(show: false),
          ),
        );
      }
    }

    return bars;
  }

  /// Builds a simple responsive legend overlay on top of the chart.
  Widget _buildLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildLegendItem('Bullish', AppTheme.green),
          const SizedBox(width: 12),
          _buildLegendItem('Bearish', AppTheme.red),
          if (ema20Values != null && ema20Values!.any((e) => e > 0)) ...[
            const SizedBox(width: 12),
            _buildLegendItem('EMA 20', Colors.cyan, isLine: true),
          ],
          if (ema50Values != null && ema50Values!.any((e) => e > 0)) ...[
            const SizedBox(width: 12),
            _buildLegendItem('EMA 50', AppTheme.gold, isLine: true),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isLine = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isLine ? 16 : 8,
          height: isLine ? 2 : 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: isLine ? null : BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
