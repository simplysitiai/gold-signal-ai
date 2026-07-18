import '../models/candle.dart';
import '../models/indicator_data.dart';
import '../models/signal.dart';
import '../utils/constants.dart';
import 'indicator_service.dart';

/// Signal engine — evaluates indicators and generates BUY/SELL/WAIT signals
///
/// The engine uses a weighted voting system across multiple indicators.
/// Each indicator casts a bullish, bearish, or neutral vote with a weight.
/// The final signal and confidence are derived from the aggregated votes.
class SignalEngine {
  /// Analyze candle data and generate a trading signal
  static TradingSignal analyze(List<Candle> candles) {
    if (candles.length < 50) {
      return TradingSignal(
        signal: SignalType.wait,
        confidence: 0,
        reasons: ['Not enough data to generate signal (need at least 50 candles)'],
        generatedAt: DateTime.now(),
      );
    }

    final data = IndicatorService.calculateAll(candles);
    final reasons = <String>[];
    int bullishScore = 0;
    int bearishScore = 0;
    int totalWeight = 0;

    // === EMA 20 vs EMA 50 (weight: 25) ===
    totalWeight += 25;
    if (data.emaBullishCross) {
      bullishScore += 25;
      reasons.add('EMA20 (${_fmt(data.ema20)}) is above EMA50 (${_fmt(data.ema50)}) — bullish trend');
    } else if (data.emaBearishCross) {
      bearishScore += 25;
      reasons.add('EMA20 (${_fmt(data.ema20)}) is below EMA50 (${_fmt(data.ema50)}) — bearish trend');
    } else {
      reasons.add('EMA20 and EMA50 are neutral');
    }

    // === RSI (weight: 20) ===
    totalWeight += 20;
    if (data.rsiOversold) {
      bullishScore += 20;
      reasons.add('RSI = ${data.rsi.toStringAsFixed(1)} — oversold, potential reversal up');
    } else if (data.rsiOverbought) {
      bearishScore += 20;
      reasons.add('RSI = ${data.rsi.toStringAsFixed(1)} — overbought, potential reversal down');
    } else if (data.rsi > 50) {
      bullishScore += 10;
      reasons.add('RSI = ${data.rsi.toStringAsFixed(1)} — above 50, mildly bullish');
    } else {
      bearishScore += 10;
      reasons.add('RSI = ${data.rsi.toStringAsFixed(1)} — below 50, mildly bearish');
    }

    // === MACD (weight: 25) ===
    totalWeight += 25;
    if (data.macdBullishCross && data.macdHistogram > 0) {
      bullishScore += 25;
      reasons.add('MACD bullish crossover (histogram ${data.macdHistogram.toStringAsFixed(3)})');
    } else if (data.macdBearishCross && data.macdHistogram < 0) {
      bearishScore += 25;
      reasons.add('MACD bearish crossover (histogram ${data.macdHistogram.toStringAsFixed(3)})');
    } else if (data.macdBullishCross) {
      bullishScore += 15;
      reasons.add('MACD line above signal — mildly bullish');
    } else if (data.macdBearishCross) {
      bearishScore += 15;
      reasons.add('MACD line below signal — mildly bearish');
    }

    // === Bollinger Bands (weight: 15) ===
    totalWeight += 15;
    if (data.bbPercentB < 0.2) {
      bullishScore += 15;
      reasons.add('Price near lower Bollinger Band — potential bounce');
    } else if (data.bbPercentB > 0.8) {
      bearishScore += 15;
      reasons.add('Price near upper Bollinger Band — potential pullback');
    } else {
      reasons.add('Price within Bollinger Bands (%B = ${data.bbPercentB.toStringAsFixed(2)})');
    }

    // === Support/Resistance (weight: 15) ===
    totalWeight += 15;
    final srRange = data.resistance - data.support;
    if (srRange > 0) {
      final pricePosition = (data.currentPrice - data.support) / srRange;
      if (pricePosition < 0.3) {
        bullishScore += 15;
        reasons.add('Price near support (${_fmt(data.support)}) — bounce zone');
      } else if (pricePosition > 0.7) {
        bearishScore += 15;
        reasons.add('Price near resistance (${_fmt(data.resistance)}) — rejection zone');
      } else {
        reasons.add('Price mid-range between support (${_fmt(data.support)}) and resistance (${_fmt(data.resistance)})');
      }
    }

    // === Determine signal ===
    final netScore = bullishScore - bearishScore;
    final confidencePercent = ((netScore.abs() / totalWeight) * 100).clamp(0, 100);

    SignalType signal;
    if (netScore > 15) {
      signal = SignalType.buy;
    } else if (netScore < -15) {
      signal = SignalType.sell;
    } else {
      signal = SignalType.wait;
    }

    // Add ATR context
    reasons.add('ATR = ${data.atr.toStringAsFixed(2)} — volatility indicator');

    return TradingSignal(
      signal: signal,
      confidence: confidencePercent.toDouble(),
      reasons: reasons,
      generatedAt: DateTime.now(),
    );
  }

  static String _fmt(double v) => v.toStringAsFixed(2);
}
