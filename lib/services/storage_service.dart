import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signal.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===== API Key (Twelve Data) =====
  Future<String> getApiKey() async {
    final p = await _p;
    return p.getString(AppConstants.keyApiKey) ?? AppConstants.twelveDataDefaultKey;
  }
  Future<void> setApiKey(String key) async => (await _p).setString(AppConstants.keyApiKey, key);
  Future<void> clearApiKey() async => (await _p).remove(AppConstants.keyApiKey);

  // ===== Alpha Vantage API Key =====
  Future<String> getAlphaVantageKey() async {
    final p = await _p;
    return p.getString(AppConstants.keyAlphaVantageKey) ?? AppConstants.alphaVantageDefaultKey;
  }
  Future<void> setAlphaVantageKey(String key) async => (await _p).setString(AppConstants.keyAlphaVantageKey, key);

  // ===== API Provider =====
  Future<String> getApiProvider() async {
    final p = await _p;
    return p.getString(AppConstants.keyApiProvider) ?? AppConstants.defaultApiProvider;
  }
  Future<void> setApiProvider(String provider) async => (await _p).setString(AppConstants.keyApiProvider, provider);

  // ===== Selected Symbol =====
  Future<String> getSelectedSymbol() async {
    final p = await _p;
    return p.getString(AppConstants.keySelectedSymbol) ?? AppConstants.defaultSymbol;
  }
  Future<void> setSelectedSymbol(String symbol) async => (await _p).setString(AppConstants.keySelectedSymbol, symbol);

  // ===== Refresh Interval =====
  Future<int> getRefreshInterval() async {
    final p = await _p;
    return p.getInt(AppConstants.keyRefreshInterval) ?? AppConstants.defaultRefreshInterval;
  }
  Future<void> setRefreshInterval(int minutes) async => (await _p).setInt(AppConstants.keyRefreshInterval, minutes);

  // ===== Premium Status =====
  Future<bool> isPremium() async => (await _p).getBool(AppConstants.keyPremium) ?? false;
  Future<void> setPremium(bool value) async => (await _p).setBool(AppConstants.keyPremium, value);

  // ===== Price Alerts =====
  Future<List<PriceAlert>> getAlerts() async {
    final p = await _p;
    final jsonStr = p.getString(AppConstants.keyAlerts);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAlerts(List<PriceAlert> alerts) async {
    final p = await _p;
    await p.setString(AppConstants.keyAlerts, json.encode(alerts.map((a) => a.toJson()).toList()));
  }

  Future<void> addAlert(PriceAlert alert) async {
    final alerts = await getAlerts();
    alerts.add(alert);
    await saveAlerts(alerts);
  }

  Future<void> removeAlert(String id) async {
    final alerts = await getAlerts();
    alerts.removeWhere((a) => a.id == id);
    await saveAlerts(alerts);
  }

  Future<void> updateAlert(PriceAlert updated) async {
    final alerts = await getAlerts();
    final idx = alerts.indexWhere((a) => a.id == updated.id);
    if (idx >= 0) {
      alerts[idx] = updated;
      await saveAlerts(alerts);
    }
  }

  Future<void> markAlertTriggered(String id) async {
    final alerts = await getAlerts();
    final idx = alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      alerts[idx] = PriceAlert(
        id: alerts[idx].id,
        targetPrice: alerts[idx].targetPrice,
        isAbove: alerts[idx].isAbove,
        isActive: false,
        createdAt: alerts[idx].createdAt,
        triggered: true,
        symbol: alerts[idx].symbol,
      );
      await saveAlerts(alerts);
    }
  }
}
