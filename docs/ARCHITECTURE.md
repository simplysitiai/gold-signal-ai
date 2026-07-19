# Signal Pro — Architecture

## Project Structure
```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase config
├── models/
│   ├── candle.dart              # OHLCV candle model
│   ├── indicator_data.dart      # All indicator values container
│   ├── signal.dart              # TradingSignal + PriceAlert models
│   └── (constants.dart)         # TradingInstrument model
├── services/
│   ├── api_service.dart         # Unified API (Twelve Data + Alpha Vantage)
│   ├── indicator_service.dart   # Local indicator calculations
│   ├── signal_engine.dart       # Weighted voting signal engine
│   └── storage_service.dart    # SharedPreferences wrapper
├── screens/
│   ├── home_screen.dart         # Dashboard with price + quick signal
│   ├── chart_screen.dart        # Candlestick chart with timeframes
│   ├── signal_screen.dart       # Full signal + indicator breakdown
│   ├── alerts_screen.dart       # Price alert management
│   └── settings_screen.dart     # API keys, provider, refresh, premium
├── utils/
│   ├── constants.dart           # App constants + instrument list
│   └── theme.dart               # Colors + theme
└── widgets/
    ├── price_card.dart          # Live price display
    ├── signal_card.dart         # Signal result card
    ├── indicator_card.dart      # Individual indicator display
    ├── candlestick_chart.dart   # Custom chart painter
    └── symbol_selector.dart     # Instrument dropdown
```

## Data Flow
1. User selects instrument → stored in SharedPreferences
2. ApiService fetches data from active provider (TD or AV)
3. IndicatorService computes indicators locally
4. SignalEngine aggregates into BUY/SELL/WAIT
5. UI displays results with appropriate formatting

## Signal Engine Weights
| Indicator | Weight | Bullish Condition |
|-----------|--------|-------------------|
| EMA 20/50 | 25 | EMA20 > EMA50 |
| RSI 14 | 20 | RSI < 30 (oversold) |
| MACD 12/26/9 | 25 | MACD > Signal + histogram > 0 |
| Bollinger 20/2 | 15 | Price near lower band |
| Support/Resistance | 15 | Price near support |
