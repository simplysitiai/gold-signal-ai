import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/signal.dart';
import '../utils/constants.dart';

/// Local storage service for persisting API key, alerts, and settings
class StorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ===== API Key =====

  Future<String> getApiKey() async {
    return _prefs.getString(AppConstants.keyApiKey) ?? AppConstants.defaultApiKey;
  }

  Future<void> setApiKey(String key) async {
    await _prefs.setString(AppConstants.keyApiKey, key);
  }

  Future<void> clearApiKey() async {
    await _prefs.remove(AppConstants.keyApiKey);
  }

  // ===== Premium Status =====

  Future<bool> isPremium() async {
    return _prefs.getBool(AppConstants.keyPremium) ?? false;
  }

  Future<void> setPremium(bool value) async {
    await _prefs.setBool(AppConstants.keyPremium, value);
  }

  // ===== Price Alerts =====

  Future<List<PriceAlert>> getAlerts() async {
    final jsonStr = _prefs.getString(AppConstants.keyAlerts);
    if (jsonStr == null) return [];
    final list = json.decode(jsonStr) as List;
    return list.map((e) => PriceAlert.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> saveAlerts(List<PriceAlert> alerts) async {
    final jsonStr = json.encode(alerts.map((a) => a.toJson()).toList());
    await _prefs.setString(AppConstants.keyAlerts, jsonStr);
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
}
