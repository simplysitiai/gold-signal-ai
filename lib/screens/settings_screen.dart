import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// Settings screen — manage API key, premium status, and app info.
///
/// Users can:
/// - Enter their own Twelve Data API key (stored locally on device)
/// - View/clear the default API key
/// - Toggle premium status (removes ads — demo only)
/// - View app info and disclaimer
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  final _apiKeyController = TextEditingController();

  bool _isPremium = false;
  bool _isValidating = false;
  bool? _apiKeyValid;
  String _currentApiKey = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _currentApiKey = await _storage.getApiKey();
    _isPremium = await _storage.isPremium();

    // Show masked version of current key
    if (_currentApiKey.isNotEmpty) {
      _apiKeyController.text = _currentApiKey;
    }

    setState(() {});
  }

  Future<void> _saveApiKey() async {
    final key = _apiKeyController.text.trim();
    if (key.isEmpty) return;

    setState(() => _isValidating = true);

    // Validate the API key
    final isValid = await _api.validateApiKey(key);

    if (isValid) {
      await _storage.setApiKey(key);
      setState(() {
        _currentApiKey = key;
        _apiKeyValid = true;
        _isValidating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API key saved and validated!'),
          backgroundColor: AppTheme.green,
        ),
      );
    } else {
      setState(() {
        _apiKeyValid = false;
        _isValidating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid API key. Please check and try again.'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  Future<void> _clearApiKey() async {
    await _storage.clearApiKey();
    _apiKeyController.clear();
    setState(() {
      _currentApiKey = '';
      _apiKeyValid = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Using default API key'),
        backgroundColor: AppTheme.gold,
      ),
    );
  }

  Future<void> _togglePremium(bool value) async {
    await _storage.setPremium(value);
    setState(() => _isPremium = value);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
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
          // === API Key Section ===
          _buildSectionHeader('MARKET DATA'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vpn_key, color: AppTheme.gold, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Twelve Data API Key',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Enter your own API key for higher limits.\nFree key at twelvedata.com/pricing',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Enter your API key',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: AppTheme.blackLight,
                      suffixIcon: _apiKeyValid == true
                          ? const Icon(Icons.check_circle, color: AppTheme.green)
                          : _apiKeyValid == false
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
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isValidating ? null : _saveApiKey,
                          icon: _isValidating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.black),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: Text(_isValidating ? 'Validating...' : 'Save & Validate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.gold,
                            foregroundColor: AppTheme.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _clearApiKey,
                        child: const Text('Use Default', style: TextStyle(color: Colors.white54)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_currentApiKey.isNotEmpty && _currentApiKey != AppConstants.defaultApiKey)
                          ? AppTheme.green.withOpacity(0.1)
                          : AppTheme.goldDark.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      (_currentApiKey.isNotEmpty && _currentApiKey != AppConstants.defaultApiKey)
                          ? 'Using custom API key'
                          : 'Using default (shared) API key — limited requests',
                      style: TextStyle(
                        color: (_currentApiKey.isNotEmpty && _currentApiKey != AppConstants.defaultApiKey)
                            ? AppTheme.green
                            : AppTheme.gold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // === Premium Section ===
          _buildSectionHeader('SUBSCRIPTION'),
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
          const SizedBox(height: 8),
          if (_isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.gold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: AppTheme.gold, size: 16),
                  SizedBox(width: 8),
                  Text('Premium active — ads removed', style: TextStyle(color: AppTheme.gold, fontSize: 12)),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // === About Section ===
          _buildSectionHeader('ABOUT'),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                _buildAboutTile('App Name', AppConstants.appName),
                _buildAboutTile('Version', AppConstants.appVersion),
                _buildAboutTile('Symbol', AppConstants.symbolDisplay),
                _buildAboutTile('Data Provider', 'Twelve Data'),
                _buildAboutTile('Framework', 'Flutter'),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // === Disclaimer ===
          _buildSectionHeader('DISCLAIMER'),
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
                Text(
                  appDisclaimer,
                  style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildAboutTile(String label, String value) {
    return ListTile(
      dense: true,
      title: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
      trailing: Text(value, style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}
