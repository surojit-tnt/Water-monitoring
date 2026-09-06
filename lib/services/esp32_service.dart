import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sensor_data.dart';

/// Handles all communication with the ESP32 device.
///
/// The ESP32 is expected to run a small HTTP web server (e.g. using
/// WebServer.h / ESPAsyncWebServer) that responds to GET requests on
/// an endpoint (default "/data") with a JSON body like:
///
///   {"ph":7.12,"tds":342.5,"temperature":26.4,"turbidity":3.8}
///
/// The app polls this endpoint on a timer (see DashboardScreen).
class Esp32Service {
  static const String _prefKeyIp = 'esp32_ip';
  static const String _prefKeyEndpoint = 'esp32_endpoint';

  /// Default values — change these to match your ESP32 sketch,
  /// or update them at runtime from the in-app Settings screen.
  static const String defaultIp = '192.168.4.1'; // ESP32 default AP IP
  static const String defaultEndpoint = '/data';

  Future<String> getIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyIp) ?? defaultIp;
  }

  Future<String> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKeyEndpoint) ?? defaultEndpoint;
  }

  Future<void> saveConnectionSettings({
    required String ip,
    required String endpoint,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyIp, ip.trim());
    await prefs.setString(_prefKeyEndpoint, endpoint.trim());
  }

  /// Builds the full URL, e.g. http://192.168.4.1/data
  Future<Uri> _buildUri() async {
    final ip = await getIp();
    final endpoint = await getEndpoint();
    final normalizedEndpoint =
        endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('http://$ip$normalizedEndpoint');
  }

  /// Fetches the latest sensor reading from the ESP32.
  /// Throws an exception on network failure or bad response,
  /// which the caller should catch and surface to the user.
  Future<SensorData> fetchSensorData() async {
    final uri = await _buildUri();
    final response = await http.get(uri).timeout(
          const Duration(seconds: 5),
        );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonBody = jsonDecode(response.body);
      return SensorData.fromJson(jsonBody);
    } else {
      throw Exception('ESP32 returned status code ${response.statusCode}');
    }
  }
}
