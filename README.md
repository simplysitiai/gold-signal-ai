# 🥇 Gold Signal AI

A modern Android app for **XAUUSD (Gold/USD) technical analysis** built with Flutter.  
It analyzes market data and generates educational BUY / SELL / WAIT signals using common technical indicators.

> ⚠️ **Disclaimer:** This application is for educational and informational purposes only. It does not provide financial advice or guarantee trading results. Users are responsible for their own trading decisions.

---

## ✨ Features

| Feature | Description |
|---|---|
| **Real-time Price** | Current XAUUSD price, daily high/low/open, daily change %, spread |
| **Candlestick Chart** | Interactive candlestick chart with 7 timeframes (1m – 1D) |
| **Technical Indicators** | EMA 20, EMA 50, RSI (14), MACD, Bollinger Bands, ATR, Support & Resistance |
| **Signal Engine** | Weighted multi-indicator voting system → BUY / SELL / WAIT with confidence score |
| **Price Alerts** | Set target prices and receive notifications when reached |
| **Watchlist** | XAUUSD only — focused on gold trading |
| **Dark Theme** | Gold and black color scheme, Material Design 3 |
| **AdMob** | Banner ads + rewarded ads for additional analysis |
| **Premium** | Optional subscription to remove ads |
| **Custom API Key** | Users can input their own Twelve Data API key, stored locally on-device |

---

## 📱 Screens

1. **Home** — Current price, daily stats, quick signal overview
2. **Chart** — Candlestick chart with timeframe selector, EMA overlays
3. **Signals** — Full signal breakdown with confidence score and all indicator values
4. **Alerts** — Create and manage price alerts
5. **Settings** — API key management, premium toggle, about

---

## 🛠️ Technology Stack

| Component | Technology |
|---|---|
| Framework | Flutter 3.22+ |
| Language | Dart 3.0+ |
| State Management | Provider |
| Charts | fl_chart |
| Backend | Firebase (optional) |
| Market Data | Twelve Data API |
| Ads | Google AdMob |
| Notifications | flutter_local_notifications |
| Local Storage | SharedPreferences |

---

## 📦 Installation

