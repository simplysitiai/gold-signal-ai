import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gold_signal_ai/models/signal.dart';
import 'package:gold_signal_ai/utils/theme.dart';

/// A card widget displaying a [TradingSignal].
///
/// Shows the signal name (BUY/SELL/WAIT) in large colored text, the signal confidence
/// as a circular progress indicator with percentage, bullet-pointed reasons,
/// and a disclaimer footer indicating confidence is an estimate.
class SignalCard extends StatelessWidget {
  final TradingSignal signal;

  const SignalCard({
    super.key,
    required this.signal,
  });

  @override
  Widget build(BuildContext context) {
    Color signalColor;
    IconData signalIcon;
    String signalDescText;

    switch (signal.signal) {
      case SignalType.buy:
        signalColor = AppTheme.green;
        signalIcon = Icons.arrow_upward;
        signalDescText = 'Bullish Trend Detected';
        break;
      case SignalType.sell:
        signalColor = AppTheme.red;
        signalIcon = Icons.arrow_downward;
        signalDescText = 'Bearish Trend Detected';
        break;
      case SignalType.wait:
        signalColor = AppTheme.gold;
        signalIcon = Icons.hourglass_empty;
        signalDescText = 'Neutral Market State';
        break;
    }

    final formattedDate = DateFormat('MM/dd HH:mm').format(signal.generatedAt);

    return Card(
      elevation: 6,
      shadowColor: Colors.black54,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: signalColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Signal Name & Confidence Circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI TRADING SIGNAL',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '${signal.signalEmoji} ${signal.signalName}',
                          style: TextStyle(
                            color: signalColor,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      signalDescText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Confidence Circular Indicator with Center Text
                _buildConfidenceIndicator(signal.confidence, signalColor),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: Colors.white10),
            const SizedBox(height: 14),

            // Bullet Point Reasons Header
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppTheme.gold, size: 16),
                SizedBox(width: 6),
                Text(
                  'ANALYSIS BREAKDOWN',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bullet Point Reasons List
            if (signal.reasons.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 22.0),
                child: Text(
                  'No technical indicators triggered criteria.',
                  style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
                ),
              )
            else
              ...signal.reasons.map((reason) => _buildReasonItem(reason, signalColor)),

            const SizedBox(height: 18),
            const Divider(color: Colors.white10),
            const SizedBox(height: 12),

            // Footer row with date & estimate disclaimer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white38, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      'Generated: $formattedDate',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'RE-EVALUATING',
                    style: TextStyle(
                      color: AppTheme.goldDark,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Disclaimer Warning
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: AppTheme.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.red.withOpacity(0.15), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 14),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Confidence is an estimate, not a guarantee.',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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

  /// Builds a stacked circular progress indicator displaying signal confidence in the center.
  Widget _buildConfidenceIndicator(double confidence, Color themeColor) {
    // Clamp confidence between 0 and 100
    final double clampedConf = confidence.clamp(0.0, 100.0);
    final double fraction = clampedConf / 100.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 58,
          height: 58,
          child: CircularProgressIndicator(
            value: fraction,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            strokeWidth: 4.5,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${clampedConf.toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'CONF',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a single bullet point item for breakdown list.
  Widget _buildReasonItem(String reason, Color bulletColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Icon(
              Icons.radio_button_checked,
              color: bulletColor.withOpacity(0.8),
              size: 10,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reason,
              style: const TextStyle(
                color: Color(0xDDFFFFFF),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
