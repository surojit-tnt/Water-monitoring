import 'package:flutter/material.dart';

/// Simple rule-of-thumb thresholds for drinking-water quality.
/// Adjust these to match the standard you are following
/// (e.g. WHO / BIS 10500) or your project requirements.
class WaterQualityRules {
  static Map<String, dynamic> phStatus(double ph) {
    if (ph < 6.5) return {'label': 'Acidic', 'color': Colors.redAccent};
    if (ph > 8.5) return {'label': 'Alkaline', 'color': Colors.orangeAccent};
    return {'label': 'Normal', 'color': Colors.green};
  }

  static Map<String, dynamic> tdsStatus(double tds) {
    if (tds > 500) return {'label': 'High', 'color': Colors.redAccent};
    if (tds > 300) return {'label': 'Moderate', 'color': Colors.orangeAccent};
    return {'label': 'Good', 'color': Colors.green};
  }

  static Map<String, dynamic> temperatureStatus(double temp) {
    if (temp > 35) return {'label': 'High', 'color': Colors.redAccent};
    if (temp < 10) return {'label': 'Low', 'color': Colors.blueAccent};
    return {'label': 'Normal', 'color': Colors.green};
  }

  static Map<String, dynamic> turbidityStatus(double ntu) {
    if (ntu > 5) return {'label': 'Turbid', 'color': Colors.redAccent};
    if (ntu > 1) return {'label': 'Slight', 'color': Colors.orangeAccent};
    return {'label': 'Clear', 'color': Colors.green};
  }
}