### Prerequisites
- Flutter SDK 3.22+ ([Install Flutter](https://flutter.dev/docs/get-started/install))
- Java JDK 17
- Android SDK (API 34)
- An Android device or emulator (Android 6.0+ / API 23)

### Build from Source
```bash
# Clone the repository
git clone https://github.com/simplysitiai/gold-signal-ai.git
cd gold-signal-ai

# Install dependencies
flutter pub get

# Run on a connected device
flutter run

# Build a debug APK
flutter build apk --debug

# Build a release APK (requires signing configuration)
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-debug.apk`.

### Install the APK
1. Download the APK file
2. On your Android device: Settings → Security → Enable "Install from unknown sources"
3. Open the APK file and tap "Install"

---

## 🔑 API Key Setup

The app comes with a default Twelve Data API key (free tier: 800 requests/day).  
You can use your own key for higher limits:

1. Get a free API key at [twelvedata.com](https://twelvedata.com/pricing)
2. Open the app → Settings → API Key
3. Enter your key and tap "Validate"
4. Your key is stored locally on your device (never sent anywhere except Twelve Data)

---

## 🔥 Firebase Setup (Optional)

Firebase is optional — the app works without it. To enable:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name: `com.goldsignal.ai`
3. Download `google-services.json` and place it in `android/app/`
4. Uncomment the Google Services plugin in `android/build.gradle`:
   ```gradle
   // In android/build.gradle, add to dependencies:
   classpath 'com.google.gms:google-services:4.4.0'
   ```
5. In `android/app/build.gradle`, add at the bottom:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```
6. Run `flutterfire configure` to generate `lib/firebase_options.dart`
7. Uncomment the Firebase initialization in `lib/main.dart`

---

## 📢 AdMob Setup

The app uses Google's test ad unit IDs by default. To use real ads:

1. Create an AdMob account at [apps.admob.com](https://apps.admob.com)
2. Create an Android app and get your App ID
3. Update `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <meta-data
       android:name="com.google.android.gms.ads.APPLICATION_ID"
       android:value="ca-app-pub-YOUR_APP_ID" />
   ```
4. Update `lib/utils/constants.dart`:
   ```dart
   static const String bannerAdUnitId = 'ca-app-pub-XXXX/banner_unit_id';
   static const String rewardedAdUnitId = 'ca-app-pub-XXXX/rewarded_unit_id';
   ```

---

## 📁 Project Structure

```
gold_signal_ai/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── models/
│   │   ├── candle.dart              # OHLCV candle data model
│   │   ├── signal.dart              # Trading signal & price alert models
│   │   └── indicator_data.dart      # Technical indicator data container
│   ├── services/
│   │   ├── api_service.dart         # Twelve Data API client
│   │   ├── indicator_service.dart   # Technical indicator calculations
│   │   ├── signal_engine.dart       # Signal generation engine
│   │   └── storage_service.dart     # Local persistence (SharedPreferences)
│   ├── screens/
│   │   ├── home_screen.dart         # Price dashboard
│   │   ├── chart_screen.dart        # Candlestick chart
│   │   ├── signal_screen.dart       # Signal & indicator details
│   │   ├── alerts_screen.dart       # Price alerts
│   │   └── settings_screen.dart     # Settings & API key
│   ├── widgets/
│   │   ├── candlestick_chart.dart    # Custom candlestick chart
│   │   ├── price_card.dart          # Price display card
│   │   ├── signal_card.dart         # Signal display card
│   │   └── indicator_card.dart      # Reusable indicator value card
│   └── utils/
│       ├── constants.dart           # App constants & API endpoints
│       └── theme.dart               # Dark gold/black Material 3 theme
├── android/                         # Android-specific configuration
├── .github/workflows/build-apk.yml  # CI/CD: automatic APK building
├── pubspec.yaml                     # Flutter dependencies
└── README.md                        # This file
```

---

## 🔄 GitHub Actions — Automatic APK Building

The repository includes a GitHub Actions workflow (`.github/workflows/build-apk.yml`) that:

1. **Triggers** on push to `main`/`master`, on new version tags (`v*`), and manually
2. **Builds** a debug APK using Flutter on Ubuntu
3. **Uploads** the APK as a downloadable artifact (30-day retention)
4. **Creates a release** with the APK when a version tag is pushed

### Downloading the APK
1. Go to the repository on GitHub → **Actions** tab
2. Click the latest successful run
3. Scroll to **Artifacts** → download `gold-signal-ai-apk`

### Creating a Release
```bash
git tag v1.0.0
git push origin v1.0.0
```
This triggers the workflow and creates a GitHub Release with the APK attached.

---

## 📊 Signal Engine

The signal engine uses a **weighted multi-indicator voting system**:

| Indicator | Weight | Bullish Condition | Bearish Condition |
|---|---|---|---|
| EMA 20/50 Cross | 25 | EMA20 > EMA50 | EMA20 < EMA50 |
| RSI (14) | 20 | RSI < 30 (oversold) | RSI > 70 (overbought) |
| MACD | 25 | MACD > Signal & Histogram > 0 | MACD < Signal & Histogram < 0 |
| Bollinger Bands | 15 | %B < 0.2 (near lower band) | %B > 0.8 (near upper band) |
| Support/Resistance | 15 | Near support | Near resistance |

- Net score > 15 → **BUY**
- Net score < -15 → **SELL**
- Otherwise → **WAIT**
- Confidence = |net score| / total weight × 100

---

## 📝 License

This project is provided as-is for educational purposes.  
Market data provided by [Twelve Data](https://twelvedata.com).

---

## ⚠️ Disclaimer

This application is for educational and informational purposes only. It does not provide financial advice or guarantee trading results. Users are responsible for their own trading decisions.
