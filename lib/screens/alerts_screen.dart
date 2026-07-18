import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Alerts screen — manage price alerts for XAU/USD.
///
/// Users can set target prices and choose to be notified when the price
/// crosses above or below that level. Alerts are stored locally via
/// SharedPreferences and monitored via a background timer.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  List<PriceAlert> _alerts = [];
  double _currentPrice = 0;
  final _targetPriceController = TextEditingController();

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _loadAlerts();
    _fetchCurrentPrice();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  Future<void> _loadAlerts() async {
    final alerts = await _storage.getAlerts();
    setState(() => _alerts = alerts);
  }

  Future<void> _fetchCurrentPrice() async {
    try {
      final data = await _api.getRealTimePrice();
      setState(() => _currentPrice = double.parse(data['price'].toString()));
    } catch (_) {}
  }

  Future<void> _addAlert({required bool isAbove}) async {
    final target = double.tryParse(_targetPriceController.text.trim());
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }

    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetPrice: target,
      isAbove: isAbove,
      createdAt: DateTime.now(),
    );

    await _storage.addAlert(alert);
    _targetPriceController.clear();
    _loadAlerts();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert set: XAUUSD ${isAbove ? "above" : "below"} \$${target.toStringAsFixed(2)}'),
        backgroundColor: AppTheme.green,
      ),
    );
  }

  Future<void> _deleteAlert(String id) async {
    await _storage.removeAlert(id);
    _loadAlerts();
  }

  Future<void> _checkAlerts() async {
    await _fetchCurrentPrice();
    if (_currentPrice == 0) return;

    for (final alert in _alerts) {
      if (!alert.isActive || alert.triggered) continue;

      bool shouldTrigger = false;
      if (alert.isAbove && _currentPrice >= alert.targetPrice) shouldTrigger = true;
      if (!alert.isAbove && _currentPrice <= alert.targetPrice) shouldTrigger = true;

      if (shouldTrigger) {
        await _showNotification(alert);
        await _storage.markAlertTriggered(alert.id);
        _loadAlerts();
      }
    }
  }

  Future<void> _showNotification(PriceAlert alert) async {
    const androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFFFD700),
    );
    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      alert.id.hashCode,
      'XAUUSD Price Alert Triggered!',
      'Gold has ${alert.isAbove ? "risen above" : "fallen below"} \$${alert.targetPrice.toStringAsFixed(2)} '
      '(current: \$${_currentPrice.toStringAsFixed(2)})',
      details,
    );
  }

  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: () {
              _fetchCurrentPrice();
              _checkAlerts();
            },
            tooltip: 'Check Alerts',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current price display
          if (_currentPrice > 0)
            Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Price', style: TextStyle(color: Colors.white54, fontSize: 14)),
                    Text(
                      '\$${_currentPrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppTheme.gold, fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Set new alert
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SET NEW ALERT',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _targetPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Enter target price (e.g. ${_currentPrice > 0 ? _currentPrice.toStringAsFixed(0) : "4000"})',
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixText: '\$ ',
                      prefixStyle: const TextStyle(color: AppTheme.gold, fontSize: 18),
                      filled: true,
                      fillColor: AppTheme.blackLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addAlert(isAbove: true),
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          label: const Text('Above'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addAlert(isAbove: false),
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          label: const Text('Below'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active alerts list
          const Text(
            'ACTIVE ALERTS',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),

          if (_alerts.isEmpty)
            Card(
              color: AppTheme.surface,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.notifications_off, color: Colors.white24, size: 36),
                    SizedBox(height: 12),
                    Text('No alerts set', style: TextStyle(color: Colors.white38, fontSize: 14)),
                  ],
                ),
              ),
            )
          else
            ..._alerts.map((alert) => _buildAlertTile(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertTile(PriceAlert alert) {
    final color = alert.isAbove ? AppTheme.green : AppTheme.red;
    final direction = alert.isAbove ? 'Above' : 'Below';

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(alert.triggered ? Icons.check_circle : Icons.notifications_active, color: color, size: 20),
        ),
        title: Text(
          '$direction \$${alert.targetPrice.toStringAsFixed(2)}',
          style: TextStyle(
            color: alert.triggered ? Colors.white38 : Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            decoration: alert.triggered ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          alert.triggered ? 'Triggered' : 'Active • Set on ${alert.createdAt.toLocal().toString().substring(0, 16)}',
          style: const TextStyle(color: Colors.white38, fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white38, size: 20),
          onPressed: () => _deleteAlert(alert.id),
        ),
      ),
    );
  }
}
