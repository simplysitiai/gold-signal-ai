/// Container for all calculated indicator values
class IndicatorData {
  // EMA
  final double ema20;
  final double ema50;
  final bool emaBullishCross; // EMA20 > EMA50
  final bool emaBearishCross; // EMA20 < EMA50

  // RSI
  final double rsi;
  final bool rsiOversold; // RSI < 30
  final bool rsiOverbought; // RSI > 70

  // MACD
  final double macdLine;
  final double macdSignal;
  final double macdHistogram;
  final bool macdBullishCross; // MACD line > signal line
  final bool macdBearishCross;

  // Bollinger Bands
  final double bbUpper;
  final double bbMiddle;
  final double bbLower;
  final double bbPercentB; // (price - lower) / (upper - lower)

  // ATR
  final double atr;

  // Support & Resistance
  final double support;
  final double resistance;

  // Current price
  final double currentPrice;

  IndicatorData({
    required this.ema20,
    required this.ema50,
    required this.emaBullishCross,
    required this.emaBearishCross,
    required this.rsi,
    required this.rsiOversold,
    required this.rsiOverbought,
    required this.macdLine,
    required this.macdSignal,
    required this.macdHistogram,
    required this.macdBullishCross,
    required this.macdBearishCross,
    required this.bbUpper,
    required this.bbMiddle,
    required this.bbLower,
    required this.bbPercentB,
    required this.atr,
    required this.support,
    required this.resistance,
    required this.currentPrice,
  });
}
