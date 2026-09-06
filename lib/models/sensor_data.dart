class SensorData {
  final double ph;
  final double tds; // in ppm
  final double temperature; // in °C
  final double turbidity; // in NTU
  final DateTime timestamp;

  SensorData({
    required this.ph,
    required this.tds,
    required this.temperature,
    required this.turbidity,
    required this.timestamp,
  });

  /// Parses JSON coming from the ESP32.
  /// Expected ESP32 JSON response example:
  /// {
  ///   "ph": 7.12,
  ///   "tds": 342.5,
  ///   "temperature": 26.4,
  ///   "turbidity": 3.8
  /// }
  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      ph: _toDouble(json['ph']),
      tds: _toDouble(json['tds']),
      temperature: _toDouble(json['temperature']),
      turbidity: _toDouble(json['turbidity']),
      timestamp: DateTime.now(),
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  factory SensorData.empty() {
    return SensorData(
      ph: 0,
      tds: 0,
      temperature: 0,
      turbidity: 0,
      timestamp: DateTime.now(),
    );
  }
}
