/// Candlestick data model representing OHLCV data
class Candle {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  Candle({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    this.volume = 0,
  });

  /// Parse a candle from Twelve Data time_series API response
  factory Candle.fromTwelveData(Map<String, dynamic> json) {
    return Candle(
      timestamp: DateTime.parse(json['datetime']),
      open: double.parse(json['open'].toString()),
      high: double.parse(json['high'].toString()),
      low: double.parse(json['low'].toString()),
      close: double.parse(json['close'].toString()),
      volume: json['volume'] != null ? double.parse(json['volume'].toString()) : 0,
    );
  }

  /// Whether this candle is bullish (close > open)
  bool get isBullish => close >= open;

  /// Whether this candle is bearish (close < open)
  bool get isBearish => close < open;

  /// Body size of the candle
  double get body => (close - open).abs();

  /// Range of the candle
  double get range => high - low;

  /// Typical price (high + low + close) / 3
  double get typicalPrice => (high + low + close) / 3;

  Map<String, dynamic> toJson() => {
    'datetime': timestamp.toIso8601String(),
    'open': open,
    'high': high,
    'low': low,
    'close': close,
    'volume': volume,
  };
}
