/// App-wide constants for Gold Signal AI
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Gold Signal AI';
  static const String appVersion = '1.1.0';

  // Default symbol (Gold)
  static const String defaultSymbol = 'XAU/USD';
  static const String defaultSymbolDisplay = 'XAUUSD';

  // ─── Available trading instruments ─────────────────────────────────────────
  // Twelve Data supports forex, commodities, crypto, and stocks.
  // The app lets users switch between any of these.
  static const List<TradingInstrument> availableSymbols = [
    // Commodities
    TradingInstrument(symbol: 'XAU/USD', display: 'XAUUSD', name: 'Gold / USD', category: 'Commodities'),
    TradingInstrument(symbol: 'XAG/USD', display: 'XAGUSD', name: 'Silver / USD', category: 'Commodities'),
    // Forex Majors
    TradingInstrument(symbol: 'EUR/USD', display: 'EURUSD', name: 'Euro / US Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'GBP/USD', display: 'GBPUSD', name: 'British Pound / US Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'USD/JPY', display: 'USDJPY', name: 'US Dollar / Japanese Yen', category: 'Forex'),
    TradingInstrument(symbol: 'USD/CHF', display: 'USDCHF', name: 'US Dollar / Swiss Franc', category: 'Forex'),
    TradingInstrument(symbol: 'AUD/USD', display: 'AUDUSD', name: 'Australian Dollar / US Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'USD/CAD', display: 'USDCAD', name: 'US Dollar / Canadian Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'NZD/USD', display: 'NZDUSD', name: 'NZ Dollar / US Dollar', category: 'Forex'),
    TradingInstrument(symbol: 'EUR/GBP', display: 'EURGBP', name: 'Euro / British Pound', category: 'Forex'),
    TradingInstrument(symbol: 'EUR/JPY', display: 'EURJPY', name: 'Euro / Japanese Yen', category: 'Forex'),
    TradingInstrument(symbol: 'GBP/JPY', display: 'GBPJPY', name: 'British Pound / Japanese Yen', category: 'Forex'),
    // Crypto
    TradingInstrument(symbol: 'BTC/USD', display: 'BTCUSD', name: 'Bitcoin / USD', category: 'Crypto'),
    TradingInstrument(symbol: 'ETH/USD', display: 'ETHUSD', name: 'Ethereum / USD', category: 'Crypto'),
    TradingInstrument(symbol: 'SOL/USD', display: 'SOLUSD', name: 'Solana / USD', category: 'Crypto'),
  ];

  // Twelve Data API endpoints
  static const String baseUrl = 'https://api.twelvedata.com';
  static const String priceEndpoint = '/price';
  static const String quoteEndpoint = '/quote';
  static const String timeSeriesEndpoint = '/time_series';

  // Available timeframes (Twelve Data interval values)
  static const List<String> intervals = ['1min', '5min', '15min', '30min', '1h', '4h', '1day'];
  static const List<String> intervalLabels = ['1m', '5m', '15m', '30m', '1H', '4H', '1D'];

  // Default API key — Twelve Data free tier (800 requests/day, 8 requests/minute)
  // Users can override in Settings with their own key
  static const String defaultApiKey = 'ff3a23ba9e654dd09c5cccb2193d28a7';

  // SharedPreferences keys
  static const String keyApiKey = 'api_key';
  static const String keyPremium = 'is_premium';
  static const String keyAlerts = 'price_alerts';
  static const String keySelectedSymbol = 'selected_symbol';

  // AdMob ad unit IDs (replace with your own production IDs)
  // These are Google's test ad unit IDs — see:
  // https://developers.google.com/admob/android/test-ads
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // test banner
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // test rewarded

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
  final String symbol;       // API symbol, e.g. "XAU/USD"
  final String display;      // Compact display, e.g. "XAUUSD"
  final String name;         // Full name, e.g. "Gold / USD"
  final String category;      // "Commodities", "Forex", "Crypto"

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
