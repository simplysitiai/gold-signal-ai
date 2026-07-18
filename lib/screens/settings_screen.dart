import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Settings screen — API keys, provider selection, refresh interval, premium.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  final _tdKeyController = TextEditingController();
  final _avKeyController = TextEditingController();

  bool _isPremium = false;
  bool _isValidating = false;
  bool? _tdKeyValid;
  bool? _avKeyValid;
  String _currentTdKey = '';
  String _currentAvKey = '';
  String _apiProvider = AppConstants.apiProviderTwelveData;
  int _refreshInterval = AppConstants.defaultRefreshInterval;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currentTdKey = await _storage.getApiKey();
    _currentAvKey = await _storage.getAlphaVantageKey();
    _isPremium = await _storage.isPremium();
    _apiProvider = await _storage.getApiProvider();
    _refreshInterval = await _storage.getRefreshInterval();

    _tdKeyController.text = _currentTdKey == AppConstants.twelveDataDefaultKey ? '' : _currentTdKey;
    _avKeyController.text = _currentAvKey == AppConstants.alphaVantageDefaultKey ? '' : _currentAvKey;
    setState(() {});
  }

  Future<void> _saveTdKey() async {
    final key = _tdKeyController.text.trim();
    if (key.isEmpty) return;
    setState(() => _isValidating = true);
    final isValid = await _api.validateApiKey(key);
    if (isValid) {
      await _storage.setApiKey(key);
      setState(() { _currentTdKey = key; _tdKeyValid = true; _isValidating = false; });
      _snack('Twelve Data key saved!', AppTheme.green);
    } else {
      setState(() { _tdKeyValid = false; _isValidating = false; });
      _snack('Invalid Twelve Data key.', AppTheme.red);
    }
  }

  Future<void> _saveAvKey() async {
    final key = _avKeyController.text.trim();
    if (key.isEmpty) return;
    setState(() => _isValidating = true);
    final isValid = await _api.validateApiKey(key, isAlphaVantage: true);
    if (isValid) {
      await _storage.setAlphaVantageKey(key);
      setState(() { _currentAvKey = key; _avKeyValid = true; _isValidating = false; });
      _snack('Alpha Vantage key saved!', AppTheme.green);
    } else {
      setState(() { _avKeyValid = false; _isValidating = false; });
      _snack('Invalid Alpha Vantage key.', AppTheme.red);
    }
  }

  Future<void> _setProvider(String provider) async {
    await _storage.setApiProvider(provider);
    setState(() => _apiProvider = provider);
    _snack('Data provider set to ${provider == AppConstants.apiProviderTwelveData ? "Twelve Data" : "Alpha Vantage"}', AppTheme.gold);
  }

  Future<void> _setRefreshInterval(int minutes) async {
    await _storage.setRefreshInterval(minutes);
    setState(() => _refreshInterval = minutes);
    final label = AppConstants.refreshIntervalLabels[AppConstants.refreshIntervals.indexOf(minutes)];
    _snack('Auto-refresh: $label', AppTheme.gold);
  }

  Future<void> _togglePremium(bool value) async {
    await _storage.setPremium(value);
    setState(() => _isPremium = value);
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  void dispose() {
    _tdKeyController.dispose();
    _avKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── Data Provider ──────────────────────────────────────────────────
          _sectionHeader('DATA PROVIDER'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select API provider for market data:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  _providerTile(
                    title: 'Twelve Data',
                    subtitle: 'Forex, commodities, crypto, stocks\nFree: 800 req/day',
                    value: AppConstants.apiProviderTwelveData,
                    icon: Icons.data_usage,
                  ),
                  const SizedBox(height: 8),
                  _providerTile(
                    title: 'Alpha Vantage',
                    subtitle: 'Forex, crypto, stocks\nFree: 25 req/day',
                    value: AppConstants.apiProviderAlphaVantage,
                    icon: Icons.bar_chart,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Twelve Data API Key ────────────────────────────────────────────
          _sectionHeader('TWELVE DATA API KEY'),
          const SizedBox(height: 8),
          _apiKeyCard(
            controller: _tdKeyController,
            hint: 'Paste your Twelve Data key',
            isValid: _tdKeyValid,
            isValidating: _isValidating,
            onSave: _saveTdKey,
            onClear: () async {
              await _storage.clearApiKey();
              _tdKeyController.clear();
              setState(() { _currentTdKey = AppConstants.twelveDataDefaultKey; _tdKeyValid = null; });
              _snack('Using default Twelve Data key', AppTheme.gold);
            },
            usingDefault: _currentTdKey == AppConstants.twelveDataDefaultKey,
            getKeyUrl: 'twelvedata.com/pricing',
          ),
          const SizedBox(height: 24),

          // ── Alpha Vantage API Key ──────────────────────────────────────────
          _sectionHeader('ALPHA VANTAGE API KEY'),
          const SizedBox(height: 8),
          _apiKeyCard(
            controller: _avKeyController,
            hint: 'Paste your Alpha Vantage key',
            isValid: _avKeyValid,
            isValidating: _isValidating,
            onSave: _saveAvKey,
            onClear: () async {
              await _storage.setAlphaVantageKey(AppConstants.alphaVantageDefaultKey);
              _avKeyController.clear();
              setState(() { _currentAvKey = AppConstants.alphaVantageDefaultKey; _avKeyValid = null; });
              _snack('Using demo key (very limited)', AppTheme.gold);
            },
            usingDefault: _currentAvKey == AppConstants.alphaVantageDefaultKey,
            getKeyUrl: 'alphavantage.co/support/#api-key',
          ),
          const SizedBox(height: 24),

          // ── Auto Refresh ───────────────────────────────────────────────────
          _sectionHeader('AUTO REFRESH'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.goldDark.withOpacity(0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('How often to pull new data automatically:',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(AppConstants.refreshIntervals.length, (i) {
                      final val = AppConstants.refreshIntervals[i];
                      final label = AppConstants.refreshIntervalLabels[i];
                      final selected = val == _refreshInterval;
                      return GestureDetector(
                        onTap: () => _setRefreshInterval(val),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.gold : AppTheme.blackLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: selected ? AppTheme.gold : AppTheme.goldDark.withOpacity(0.3)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? AppTheme.black : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  if (_refreshInterval > 0) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white38, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Data refreshes every $_refreshInterval minute${_refreshInterval > 1 ? "s" : ""}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Premium ────────────────────────────────────────────────────────
          _sectionHeader('SUBSCRIPTION'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: _isPremium ? AppTheme.gold : Colors.white10),
            ),
            child: SwitchListTile(
              title: Row(
                children: [
                  Icon(Icons.workspace_premium, color: _isPremium ? AppTheme.gold : Colors.white38, size: 20),
                  const SizedBox(width: 8),
                  const Text('Premium', style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
              subtitle: const Text('Remove ads and unlock all features', style: TextStyle(color: Colors.white38, fontSize: 12)),
              value: _isPremium,
              activeColor: AppTheme.gold,
              onChanged: _togglePremium,
            ),
          ),
          const SizedBox(height: 24),

          // ── About ──────────────────────────────────────────────────────────
          _sectionHeader('ABOUT'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _aboutTile('App Name', AppConstants.appName),
                _aboutTile('Version', AppConstants.appVersion),
                _aboutTile('Provider', _apiProvider == AppConstants.apiProviderTwelveData ? 'Twelve Data' : 'Alpha Vantage'),
                _aboutTile('Framework', 'Flutter'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Disclaimer ─────────────────────────────────────────────────────
          _sectionHeader('DISCLAIMER'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.red.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.red.withOpacity(0.15)),
            ),
            child: Column(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppTheme.red, size: 24),
                const SizedBox(height: 8),
                Text(appDisclaimer,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _providerTile({required String title, required String subtitle, required String value, required IconData icon}) {
    final selected = _apiProvider == value;
    return GestureDetector(
      onTap: () => _setProvider(value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppTheme.gold.withOpacity(0.1) : AppTheme.blackLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.gold : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppTheme.gold : Colors.white38, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: selected ? AppTheme.gold : Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: AppTheme.gold, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _apiKeyCard({
    required TextEditingController controller,
    required String hint,
    required bool? isValid,
    required bool isValidating,
    required VoidCallback onSave,
    required VoidCallback onClear,
    required bool usingDefault,
    required String getKeyUrl,
  }) {
    return Card(
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
            Text('Get a free key at $getKeyUrl', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: AppTheme.blackLight,
                suffixIcon: isValid == true
                    ? const Icon(Icons.check_circle, color: AppTheme.green)
                    : isValid == false
                        ? const Icon(Icons.cancel, color: AppTheme.red)
                        : null,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isValidating ? null : onSave,
                    icon: isValidating
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black))
                        : const Icon(Icons.save, size: 16),
                    label: Text(isValidating ? 'Validating...' : 'Save & Validate'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: AppTheme.black),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onClear,
                  child: const Text('Reset', style: TextStyle(color: Colors.white54)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              usingDefault ? 'Using default key (limited)' : 'Using custom key',
              style: TextStyle(color: usingDefault ? AppTheme.gold : AppTheme.green, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5));
  }

  Widget _aboutTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}
