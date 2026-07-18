/// App-wide constants for Gold Signal AI
class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'Gold Signal AI';
  static const String appVersion = '1.0.0';

  // XAUUSD symbol — the only instrument this app tracks
  static const String symbol = 'XAU/USD';
  static const String symbolDisplay = 'XAUUSD';

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

/// Disclaimer text shown throughout the app
const String appDisclaimer =
    'This application is for educational and informational purposes only. '
    'It does not provide financial advice or guarantee trading results. '
    'Users are responsible for their own trading decisions.';
