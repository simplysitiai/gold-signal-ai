import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Twelve Data API service for fetching market data.
///
/// All methods accept an optional [symbol] parameter (default: XAU/USD).
/// This lets the app fetch data for any supported instrument — forex,
/// commodities, crypto, or stocks.
class ApiService {
  final StorageService _storage = StorageService();

  /// Get the current API key (user-provided or default)
  Future<String> _getApiKey() async {
    final key = await _storage.getApiKey();
    return key.isNotEmpty ? key : AppConstants.defaultApiKey;
  }

  /// Get the currently selected symbol from storage (or default XAU/USD)
  Future<String> _getSymbol({String? symbol}) async {
    if (symbol != null) return symbol;
    return await _storage.getSelectedSymbol();
  }

  /// Get current real-time price
  Future<Map<String, dynamic>> getRealTimePrice({String? symbol}) async {
    final apiKey = await _getApiKey();
    final sym = await _getSymbol(symbol: symbol);
    final url = '${AppConstants.baseUrl}${AppConstants.priceEndpoint}'
        '?symbol=$sym&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Failed to fetch price');
    }

    return data;
  }

  /// Get quote data (includes open, high, low, close, change, etc.)
  Future<Map<String, dynamic>> getQuote({String? symbol}) async {
    final apiKey = await _getApiKey();
    final sym = await _getSymbol(symbol: symbol);
    final url = '${AppConstants.baseUrl}${AppConstants.quoteEndpoint}'
        '?symbol=$sym&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Failed to fetch quote');
    }

    return data;
  }

  /// Get historical candlestick data (time series)
  Future<List<Candle>> getTimeSeries({
    String interval = '1h',
    int outputsize = 200,
    String? symbol,
  }) async {
    final apiKey = await _getApiKey();
    final sym = await _getSymbol(symbol: symbol);
    final url = '${AppConstants.baseUrl}${AppConstants.timeSeriesEndpoint}'
        '?symbol=$sym'
        '&interval=$interval'
        '&outputsize=$outputsize'
        '&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Failed to fetch time series');
    }

    final values = data['values'] as List;
    final candles = values.map((v) => Candle.fromTwelveData(v)).toList();
    // Twelve Data returns newest first — reverse for chronological order
    return candles.reversed.toList();
  }

  /// Get EMA value from Twelve Data API
  Future<double> getEMA(int period, {String interval = '1h', String? symbol}) async {
    final apiKey = await _getApiKey();
    final sym = await _getSymbol(symbol: symbol);
    final url = '${AppConstants.baseUrl}/ema'
        '?symbol=$sym'
        '&interval=$interval'
        '&time_period=$period'
        '&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Failed to fetch EMA');
    }

    final values = data['values'] as List;
    return double.parse(values[0]['ema'].toString());
  }

  /// Get RSI value from Twelve Data API
  Future<double> getRSI({String interval = '1h', int period = 14, String? symbol}) async {
    final apiKey = await _getApiKey();
    final sym = await _getSymbol(symbol: symbol);
    final url = '${AppConstants.baseUrl}/rsi'
        '?symbol=$sym'
        '&interval=$interval'
        '&time_period=$period'
        '&apikey=$apiKey';

    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);

    if (data['status'] == 'error') {
      throw Exception(data['message'] ?? 'Failed to fetch RSI');
    }

    final values = data['values'] as List;
    return double.parse(values[0]['rsi'].toString());
  }

  /// Check if the API key is valid by making a test request
  Future<bool> validateApiKey(String apiKey) async {
    try {
      final url = '${AppConstants.baseUrl}${AppConstants.priceEndpoint}'
          '?symbol=XAU/USD&apikey=$apiKey';
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      return data['status'] != 'error';
    } catch (_) {
      return false;
    }
  }
}
