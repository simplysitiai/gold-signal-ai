import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';

/// A dropdown widget that lets the user switch between all available
/// trading instruments (XAUUSD, EURUSD, BTCUSD, etc.).
///
/// The currently active symbol is passed in via [selectedSymbol] so it
/// always reflects the parent's shared state — no stale storage reads.
class SymbolSelector extends StatelessWidget {
  /// The currently selected symbol (e.g. "XAUUSD"). Drives the highlight.
  final String selectedSymbol;

  /// Called whenever the user picks a different symbol.
  final void Function(String symbol)? onSymbolChanged;

  /// Compact mode — shows just the short display code (e.g. "XAUUSD").
  final bool compact;

  const SymbolSelector({
    super.key,
    required this.selectedSymbol,
    this.onSymbolChanged,
    this.compact = false,
  });

  Future<void> _changeSymbol(String symbol) async {
    onSymbolChanged?.call(symbol);
  }

  @override
  Widget build(BuildContext context) {
    // Group instruments by category for the dropdown
    final categories = <String, List<TradingInstrument>>{};
    for (final inst in AppConstants.availableSymbols) {
      categories.putIfAbsent(inst.category, () => []).add(inst);
    }

    final selected = AppConstants.availableSymbols.firstWhere(
      (i) => i.symbol == selectedSymbol,
      orElse: () => AppConstants.availableSymbols.first,
    );

    return PopupMenuButton<String>(
      onSelected: _changeSymbol,
      color: AppTheme.surface,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
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
            Icon(Icons.expand_more, color: AppTheme.gold, size: compact ? 16 : 18),
            const SizedBox(width: 4),
            Text(
              selected.display,
              style: TextStyle(
                color: AppTheme.gold,
                fontSize: compact ? 12 : 14,
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
            final isSelected = inst.symbol == selectedSymbol;
            items.add(PopupMenuItem<String>(
              value: inst.symbol,
              child: Row(
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.check, color: AppTheme.gold, size: 14),
                    ),
                  Text(
                    inst.display,
                    style: TextStyle(
                      color: isSelected ? AppTheme.gold : Colors.white,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
          items.add(const PopupMenuDivider());
        }
        if (items.isNotEmpty && items.last is PopupMenuDivider) {
          items.removeLast();
        }
        return items;
      },
    );
  }
}
