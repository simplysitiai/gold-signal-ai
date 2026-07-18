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
  static const List<TradingInstrument> availableSymbols = [
    // Commodities
    TradingInstrument(symbol: 'XAU/USD', display: 'XAUUSD', name: 'Gold / USD', category: 'Commodities'),
    TradingInstrument(symbol: 'XAG/USD', display: 'XAGUSD', name: 'Silver / USD', category: 'Commodities'),
    // Forex Majors
    TradingInstrument(symbol: 'EUR/USD', display: 'EURUSD', name: 'Euro / US Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'GBP/USD', display: 'GBPUSD', name: 'British Pound / USD', category: 'Forex'),
    TradingInstrument(symbol: 'USD/JPY', display: 'USDJPY', name: 'US Dollar / Japanese Yen', category: 'Forex'),
    TradingInstrument(symbol: 'USD/CHF', display: 'USDCHF', name: 'US Dollar / Swiss Franc', category: 'Forex'),
    TradingInstrument(symbol: 'AUD/USD', display: 'AUDUSD', name: 'Australian Dollar / USD', category: 'Forex'),
    TradingInstrument(symbol: 'USD/CAD', display: 'USDCAD', name: 'US Dollar / Canadian Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'NZD/USD', display: 'NZDUSD', name: 'NZ Dollar / USD', category: 'Forex'),
    TradingInstrument(symbol: 'EUR/GBP', display: 'EURGBP', name: 'Euro / British Pound', category: 'Forex'),
    TradingInstrument(symbol: 'EUR/JPY', display: 'EURJPY', name: 'Euro / Japanese Yen', category: 'Forex'),
    TradingInstrument(symbol: 'GBP/JPY', display: 'GBPJPY', name: 'GBP / Japanese Yen', category: 'Forex'),
    // Crypto
    TradingInstrument(symbol: 'BTC/USD', display: 'BTCUSD', name: 'Bitcoin / USD', category: 'Crypto'),
    TradingInstrument(symbol: 'ETH/USD', display: 'ETHUSD', name: 'Ethereum / USD', category: 'Crypto'),
    TradingInstrument(symbol: 'SOL/USD', display: 'SOLUSD', name: 'Solana / USD', category: 'Crypto'),
  ];

  // ─── Data refresh intervals (minutes) ─────────────────────────────────────
  // How often the app auto-refreshes data. 0 = manual only.
  static const List<int> refreshIntervals = [0, 1, 2, 5, 10, 15, 30];
  static const List<String> refreshIntervalLabels = ['Manual', '1 min', '2 min', '5 min', '10 min', '15 min', '30 min'];
  static const int defaultRefreshInterval = 5; // 5 minutes

  // ─── API providers ─────────────────────────────────────────────────────────
  static const String apiProviderTwelveData = 'twelve_data';
  static const String apiProviderAlphaVantage = 'alpha_vantage';
  static const String defaultApiProvider = apiProviderTwelveData;

  // Twelve Data API
  static const String twelveDataBaseUrl = 'https://api.twelvedata.com';
  static const String twelveDataDefaultKey = 'ff3a23ba9e654dd09c5cccb2193d28a7';

  // Alpha Vantage API — free key = demo, users must supply their own
  // https://www.alphavantage.co/support/#api-key
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co';
  static const String alphaVantageDefaultKey = 'demo';

  // Legacy compat
  static const String baseUrl = twelveDataBaseUrl;
  static const String priceEndpoint = '/price';
  static const String quoteEndpoint = '/quote';
  static const String timeSeriesEndpoint = '/time_series';

  // Available timeframes (Twelve Data interval values)
  static const List<String> intervals = ['1min', '5min', '15min', '30min', '1h', '4h', '1day'];
  static const List<String> intervalLabels = ['1m', '5m', '15m', '30m', '1H', '4H', '1D'];

  // Alpha Vantage interval mapping (for TIME_SERIES_INTRADAY)
  static const Map<String, String> avIntervalMap = {
    '1min': '1min',
    '5min': '5min',
    '15min': '15min',
    '30min': '30min',
    '1h': '60min',
    '4h': '60min', // AV doesn't have 4h, use 60min
    '1day': 'daily',
  };

  // SharedPreferences keys
  static const String keyApiKey = 'api_key';
  static const String keyPremium = 'is_premium';
  static const String keyAlerts = 'price_alerts';
  static const String keySelectedSymbol = 'selected_symbol';
  static const String keyRefreshInterval = 'refresh_interval';
  static const String keyApiProvider = 'api_provider';
  static const String keyAlphaVantageKey = 'alpha_vantage_key';

  // AdMob ad unit IDs (Google test IDs)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';

  // Indicator parameters
  static const int emaShortPeriod = 20;
  static const int emaLongPeriod = 50;
  static const int rsiPeriod = 14;
  static const int macdFastPeriod = 12;
  static const int macdSlowPeriod = 26;
  static const int macdSignalPeriod = 9;
  static const int bollingerPeriod = 20;
  static const double bollingerStdDev = 2.0;
  static const int atrPeriod = 14;
}

/// Represents a tradeable instrument available in the app
class TradingInstrument {
  final String symbol;
  final String display;
  final String name;
  final String category;

  const TradingInstrument({
    required this.symbol,
    required this.display,
    required this.name,
    required this.category,
  });
}

/// Disclaimer text shown throughout the app
const String appDisclaimer =
    'This application is for educational and informational purposes only. '
    'It does not provide financial advice or guarantee trading results. '
    'Users are responsible for their own trading decisions.';
