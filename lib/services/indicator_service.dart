import 'dart:math';
import '../models/candle.dart';
import '../models/indicator_data.dart';
import '../utils/constants.dart';

/// Technical indicator calculation service
/// All indicators are computed locally from candlestick data
class IndicatorService {
  /// Calculate Exponential Moving Average (EMA)
  /// Returns a list of EMA values corresponding to the input closes
  static List<double> calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return [];

    final ema = <double>[];
    final multiplier = 2.0 / (period + 1);

    // SMA seed for the first EMA value
    double sma = 0;
    for (int i = 0; i < period; i++) {
      sma += prices[i];
    }
    sma /= period;
    ema.add(sma);

    // EMA for subsequent values
    for (int i = period; i < prices.length; i++) {
      final value = (prices[i] - ema.last) * multiplier + ema.last;
      ema.add(value);
    }

    return ema;
  }

  /// Calculate Relative Strength Index (RSI)
  static List<double> calculateRSI(List<double> prices, int period) {
    if (prices.length < period + 1) return [];

    final rsi = <double>[];
    final gains = <double>[];
    final losses = <double>[];

    // Calculate initial price changes
    for (int i = 1; i < prices.length; i++) {
      final change = prices[i] - prices[i - 1];
      gains.add(change > 0 ? change : 0);
      losses.add(change < 0 ? -change : 0);
    }

    // Initial average gain and loss (SMA)
    double avgGain = 0;
    double avgLoss = 0;
    for (int i = 0; i < period; i++) {
      avgGain += gains[i];
      avgLoss += losses[i];
    }
    avgGain /= period;
    avgLoss /= period;

    // First RSI
    double rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
    rsi.add(100 - (100 / (1 + rs)));

    // Subsequent RSI values using Wilder's smoothing
    for (int i = period; i < gains.length; i++) {
      avgGain = (avgGain * (period - 1) + gains[i]) / period;
      avgLoss = (avgLoss * (period - 1) + losses[i]) / period;
      rs = avgLoss == 0 ? 100 : avgGain / avgLoss;
      rsi.add(100 - (100 / (1 + rs)));
    }

    return rsi;
  }

  /// Calculate MACD (Moving Average Convergence Divergence)
  /// Returns (macdLine, signalLine, histogram) lists
  static ({List<double> macdLine, List<double> signalLine, List<double> histogram}) calculateMACD(
    List<double> prices, {
    int fastPeriod = AppConstants.macdFastPeriod,
    int slowPeriod = AppConstants.macdSlowPeriod,
    int signalPeriod = AppConstants.macdSignalPeriod,
  }) {
    final emaFast = calculateEMA(prices, fastPeriod);
    final emaSlow = calculateEMA(prices, slowPeriod);

    // MACD line = EMA(fast) - EMA(slow)
    // Align: EMA slow starts later, so we offset
    final offset = slowPeriod - fastPeriod;
    final macdLine = <double>[];
    for (int i = 0; i < emaSlow.length; i++) {
      macdLine.add(emaFast[i + offset] - emaSlow[i]);
    }

    // Signal line = EMA of MACD line
    final signalLine = calculateEMA(macdLine, signalPeriod);
    final signalOffset = macdLine.length - signalLine.length;

    // Histogram = MACD line - Signal line
    final histogram = <double>[];
    for (int i = 0; i < signalLine.length; i++) {
      histogram.add(macdLine[i + signalOffset] - signalLine[i]);
    }

    return (macdLine: macdLine, signalLine: signalLine, histogram: histogram);
  }

  /// Calculate Bollinger Bands
  /// Returns (upper, middle, lower) lists
  static ({List<double> upper, List<double> middle, List<double> lower}) calculateBollingerBands(
    List<double> prices, {
    int period = AppConstants.bollingerPeriod,
    double stdDev = AppConstants.bollingerStdDev,
  }) {
    if (prices.length < period) {
      return (upper: [], middle: [], lower: []);
    }

    final upper = <double>[];
    final middle = <double>[];
    final lower = <double>[];

    for (int i = period - 1; i < prices.length; i++) {
      // SMA (middle band)
      double sum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        sum += prices[j];
      }
      final sma = sum / period;

      // Standard deviation
      double varianceSum = 0;
      for (int j = i - period + 1; j <= i; j++) {
        varianceSum += pow(prices[j] - sma, 2);
      }
      final stdDeviation = sqrt(varianceSum / period);

      middle.add(sma);
      upper.add(sma + stdDeviation * stdDev);
      lower.add(sma - stdDeviation * stdDev);
    }

    return (upper: upper, middle: middle, lower: lower);
  }

  /// Calculate Average True Range (ATR)
  static List<double> calculateATR(List<Candle> candles, {int period = AppConstants.atrPeriod}) {
    if (candles.length < period + 1) return [];

    final trueRanges = <double>[];
    for (int i = 1; i < candles.length; i++) {
      final high = candles[i].high;
      final low = candles[i].low;
      final prevClose = candles[i - 1].close;
      final tr = [high - low, (high - prevClose).abs(), (low - prevClose).abs()].reduce(max);
      trueRanges.add(tr);
    }

    // First ATR is SMA of true ranges
    final atr = <double>[];
    double sum = 0;
    for (int i = 0; i < period; i++) {
      sum += trueRanges[i];
    }
    atr.add(sum / period);

    // Subsequent ATRs use Wilder's smoothing
    for (int i = period; i < trueRanges.length; i++) {
      final value = (atr.last * (period - 1) + trueRanges[i]) / period;
      atr.add(value);
    }

    return atr;
  }

  /// Find support and resistance levels using recent swing highs and lows
  static ({double support, double resistance}) calculateSupportResistance(
    List<Candle> candles, {
    int lookback = 50,
  }) {
    final recent = candles.length > lookback
        ? candles.sublist(candles.length - lookback)
        : candles;

    double support = double.infinity;
    double resistance = double.negativeInfinity;

    for (final candle in recent) {
      if (candle.low < support) support = candle.low;
      if (candle.high > resistance) resistance = candle.high;
    }

    // If we only have one candle, use its values
    if (support == double.infinity) support = recent.last.close;
    if (resistance == double.negativeInfinity) resistance = recent.last.close;

    return (support: support, resistance: resistance);
  }

  /// Calculate all indicators at once from candle data
  static IndicatorData calculateAll(List<Candle> candles) {
    final closes = candles.map((c) => c.close).toList();
    final currentPrice = closes.last;

    // EMA 20 & 50
    final ema20List = calculateEMA(closes, AppConstants.emaShortPeriod);
    final ema50List = calculateEMA(closes, AppConstants.emaLongPeriod);
    final ema20 = ema20List.isNotEmpty ? ema20List.last : currentPrice;
    final ema50 = ema50List.isNotEmpty ? ema50List.last : currentPrice;

    // RSI
    final rsiList = calculateRSI(closes, AppConstants.rsiPeriod);
    final rsi = rsiList.isNotEmpty ? rsiList.last : 50.0;

    // MACD
    final macdResult = calculateMACD(closes);
    final macdLine = macdResult.macdLine.isNotEmpty ? macdResult.macdLine.last : 0.0;
    final macdSignal = macdResult.signalLine.isNotEmpty ? macdResult.signalLine.last : 0.0;
    final macdHistogram = macdResult.histogram.isNotEmpty ? macdResult.histogram.last : 0.0;

    // Bollinger Bands
    final bbResult = calculateBollingerBands(closes);
    final bbUpper = bbResult.upper.isNotEmpty ? bbResult.upper.last : currentPrice;
    final bbMiddle = bbResult.middle.isNotEmpty ? bbResult.middle.last : currentPrice;
    final bbLower = bbResult.lower.isNotEmpty ? bbResult.lower.last : currentPrice;
    final bbWidth = bbUpper - bbLower;
    final bbPercentB = bbWidth > 0 ? (currentPrice - bbLower) / bbWidth : 0.5;

    // ATR
    final atrList = calculateATR(candles);
    final atr = atrList.isNotEmpty ? atrList.last : 0.0;

    // Support & Resistance
    final sr = calculateSupportResistance(candles);

    return IndicatorData(
      ema20: ema20,
      ema50: ema50,
      emaBullishCross: ema20 > ema50,
      emaBearishCross: ema20 < ema50,
      rsi: rsi,
      rsiOversold: rsi < 30,
      rsiOverbought: rsi > 70,
      macdLine: macdLine,
      macdSignal: macdSignal,
      macdHistogram: macdHistogram,
      macdBullishCross: macdLine > macdSignal,
      macdBearishCross: macdLine < macdSignal,
      bbUpper: bbUpper,
      bbMiddle: bbMiddle,
      bbLower: bbLower,
      bbPercentB: bbPercentB,
      atr: atr,
      support: sr.support,
      resistance: sr.resistance,
      currentPrice: currentPrice,
    );
  }
}
