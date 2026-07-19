import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// SharedPreferences and checked automatically every 60 seconds while
/// the screen is active, and also on app resume.
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

class _AlertsScreenState extends State<AlertsScreen>
    with WidgetsBindingObserver {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  List<PriceAlert> _alerts = [];
  double _currentPrice = 0;
  late String _activeSymbol;
  String _alertSound = AppConstants.alertSoundDefault;
  final _targetPriceController = TextEditingController();

  // Auto-check timer — runs every 60 seconds while screen is visible
  Timer? _checkTimer;

  // Notification plugin
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _activeSymbol = widget.activeSymbol;
    WidgetsBinding.instance.addObserver(this);
    _initNotifications();
    _loadAlerts();
    _loadAlertSound();
    _fetchCurrentPrice().then((_) => _checkAlerts());
    _startAutoCheck();
  }

  /// Re-check alerts when the app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchCurrentPrice().then((_) => _checkAlerts());
    }
  }

  void _startAutoCheck() {
    _checkTimer?.cancel();
    // Check every 60 seconds automatically
    _checkTimer = Timer.periodic(const Duration(seconds: 60), (_) async {
      await _fetchCurrentPrice();
      _checkAlerts();
    });
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
    setState(() => _alerts = alerts);
  }

  Future<void> _fetchCurrentPrice() async {
    try {
      final data = await _api.getRealTimePrice(symbol: _activeSymbol);
      if (mounted) {
        setState(
            () => _currentPrice = double.parse(data['price'].toString()));
      }
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

    // Immediately check if the new alert is already triggered
    _checkAlerts();
  }

  Future<void> _deleteAlert(String id) async {
    await _storage.removeAlert(id);
    _loadAlerts();
  }

  Future<void> _checkAlerts() async {
    if (_currentPrice == 0) return;

    bool anyTriggered = false;

    for (final alert in _alerts) {
      if (!alert.isActive || alert.triggered) continue;

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
        anyTriggered = true;
      }
    }

    // Reload list once after all checks so UI reflects triggered state
    if (anyTriggered) _loadAlerts();
  }

  Future<void> _showNotification(PriceAlert alert) async {
    final displaySymbol = AppConstants.availableSymbols
        .firstWhere((i) => i.symbol == alert.symbol,
            orElse: () => AppConstants.availableSymbols.first)
        .display;

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
      sound: soundName.isNotEmpty
          ? RawResourceAndroidNotificationSound(soundName)
          : null,
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

    // Also show an in-app snackbar so user sees it immediately
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔔 $displaySymbol ${alert.isAbove ? "↑ above" : "↓ below"} '
            '\$${alert.targetPrice.toStringAsFixed(2)}',
          ),
          backgroundColor: AppTheme.gold,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AlertsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSymbol != widget.activeSymbol) {
      setState(() => _activeSymbol = widget.activeSymbol);
      _loadAlerts();
      _fetchCurrentPrice().then((_) => _checkAlerts());
    }
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
              compact: true,
              onSymbolChanged: _onSymbolChanged),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.gold),
            onPressed: () async {
              await _fetchCurrentPrice();
              _checkAlerts();
            },
            tooltip: 'Check Alerts Now',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current price display
          Card(
            color: AppTheme.surface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                              color: AppTheme.gold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                      const Text('Current Price',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
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
                          child: CircularProgressIndicator(
                              color: AppTheme.gold, strokeWidth: 2),
                        ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Auto-check indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: const [
                Icon(Icons.timer, color: Colors.white38, size: 14),
                SizedBox(width: 8),
                Text(
                  'Auto-checking every 60 seconds',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*')),
                    ],
                    style:
                        const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: _currentPrice > 0
                          ? 'e.g. ${_formatPrice(_currentPrice)}'
                          : 'Target price',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.attach_money,
                          color: AppTheme.gold, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addAlert(isAbove: true),
                          icon: const Icon(Icons.arrow_upward, size: 16),
                          label: const Text('Alert Above'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addAlert(isAbove: false),
                          icon: const Icon(Icons.arrow_downward, size: 16),
                          label: const Text('Alert Below'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
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

          // Alerts list header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACTIVE ALERTS',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '${_alerts.where((a) => !a.triggered && a.isActive).length} active',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_alerts.isEmpty)
            Card(
              color: AppTheme.surface,
              child: const Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none,
                        color: Colors.white24, size: 36),
                    SizedBox(height: 8),
                    Text('No alerts set',
                        style:
                            TextStyle(color: Colors.white38, fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Set a target price above to get notified',
                        style:
                            TextStyle(color: Colors.white24, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ..._alerts.map((alert) => _buildAlertTile(alert)).toList(),
        ],
      ),
    );
  }

  Widget _buildAlertTile(PriceAlert alert) {
    final inst = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == alert.symbol,
      orElse: () => AppConstants.availableSymbols.first,
    );
    final color = alert.isAbove ? AppTheme.green : AppTheme.red;
    final diff = _currentPrice > 0
        ? (_currentPrice - alert.targetPrice).abs()
        : null;

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: alert.triggered
              ? Colors.white10
              : color.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        leading: Icon(
          alert.triggered ? Icons.check_circle : Icons.notifications_active,
          color: alert.triggered ? Colors.white24 : color,
        ),
        title: Text(
          '${inst.display} ${alert.isAbove ? "↑ Above" : "↓ Below"} '
          '\$${alert.targetPrice.toStringAsFixed(inst.decimals)}',
          style: TextStyle(
            color: alert.triggered ? Colors.white38 : Colors.white,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          alert.triggered
              ? 'Triggered ✓'
              : diff != null
                  ? '\$${diff.toStringAsFixed(inst.decimals)} away from target'
                  : 'Set ${_timeAgo(alert.createdAt)}',
          style: TextStyle(
            color: alert.triggered ? Colors.white24 : Colors.white54,
            fontSize: 11,
          ),
        ),
        trailing: alert.triggered
            ? IconButton(
                icon:
                    const Icon(Icons.delete_outline, color: Colors.white24),
                onPressed: () => _deleteAlert(alert.id),
              )
            : IconButton(
                icon: const Icon(Icons.close, color: Colors.white38),
                onPressed: () => _deleteAlert(alert.id),
              ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
