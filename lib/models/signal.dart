/// Trading signal types
enum SignalType { buy, sell, wait }

/// Signal model — represents the output of the signal engine
class TradingSignal {
  final SignalType signal;
  final double confidence; // 0-100
  final List<String> reasons;
  final DateTime generatedAt;

  TradingSignal({
    required this.signal,
    required this.confidence,
    required this.reasons,
    required this.generatedAt,
  });

  /// Human-readable signal name
  String get signalName {
    switch (signal) {
      case SignalType.buy:
        return 'BUY';
      case SignalType.sell:
        return 'SELL';
      case SignalType.wait:
        return 'WAIT';
    }
  }

  /// Color-associated signal for UI
  String get signalEmoji {
    switch (signal) {
      case SignalType.buy:
        return '▲';
      case SignalType.sell:
        return '▼';
      case SignalType.wait:
        return '◆';
    }
  }
}

/// Price alert model — supports alerts for any trading instrument
class PriceAlert {
  final String id;
  final double targetPrice;
  final bool isAbove; // true = alert when price goes above, false = below
  final bool isActive;
  final DateTime createdAt;
  final bool triggered;
  final String symbol; // e.g. "XAU/USD", "EUR/USD"

  PriceAlert({
    required this.id,
    required this.targetPrice,
    required this.isAbove,
    this.isActive = true,
    required this.createdAt,
    this.triggered = false,
    this.symbol = 'XAU/USD',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'targetPrice': targetPrice,
    'isAbove': isAbove,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
    'triggered': triggered,
    'symbol': symbol,
  };

  factory PriceAlert.fromJson(Map<String, dynamic> json) {
    return PriceAlert(
      id: json['id'],
      targetPrice: (json['targetPrice'] as num).toDouble(),
      isAbove: json['isAbove'] as bool,
      isActive: json['isActive'] as bool,
      createdAt: DateTime.parse(json['createdAt']),
      triggered: json['triggered'] as bool? ?? false,
      symbol: json['symbol'] as String? ?? 'XAU/USD',
    );
  }
}
