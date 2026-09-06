# Water Quality Monitor (Flutter + ESP32)

A Flutter dashboard app that displays live **pH**, **TDS**, **Temperature**,
and **Turbidity** readings pulled from an **ESP32** over Wi-Fi.

## Project structure

```
water_monitor_app/
├── lib/
│   ├── main.dart                     # App entry point
│   ├── models/sensor_data.dart       # Sensor data model + JSON parsing
│   ├── services/esp32_service.dart   # HTTP calls to the ESP32
│   ├── services/water_quality_rules.dart  # Status thresholds (Good/Moderate/High etc.)
│   ├── screens/dashboard_screen.dart # Main UI, polling loop, settings dialog
│   └── widgets/sensor_card.dart      # Reusable card widget for each reading
├── esp32_example/
│   └── esp32_water_monitor.ino       # Example ESP32 sketch (Arduino IDE)
├── pubspec.yaml
└── README.md
```

## 1. How data flows (ESP32 → App)

1. The ESP32 reads its 4 sensors (pH, TDS, temperature, turbidity probes).
2. It runs a tiny built-in web server and exposes the latest readings as
   JSON at an endpoint, e.g. `http://<ESP32_IP>/data`:
   ```json
   { "ph": 7.12, "tds": 342.5, "temperature": 26.4, "turbidity": 3.8 }
   ```
3. The Flutter app calls that URL with a normal HTTP GET request every
   **3 seconds** (see `pollInterval` in `dashboard_screen.dart`) and
   updates the dashboard with the new values.
4. Both devices must be on the **same Wi-Fi network** (or the ESP32 can
   run its own Wi-Fi hotspot / Access Point and the phone connects to it).

No cloud server, MQTT broker, or database is required for this basic
setup — it's a direct phone ⇄ ESP32 HTTP connection on the local network.

## 2. Setting up the ESP32

1. Open `esp32_example/esp32_water_monitor.ino` in the Arduino IDE.
2. Install the **ArduinoJson** library (Tools → Manage Libraries).
3. Wire up your sensors:
   - pH sensor → analog pin (e.g. GPIO34)
   - TDS sensor → analog pin (e.g. GPIO35)
   - Turbidity sensor → analog pin (e.g. GPIO32)
   - Temperature sensor (e.g. DS18B20 or analog) → GPIO33
4. Replace the placeholder formulas in `readPH()`, `readTDS()`,
   `readTemperature()`, `readTurbidity()` with your sensor's real
   calibration curve (each sensor module's datasheet gives you this).
5. Enter your Wi-Fi `ssid` and `password` at the top of the sketch.
6. Upload the sketch to the ESP32. Open the Serial Monitor at 115200 baud —
   once connected, it prints something like:
   ```
   Connected! ESP32 IP address: 192.168.1.47
   ```
   **Note this IP address down.**
7. Test it directly first: open that IP + `/data` in a browser
   (e.g. `http://192.168.1.47/data`) — you should see the raw JSON.

## 3. Setting up the Flutter app

1. Extract this zip, then from the project root run:
   ```
   flutter pub get
   ```
2. Run the app on your phone/emulator (must be on the same Wi-Fi as the
   ESP32):
   ```
   flutter run
   ```
3. On first launch it tries the default IP (`192.168.4.1`). Tap the
   **Wi-Fi/settings icon** in the top app bar and enter:
   - **ESP32 IP address** — the one printed in the Serial Monitor
     (e.g. `192.168.1.47`)
   - **Endpoint** — `/data` (already the default)
4. Tap **Save**. The app immediately fetches data and then keeps polling
   every 3 seconds automatically.

## 4. Where the data shows up in the app

- **Dashboard screen** (`lib/screens/dashboard_screen.dart`) — the home
  screen of the app:
  - A **status banner** at the top shows "Connected to ESP32 (IP)" in
    green, or a red error banner if the ESP32 can't be reached.
  - Below it, a **2x2 grid of cards** (`SensorCard` widget) shows the
    four live readings:
    - pH Level (with Acidic / Normal / Alkaline tag)
    - TDS in ppm (Good / Moderate / High tag)
    - Temperature in °C (Low / Normal / High tag)
    - Turbidity in NTU (Clear / Slight / Turbid tag)
  - Each card's colored tag is computed in
    `lib/services/water_quality_rules.dart` — adjust the numeric
    thresholds there to match the water-quality standard you want
    (e.g. WHO or BIS 10500 drinking water limits).
  - A **"Last updated" timestamp** at the bottom shows when the most
    recent reading arrived.
  - **Pull down to refresh** manually at any time.

## 5. Customizing

- **Polling speed**: change `pollInterval` in `dashboard_screen.dart`.
- **Thresholds/status labels**: edit `water_quality_rules.dart`.
- **JSON field names**: if your ESP32 sends different keys, update
  `SensorData.fromJson()` in `models/sensor_data.dart` to match.
- **Charts/history**: `fl_chart` is already included in `pubspec.yaml`
  if you want to add a trend graph later (not wired up yet — this
  version focuses on live current readings).

## 6. Troubleshooting

- **"Could not reach ESP32"**: confirm the phone and ESP32 are on the
  same network, the IP hasn't changed (routers can reassign IPs — 
  consider setting a static IP on the ESP32), and that
  `http://<ip>/data` opens correctly in a mobile browser.
- **CORS-related errors on web builds**: the example sketch already
  sends `Access-Control-Allow-Origin: *`, but if you customize the
  sketch, keep that header for the app to work when run via
  `flutter run -d chrome`.
