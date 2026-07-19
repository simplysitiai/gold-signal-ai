# Signal Pro — Complete Documentation

## Overview
Signal Pro is a Flutter-based mobile trading signal application that provides real-time technical analysis across multiple financial instruments including Gold, Silver, Forex majors, and Cryptocurrencies.

## Features
- Multi-instrument support (15+ trading pairs)
- Dual API providers (Twelve Data + Alpha Vantage)
- AI signal engine with weighted indicator voting
- Real-time candlestick charts with EMA overlays
- Price alerts with local notifications
- Configurable auto-refresh intervals
- Per-symbol decimal precision
- AdMob integration (banner + rewarded ads)

## Architecture
- **Models:** Candle, IndicatorData, TradingSignal, PriceAlert, TradingInstrument
- **Services:** ApiService (Twelve Data + Alpha Vantage), IndicatorService, SignalEngine, StorageService
- **Screens:** Home, Chart, Signal, Alerts, Settings
- **Widgets:** PriceCard, SignalCard, IndicatorCard, CandlestickChart, SymbolSelector

## Setup
1. Clone the repo
2. Run `flutter pub get`
3. Configure API keys in Settings or use default
4. Build with `flutter build apk` or use GitHub Actions

## API Keys
- Twelve Data: Free at https://twelvedata.com/pricing (800 req/day)
- Alpha Vantage: Free at https://www.alphavantage.co/support/#api-key (25 req/day)

## Signal Engine
Uses weighted voting across 5 indicators:
- EMA 20/50 crossover (weight: 25)
- RSI 14 (weight: 20)
- MACD 12/26/9 (weight: 25)
- Bollinger Bands 20/2 (weight: 15)
- Support/Resistance (weight: 15)

Score > +15 = BUY, < -15 = SELL, otherwise WAIT
