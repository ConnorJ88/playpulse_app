import 'package:flutter/material.dart';

class Prediction {
  final String metricType;
  final double currentValue;
  final double predictedValue;
  final double percentageChange;

  Prediction({
    required this.metricType,
    required this.currentValue,
    required this.predictedValue,
    required this.percentageChange,
  });

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      metricType: json['metric_type'],
      currentValue: json['current_value'].toDouble(),
      predictedValue: json['predicted_value'].toDouble(),
      percentageChange: json['percentage_change'].toDouble(),
    );
  }

  // Determine if this prediction shows a decline
  bool get isDecline => percentageChange <= -0.05; // 5% threshold

  // Get color based on prediction (red for decline, green for improvement)
  Color getColor() {
    if (isDecline) {
      return Colors.red;
    } else if (percentageChange >= 0.05) { // 5% improvement
      return Colors.green;
    } else {
      return Colors.blue; // Neutral/stable
    }
  }

  // Get icon based on prediction
  IconData getIcon() {
    if (isDecline) {
      return Icons.arrow_downward;
    } else if (percentageChange >= 0.05) {
      return Icons.arrow_upward;
    } else {
      return Icons.remove; // Stable
    }
  }
}