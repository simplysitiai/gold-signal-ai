import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/signal.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../widgets/symbol_selector.dart';

/// Alerts screen — manage price alerts for any supported instrument.
///
/// Users can set target prices and choose to be notified when the price
/// crosses above or below that level. Alerts are stored locally via
/// SharedPreferences and can be checked manually.
class AlertsScreen extends StatefulWidget {
  final String activeSymbol;
  final void Function(String) onSymbolChanged;

  const AlertsScreen({
    super.key,
    required this.activeSymbol,
    required this.onSymbolChanged,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  List<PriceAlert> _alerts = [];
  double _currentPrice = 0;
  late String _activeSymbol;
  String _alertSound = AppConstants.alertSoundDefault;
  final _targetPriceController = TextEditingController();

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _activeSymbol = widget.activeSymbol;
    _initNotifications();
    _loadAlerts();
    _loadAlertSound();
    _fetchCurrentPrice();
  }

  Future<void> _initNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  String _formatPrice(double price) {
    final inst = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == _activeSymbol,
      orElse: () => AppConstants.availableSymbols.first,
    );
    return price.toStringAsFixed(inst.decimals);
  }

    void _onSymbolChanged(String symbol) {
    widget.onSymbolChanged(symbol);
  }

  Future<void> _loadAlertSound() async {
    final sound = await _storage.getAlertSound();
    setState(() => _alertSound = sound);
  }

  Future<void> _loadAlerts() async {
    final alerts = await _storage.getAlerts();
    // Show alerts for the active symbol, plus all other symbols
    setState(() => _alerts = alerts);
  }

  Future<void> _fetchCurrentPrice() async {
    try {
      final data = await _api.getRealTimePrice(symbol: _activeSymbol);
      setState(() => _currentPrice = double.parse(data['price'].toString()));
    } catch (_) {}
  }

  Future<void> _addAlert({required bool isAbove}) async {
    final target = double.tryParse(_targetPriceController.text.trim());
    if (target == null || target <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid price'),
          backgroundColor: AppTheme.red,
        ),
      );
      return;
    }

    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == _activeSymbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      targetPrice: target,
      isAbove: isAbove,
      createdAt: DateTime.now(),
      symbol: _activeSymbol,
    );

    await _storage.addAlert(alert);
    _targetPriceController.clear();
    _loadAlerts();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '$displaySymbol ${isAbove ? "above" : "below"} \$${target.toStringAsFixed(2)}'),
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
      // Only check alerts for the active symbol
      if (alert.symbol != _activeSymbol) continue;

      bool shouldTrigger = false;
      if (alert.isAbove && _currentPrice >= alert.targetPrice) {
        shouldTrigger = true;
      }
      if (!alert.isAbove && _currentPrice <= alert.targetPrice) {
        shouldTrigger = true;
      }

      if (shouldTrigger) {
        await _showNotification(alert);
        await _storage.markAlertTriggered(alert.id);
        _loadAlerts();
      }
    }
  }

  Future<void> _showNotification(PriceAlert alert) async {
    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == alert.symbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

    // Map sound name to raw resource
    String soundName = '';
    if (_alertSound == AppConstants.alertSoundBell) soundName = 'bell';
    else if (_alertSound == AppConstants.alertSoundCoin) soundName = 'coin';
    else if (_alertSound == AppConstants.alertSoundAlarm) soundName = 'alarm';
    else if (_alertSound == AppConstants.alertSoundWhistle) soundName = 'whistle';

    final androidDetails = AndroidNotificationDetails(
      'price_alerts',
      'Price Alerts',
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFFFFD700),
      sound: soundName.isNotEmpty ? RawResourceAndroidNotificationSound(soundName) : null,
      playSound: true,
    );
    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      alert.id.hashCode,
      '$displaySymbol Price Alert Triggered!',
      '$displaySymbol has ${alert.isAbove ? "risen above" : "fallen below"} '
      '\$${alert.targetPrice.toStringAsFixed(2)} '
      '(current: \$${_currentPrice.toStringAsFixed(2)})',
      details,
    );
  }


  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSymbol != widget.activeSymbol) {
      setState(() => _activeSymbol = widget.activeSymbol);
      _loadAlerts();
      _fetchCurrentPrice();
    }
  }
  @override
  void dispose() {
    _targetPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == _activeSymbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Price Alerts'),
        actions: [
          SymbolSelector(
              selectedSymbol: _activeSymbol,
              compact: true, onSymbolChanged: _onSymbolChanged),
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
          Card(
              color: AppTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$displaySymbol',
                            style: const TextStyle(
                                color: AppTheme.gold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                        const Text('Current Price',
                            style: TextStyle(color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                    _currentPrice > 0
                      ? Text(
                          _formatPrice(_currentPrice),
                      style: const TextStyle(
                          color: AppTheme.gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                        )
                      : const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: AppTheme.gold, strokeWidth: 2),
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
                  Text(
                    'SET NEW ALERT — $displaySymbol',
                    style: const TextStyle(
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
                      hintText:
                          'Enter target price (e.g. ${_currentPrice > 0 ? _currentPrice.toStringAsFixed(0) : "4000"})',
                      hintStyle: const TextStyle(color: Colors.white24),
                      prefixText: '\$ ',
                      prefixStyle:
                          const TextStyle(color: AppTheme.gold, fontSize: 18),
                      filled: true,
                      fillColor: AppTheme.blackLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: AppTheme.goldDark.withOpacity(0.3)),
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
            'ALL ALERTS',
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
                    Icon(Icons.notifications_off,
                        color: Colors.white24, size: 36),
                    SizedBox(height: 12),
                    Text('No alerts set',
                        style: TextStyle(color: Colors.white38, fontSize: 14)),
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

    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == alert.symbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteAlert(alert.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        color: AppTheme.surface,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: ListTile(
          leading: Icon(
            alert.triggered ? Icons.check_circle : Icons.notifications_active,
            color: alert.triggered ? Colors.white24 : color,
          ),
          title: Row(
            children: [
              Text(
                displaySymbol,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  direction,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Text(
            '\$${alert.targetPrice.toStringAsFixed(2)}'
            '${alert.triggered ? " — Triggered" : ""}',
            style: TextStyle(
              color: alert.triggered ? Colors.white24 : Colors.white54,
              fontSize: 13,
            ),
          ),
          trailing: alert.triggered
              ? const Icon(Icons.check, color: Colors.white24, size: 20)
              : IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.white38, size: 20),
                  onPressed: () => _deleteAlert(alert.id),
                ),
        ),
      ),
    );
  }
}
