/// App-wide constants for Signal Pro — Multi-Market Technical Analysis
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Signal Pro';
  static const String appVersion = '1.2.0';

  // Default symbol (Gold)
  static const String defaultSymbol = 'XAU/USD';
  static const String defaultSymbolDisplay = 'XAUUSD';

  // ─── Available trading instruments ─────────────────────────────────────────
  // decimals = how many decimal places to show for price formatting
  static const List<TradingInstrument> availableSymbols = [
    // Commodities
    TradingInstrument(symbol: 'XAU/USD', display: 'XAUUSD', name: 'Gold / USD',           category: 'Commodities', decimals: 2),
    TradingInstrument(symbol: 'XAG/USD', display: 'XAGUSD', name: 'Silver / USD',          category: 'Commodities', decimals: 4),
    // Forex Majors
    TradingInstrument(symbol: 'EUR/USD', display: 'EURUSD', name: 'Euro / US Dollar',       category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'GBP/USD', display: 'GBPUSD', name: 'British Pound / USD',    category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'USD/JPY', display: 'USDJPY', name: 'USD / Japanese Yen',     category: 'Forex',       decimals: 3),
    TradingInstrument(symbol: 'USD/CHF', display: 'USDCHF', name: 'USD / Swiss Franc',      category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'AUD/USD', display: 'AUDUSD', name: 'Australian Dollar / USD',category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'USD/CAD', display: 'USDCAD', name: 'USD / Canadian Dollar',  category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'NZD/USD', display: 'NZDUSD', name: 'NZ Dollar / USD',        category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'EUR/GBP', display: 'EURGBP', name: 'Euro / British Pound',   category: 'Forex',       decimals: 5),
    TradingInstrument(symbol: 'EUR/JPY', display: 'EURJPY', name: 'Euro / Japanese Yen',    category: 'Forex',       decimals: 3),
    TradingInstrument(symbol: 'GBP/JPY', display: 'GBPJPY', name: 'GBP / Japanese Yen',    category: 'Forex',       decimals: 3),
    // Crypto
    TradingInstrument(symbol: 'BTC/USD', display: 'BTCUSD', name: 'Bitcoin / USD',          category: 'Crypto',      decimals: 2),
    TradingInstrument(symbol: 'ETH/USD', display: 'ETHUSD', name: 'Ethereum / USD',         category: 'Crypto',      decimals: 2),
    TradingInstrument(symbol: 'SOL/USD', display: 'SOLUSD', name: 'Solana / USD',           category: 'Crypto',      decimals: 3),
  ];

  /// Get decimal count for a given API symbol (e.g. "EUR/USD" → 5)
  static int decimalsForSymbol(String symbol) {
    try {
      return availableSymbols.firstWhere((i) => i.symbol == symbol).decimals;
    } catch (_) {
      return 5; // safe fallback
    }
  }

  // ─── Data refresh intervals (minutes) ─────────────────────────────────────
  static const List<int> refreshIntervals = [0, 1, 2, 5, 10, 15, 30];
  static const List<String> refreshIntervalLabels = ['Manual', '1 min', '2 min', '5 min', '10 min', '15 min', '30 min'];
  static const int defaultRefreshInterval = 5;

  // ─── API providers ─────────────────────────────────────────────────────────
  static const String apiProviderTwelveData  = 'twelve_data';
  static const String apiProviderAlphaVantage = 'alpha_vantage';
  static const String defaultApiProvider     = apiProviderTwelveData;

  // Twelve Data
  static const String twelveDataBaseUrl  = 'https://api.twelvedata.com';
  static const String twelveDataDefaultKey = 'ff3a23ba9e654dd09c5cccb2193d28a7';

  // Alpha Vantage
  static const String alphaVantageBaseUrl  = 'https://www.alphavantage.co';
  static const String alphaVantageDefaultKey = 'demo';

  // Legacy compat aliases
  static const String baseUrl           = twelveDataBaseUrl;
  static const String priceEndpoint     = '/price';
  static const String quoteEndpoint     = '/quote';
  static const String timeSeriesEndpoint = '/time_series';

  // Timeframes
  static const List<String> intervals      = ['1min', '5min', '15min', '30min', '1h', '4h', '1day'];
  static const List<String> intervalLabels = ['1m',   '5m',   '15m',   '30m',   '1H', '4H', '1D'];

  // Alpha Vantage interval mapping
  static const Map<String, String> avIntervalMap = {
    '1min':  '1min',
    '5min':  '5min',
    '15min': '15min',
    '30min': '30min',
    '1h':    '60min',
    '4h':    '60min',
    '1day':  'daily',
  };

  // Chart settings
  static const double defaultCandleWidth = 6.0;   // body width in px
  static const double minCandleWidth = 2.0;
  static const double maxCandleWidth = 12.0;

  // Alert sound options
  static const String alertSoundDefault = 'default';
  static const String alertSoundBell     = 'bell';
  static const String alertSoundCoin    = 'coin';
  static const String alertSoundAlarm    = 'alarm';
  static const String alertSoundWhistle  = 'whistle';
  static const List<String> alertSounds = [alertSoundDefault, alertSoundBell, alertSoundCoin, alertSoundAlarm, alertSoundWhistle];
  static const List<String> alertSoundLabels = ['Default', 'Bell', 'Coin', 'Alarm', 'Whistle'];

  // SharedPreferences keys
  static const String keyApiKey          = 'api_key';
  static const String keyPremium         = 'is_premium';
  static const String keyAlerts          = 'price_alerts';
  static const String keySelectedSymbol  = 'selected_symbol';
  static const String keyRefreshInterval = 'refresh_interval';
  static const String keyApiProvider     = 'api_provider';
  static const String keyAlphaVantageKey = 'alpha_vantage_key';
  static const String keyCandleWidth    = 'candle_width';
  static const String keyAlertSound    = 'alert_sound';

  // AdMob test IDs
  static const String bannerAdUnitId   = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Indicator parameters
  static const int    emaShortPeriod    = 20;
  static const int    emaLongPeriod     = 50;
  static const int    rsiPeriod         = 14;
  static const int    macdFastPeriod    = 12;
  static const int    macdSlowPeriod    = 26;
  static const int    macdSignalPeriod  = 9;
  static const int    bollingerPeriod   = 20;
  static const double bollingerStdDev   = 2.0;
  static const int    atrPeriod         = 14;
}

/// Represents a tradeable instrument
class TradingInstrument {
  final String symbol;    // API symbol, e.g. "EUR/USD"
  final String display;   // Short code, e.g. "EURUSD"
  final String name;      // Full name
  final String category;  // "Commodities" | "Forex" | "Crypto"
  final int    decimals;  // Decimal places for price display

  const TradingInstrument({
    required this.symbol,
    required this.display,
    required this.name,
    required this.category,
    required this.decimals,
  });
}

/// Disclaimer text
const String appDisclaimer =
    'This application is for educational and informational purposes only. '
    'It does not provide financial advice or guarantee trading results. '
    'Users are responsible for their own trading decisions.';
