import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signal.dart';
import '../utils/constants.dart';

/// Local storage service for persisting API key, alerts, and settings.
///
/// Implemented as a singleton so SharedPreferences is initialised once in
/// main() and the same instance is reused everywhere — avoiding the
/// LateInitializationError that occurs when a fresh instance is used before
/// init() is awaited.
class StorageService {
  // ── Singleton boilerplate ────────────────────────────────────────────────
  StorageService._internal();
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  // ────────────────────────────────────────────────────────────────────────

  SharedPreferences? _prefs;

  /// Must be called once in main() before runApp().
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Safe getter — falls back to a fresh instance if somehow called before init().
  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ===== API Key =====

  Future<String> getApiKey() async {
    final p = await _p;
    return p.getString(AppConstants.keyApiKey) ?? AppConstants.defaultApiKey;
  }

  Future<void> setApiKey(String key) async {
    final p = await _p;
    await p.setString(AppConstants.keyApiKey, key);
  }

  Future<void> clearApiKey() async {
    final p = await _p;
    await p.remove(AppConstants.keyApiKey);
  }

  // ===== Premium Status =====

  Future<bool> isPremium() async {
    final p = await _p;
    return p.getBool(AppConstants.keyPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    final p = await _p;
    await p.setBool(AppConstants.keyPremium, value);
  }

  // ===== Price Alerts =====

  Future<List<PriceAlert>> getAlerts() async {
    final p = await _p;
    final jsonStr = p.getString(AppConstants.keyAlerts);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list
        .map((e) => PriceAlert.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAlerts(List<PriceAlert> alerts) async {
    final p = await _p;
    final jsonStr = json.encode(alerts.map((a) => a.toJson()).toList());
    await p.setString(AppConstants.keyAlerts, jsonStr);
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

  /// Mark an alert as triggered (when price reaches target).
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
      );
      await saveAlerts(alerts);
    }
  }
}
