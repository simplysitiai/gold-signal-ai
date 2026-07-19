import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/candle.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Unified API service supporting both Twelve Data and Alpha Vantage.
///
/// Reads the active provider from StorageService and routes all calls
/// to the appropriate implementation. Screens call the same methods
/// regardless of which provider is active.
class ApiService {
  final StorageService _storage = StorageService();

  Future<String> _getTdKey() async => _storage.getApiKey();
  Future<String> _getAvKey() async => _storage.getAlphaVantageKey();
  Future<String> _getProvider() async => _storage.getApiProvider();

  Future<String> _getSymbol({String? symbol}) async =>
      symbol ?? await _storage.getSelectedSymbol();

  // ─── Public API ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRealTimePrice({String? symbol}) async {
    final sym = await _getSymbol(symbol: symbol);
    final provider = await _getProvider();
    if (provider == AppConstants.apiProviderAlphaVantage) {
      return _avGetPrice(sym);
    }
    return _tdGetPrice(sym);
  }

  Future<Map<String, dynamic>> getQuote({String? symbol}) async {
    final sym = await _getSymbol(symbol: symbol);
    final provider = await _getProvider();
    if (provider == AppConstants.apiProviderAlphaVantage) {
      return _avGetQuote(sym);
    }
    return _tdGetQuote(sym);
  }

  Future<List<Candle>> getTimeSeries({
    String interval = '1h',
    int outputsize = 200,
    String? symbol,
  }) async {
    final sym = await _getSymbol(symbol: symbol);
    final provider = await _getProvider();
    if (provider == AppConstants.apiProviderAlphaVantage) {
      return _avGetTimeSeries(sym, interval, outputsize);
    }
    return _tdGetTimeSeries(sym, interval, outputsize);
  }

  Future<bool> validateApiKey(String apiKey, {bool isAlphaVantage = false}) async {
    try {
      if (isAlphaVantage) {
        final url = '${AppConstants.alphaVantageBaseUrl}/query'
            '?function=CURRENCY_EXCHANGE_RATE'
            '&from_currency=XAU&to_currency=USD'
            '&apikey=$apiKey';
        final r = await http.get(Uri.parse(url));
        final d = json.decode(r.body) as Map<String, dynamic>;
        return d.containsKey('Realtime Currency Exchange Rate');
      }
      final url =
          '${AppConstants.twelveDataBaseUrl}/price?symbol=XAU/USD&apikey=$apiKey';
      final r = await http.get(Uri.parse(url));
      final d = json.decode(r.body) as Map<String, dynamic>;
      return d['status'] != 'error';
    } catch (_) {
      return false;
    }
  }

  // ─── Twelve Data ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _tdGetPrice(String symbol) async {
    final key = await _getTdKey();
    final url =
        '${AppConstants.twelveDataBaseUrl}/price?symbol=$symbol&apikey=$key';
    final r = await http.get(Uri.parse(url));
    final d = json.decode(r.body) as Map<String, dynamic>;
    if (d['status'] == 'error') throw Exception(d['message'] ?? 'Twelve Data error');
    return d;
  }

  Future<Map<String, dynamic>> _tdGetQuote(String symbol) async {
    final key = await _getTdKey();
    final url =
        '${AppConstants.twelveDataBaseUrl}/quote?symbol=$symbol&apikey=$key';
    final r = await http.get(Uri.parse(url));
    final d = json.decode(r.body) as Map<String, dynamic>;
    if (d['status'] == 'error') throw Exception(d['message'] ?? 'Twelve Data error');
    return d;
  }

  Future<List<Candle>> _tdGetTimeSeries(
      String symbol, String interval, int outputsize) async {
    final key = await _getTdKey();
    final url = '${AppConstants.twelveDataBaseUrl}/time_series'
        '?symbol=$symbol&interval=$interval&outputsize=$outputsize&apikey=$key';
    final r = await http.get(Uri.parse(url));
    final d = json.decode(r.body) as Map<String, dynamic>;
    if (d['status'] == 'error') throw Exception(d['message'] ?? 'Twelve Data error');
    final values = d['values'] as List<dynamic>;
    final candles =
        values.map((v) => Candle.fromTwelveData(v as Map<String, dynamic>)).toList();
    return candles.reversed.toList();
  }

  // ─── Alpha Vantage ─────────────────────────────────────────────────────────

  /// Split "XAU/USD" → {from: "XAU", to: "USD"}
  Map<String, String> _splitSymbol(String symbol) {
    final parts = symbol.replaceAll(' ', '').split('/');
    if (parts.length == 2) return {'from': parts[0], 'to': parts[1]};
    return {'from': symbol, 'to': 'USD'};
  }

  Future<Map<String, dynamic>> _avGetPrice(String symbol) async {
    final key = await _getAvKey();
    final sp = _splitSymbol(symbol);
    final url = '${AppConstants.alphaVantageBaseUrl}/query'
        '?function=CURRENCY_EXCHANGE_RATE'
        '&from_currency=${sp['from']}&to_currency=${sp['to']}'
        '&apikey=$key';
    final r = await http.get(Uri.parse(url));
    final d = json.decode(r.body) as Map<String, dynamic>;
    final rate = d['Realtime Currency Exchange Rate'] as Map<String, dynamic>?;
    if (rate == null) {
      throw Exception('Alpha Vantage: no data for $symbol. Check API key at alphavantage.co');
    }
    return {'price': rate['5. Exchange Rate']};
  }

  Future<Map<String, dynamic>> _avGetQuote(String symbol) async {
    final priceData = await _avGetPrice(symbol);
    final price = double.parse(priceData['price'].toString());
    try {
      final candles = await _avGetTimeSeries(symbol, '1day', 2);
      if (candles.isNotEmpty) {
        final today = candles.last;
        return {
          'open': today.open.toString(),
          'high': today.high.toString(),
          'low': today.low.toString(),
          'close': today.close.toString(),
          'change': (price - today.open).toString(),
          'percent_change': ((price - today.open) / today.open * 100).toString(),
        };
      }
    } catch (_) {}
    return {
      'open': price.toString(),
      'high': price.toString(),
      'low': price.toString(),
      'close': price.toString(),
      'change': '0',
      'percent_change': '0',
    };
  }

  Future<List<Candle>> _avGetTimeSeries(
      String symbol, String interval, int outputsize) async {
    final key = await _getAvKey();
    final sp = _splitSymbol(symbol);
    final avInterval = AppConstants.avIntervalMap[interval] ?? '60min';

    String url;
    if (avInterval == 'daily') {
      url = '${AppConstants.alphaVantageBaseUrl}/query'
          '?function=FX_DAILY'
          '&from_symbol=${sp['from']}&to_symbol=${sp['to']}'
          '&outputsize=${outputsize > 100 ? "full" : "compact"}'
          '&apikey=$key';
    } else {
      url = '${AppConstants.alphaVantageBaseUrl}/query'
          '?function=FX_INTRADAY'
          '&from_symbol=${sp['from']}&to_symbol=${sp['to']}'
          '&interval=$avInterval'
          '&outputsize=${outputsize > 100 ? "full" : "compact"}'
          '&apikey=$key';
    }

    final r = await http.get(Uri.parse(url));
    final d = json.decode(r.body) as Map<String, dynamic>;

    if (d.containsKey('Error Message')) throw Exception('Alpha Vantage: ${d["Error Message"]}');
    if (d.containsKey('Note')) throw Exception('Alpha Vantage rate limit reached. Try again in a minute.');
    if (d.containsKey('Information')) throw Exception('Alpha Vantage: ${d["Information"]}');

    final seriesKey = (d.keys).firstWhere(
      (k) => k.startsWith('Time Series') || k.startsWith('FX'),
      orElse: () => '',
    );
    if (seriesKey.isEmpty) throw Exception('Alpha Vantage: unexpected response format');

    final series = d[seriesKey] as Map<String, dynamic>;
    final candles = series.entries.map((e) {
      final v = e.value as Map<String, dynamic>;
      return Candle(
        timestamp: DateTime.parse(e.key),
        open: double.parse(v['1. open'].toString()),
        high: double.parse(v['2. high'].toString()),
        low: double.parse(v['3. low'].toString()),
        close: double.parse(v['4. close'].toString()),
        volume: 0,
      );
    }).toList();

    candles.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return candles.length > outputsize
        ? candles.sublist(candles.length - outputsize)
        : candles;
  }
}
