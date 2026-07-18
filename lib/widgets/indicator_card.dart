import 'package:flutter/material.dart';
import 'package:gold_signal_ai/utils/theme.dart';

/// A reusable card widget for displaying a single technical indicator.
///
/// Used to display indicators like EMA, RSI, MACD, Bollinger Bands, ATR,
/// or Support/Resistance in a consistent, clean format. Features a dark surface
/// background with a gold accent border and an optional custom [child] widget
/// for custom visualizations (e.g., mini-charts, scales, or progress bars).
class IndicatorCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final Color? indicatorColor;
  final Widget? child;

  const IndicatorCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.indicatorColor,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final activeIndicatorColor = indicatorColor ?? AppTheme.goldDark;

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.32),
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: indicatorColor != null 
              ? indicatorColor!.withOpacity(0.4) 
              : AppTheme.goldDark.withOpacity(0.25),
          width: indicatorColor != null ? 1.2 : 1.0,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Colored Indicator Stripe
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: activeIndicatorColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            
            // Content Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title Label
                    Text(
                      title.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Value and Subtitle Layout
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: TextStyle(
                              color: indicatorColor ?? Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            subtitle!,
                            style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                    // Custom Embedded Visualization (e.g. RSI Slider, MACD histogram representation)
                    if (child != null) ...[
                      const SizedBox(height: 12),
                      child!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
