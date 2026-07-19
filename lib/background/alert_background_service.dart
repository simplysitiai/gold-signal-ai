import 'dart:ui';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

/// Background task name — must match what's registered in main.dart
const String kAlertCheckTask = 'gold_signal_alert_check';

/// Called by WorkManager in an isolate — runs even when app is killed/locked.
/// IMPORTANT: This runs in a separate isolate so no Flutter widgets, no setState.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == kAlertCheckTask) {
      await _runAlertCheck();
    }
    return Future.value(true);
  });
}

Future<void> _runAlertCheck() async {
  try {
    final storage = StorageService();
    await storage.init();

    final alerts = await storage.getAlerts();
    if (alerts.isEmpty) return;

    // Get unique symbols from active alerts
    final activeAlerts = alerts.where((a) => a.isActive && !a.triggered).toList();
    if (activeAlerts.isEmpty) return;

    final symbols = activeAlerts.map((a) => a.symbol).toSet();
    final api = ApiService();

    // Init notifications
    final notifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    await notifications.initialize(
      const InitializationSettings(android: androidSettings),
    );

    for (final symbol in symbols) {
      try {
        final priceData = await api.getRealTimePrice(symbol: symbol);
        final price = double.parse(priceData['price'].toString());

        final symbolAlerts = activeAlerts.where((a) => a.symbol == symbol);

        for (final alert in symbolAlerts) {
          final shouldTrigger =
              (alert.isAbove && price >= alert.targetPrice) ||
              (!alert.isAbove && price <= alert.targetPrice);

          if (shouldTrigger) {
            final inst = AppConstants.availableSymbols.firstWhere(
              (i) => i.symbol == symbol,
              orElse: () => AppConstants.availableSymbols.first,
            );

            await notifications.show(
              alert.id.hashCode,
              '🔔 ${inst.display} Price Alert!',
              '${inst.display} has ${alert.isAbove ? "risen above" : "fallen below"} '
                  '\$${alert.targetPrice.toStringAsFixed(inst.decimals)} '
                  '(now: \$${price.toStringAsFixed(inst.decimals)})',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'price_alerts',
                  'Price Alerts',
                  importance: Importance.high,
                  priority: Priority.high,
                  color: Color(0xFFFFD700),
                  playSound: true,
                ),
              ),
            );

            await storage.markAlertTriggered(alert.id);
          }
        }
      } catch (_) {
        // Skip this symbol on error — try others
      }
    }
  } catch (_) {
    // Silently fail — WorkManager will retry
  }
}
