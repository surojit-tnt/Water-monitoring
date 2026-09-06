/*
  ESP32 Water Quality Monitor - Example Sketch
  ---------------------------------------------
  Reads pH, TDS, Temperature, and Turbidity sensors and serves the
  latest values as JSON over Wi-Fi, so the Flutter app can fetch them
  with a simple HTTP GET request.

  Replace the analog-read / calculation sections with your actual
  sensor wiring and calibration formulas. The pin numbers and formulas
  below are placeholders — calibrate them for your specific sensors
  (e.g. Gravity Analog pH Sensor, Gravity TDS Sensor, DS18B20,
  Gravity Turbidity Sensor).

  Required Library: ArduinoJson (install via Library Manager)
  Board: ESP32 Dev Module
*/

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ---------- Wi-Fi credentials ----------
const char* ssid     = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// ---------- Sensor pins (adjust to your wiring) ----------
const int PH_PIN        = 34; // Analog pin for pH sensor
const int TDS_PIN       = 35; // Analog pin for TDS sensor
const int TURBIDITY_PIN = 32; // Analog pin for turbidity sensor
const int TEMP_PIN      = 33; // Analog/OneWire pin for temperature sensor

WebServer server(80);

float readPH() {
  int raw = analogRead(PH_PIN);
  float voltage = raw * (3.3 / 4095.0);
  // Example linear calibration — replace with your sensor's formula
  float ph = 7 + ((2.5 - voltage) / 0.18);
  return ph;
}

float readTDS() {
  int raw = analogRead(TDS_PIN);
  float voltage = raw * (3.3 / 4095.0);
  // Example TDS formula — replace with your sensor's calibration
  float tds = (133.42 * voltage * voltage * voltage
               - 255.86 * voltage * voltage
               + 857.39 * voltage) * 0.5;
  return tds;
}

float readTemperature() {
  int raw = analogRead(TEMP_PIN);
  float voltage = raw * (3.3 / 4095.0);
  // Placeholder formula — use a DS18B20 (OneWire) library for real accuracy
  float tempC = voltage * 100.0;
  return tempC;
}

float readTurbidity() {
  int raw = analogRead(TURBIDITY_PIN);
  float voltage = raw * (3.3 / 4095.0);
  // Example: higher voltage roughly maps to clearer water for many
  // turbidity sensor modules — calibrate against known NTU samples
  float ntu = (voltage < 2.5) ? 3000 : (-1120.4 * voltage * voltage
              + 5742.3 * voltage - 4352.9);
  if (ntu < 0) ntu = 0;
  return ntu;
}

void handleData() {
  StaticJsonDocument<200> doc;
  doc["ph"] = readPH();
  doc["tds"] = readTDS();
  doc["temperature"] = readTemperature();
  doc["turbidity"] = readTurbidity();

  String json;
  serializeJson(doc, json);

  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  Serial.print("Connecting to Wi-Fi");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println();
  Serial.print("Connected! ESP32 IP address: ");
  Serial.println(WiFi.localIP()); // <-- Use this IP in the Flutter app

  server.on("/data", handleData);
  server.begin();
  Serial.println("HTTP server started on /data");
}

void loop() {
  server.handleClient();
}
