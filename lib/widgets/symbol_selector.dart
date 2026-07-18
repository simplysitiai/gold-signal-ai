import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../services/storage_service.dart';

/// A dropdown widget that lets the user switch between all available
/// trading instruments (XAUUSD, EURUSD, BTCUSD, etc.).
///
/// Persists the selection to SharedPreferences so all screens share the
/// same active symbol.
class SymbolSelector extends StatefulWidget {
  /// Called whenever the user picks a different symbol.
  final void Function(String symbol)? onSymbolChanged;

  /// Compact mode — shows just the short display code (e.g. "XAUUSD").
  final bool compact;

  const SymbolSelector({
    super.key,
    this.onSymbolChanged,
    this.compact = false,
  });

  @override
  State<SymbolSelector> createState() => _SymbolSelectorState();
}

class _SymbolSelectorState extends State<SymbolSelector> {
  final StorageService _storage = StorageService();
  String _selectedSymbol = AppConstants.defaultSymbol;

  @override
  void initState() {
    super.initState();
    _loadSymbol();
  }

  Future<void> _loadSymbol() async {
    final sym = await _storage.getSelectedSymbol();
    setState(() => _selectedSymbol = sym);
  }

  Future<void> _changeSymbol(String symbol) async {
    await _storage.setSelectedSymbol(symbol);
    setState(() => _selectedSymbol = symbol);
    widget.onSymbolChanged?.call(symbol);
  }

  @override
  Widget build(BuildContext context) {
    // Group instruments by category for the dropdown
    final categories = <String, List<TradingInstrument>>{};
    for (final inst in AppConstants.availableSymbols) {
      categories.putIfAbsent(inst.category, () => []).add(inst);
    }

    final selected = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == _selectedSymbol,
      orElse: () => AppConstants.availableSymbols.first,
    );

    return PopupMenuButton<String>(
      onSelected: _changeSymbol,
      color: AppTheme.surface,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.compact ? 8 : 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppTheme.gold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.expand_more,
              color: AppTheme.gold,
              size: widget.compact ? 16 : 18,
            ),
            const SizedBox(width: 4),
            Text(
              widget.compact ? selected.display : '${selected.display}',
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: widget.compact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];
        for (final entry in categories.entries) {
          // Category header
          items.add(PopupMenuItem<String>(
            enabled: false,
            child: Text(
              entry.key.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.gold,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ));
          // Instruments in this category
          for (final inst in entry.value) {
            items.add(PopupMenuItem<String>(
              value: inst.symbol,
              child: Row(
                children: [
                  Text(
                    inst.display,
                    style: TextStyle(
                      color: inst.symbol == _selectedSymbol
                          ? AppTheme.gold
                          : Colors.white,
                      fontWeight: inst.symbol == _selectedSymbol
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    inst.name,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ));
          }
          // Divider between categories
          items.add(const PopupMenuDivider());
        }
        // Remove the last divider
        if (items.isNotEmpty && items.last is PopupMenuDivider) {
          items.removeLast();
        }
        return items;
      },
    );
  }
}
