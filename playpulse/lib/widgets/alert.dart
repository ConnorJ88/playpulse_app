import 'package:flutter/material.dart';
import '../models/prediction.dart';

class PredictionAlert extends StatelessWidget {
  final List<Prediction> predictions;

  const PredictionAlert({
    Key? key,
    required this.predictions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Decline Alert',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'The player is predicted to experience a significant decline in:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          
          // List of declining metrics
          ...predictions.map((prediction) => Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Row(
              children: [
                const SizedBox(width: 16),
                const Icon(
                  Icons.arrow_downward,
                  color: Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_formatMetricName(prediction.metricType)}: ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Decline of ${(prediction.percentageChange * 100).abs().toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ],
            ),
          )).toList(),
          
          const SizedBox(height: 8),
          Text(
            'Recommendation: Consider monitoring player workload or providing additional support.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade800,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMetricName(String metricType) {
    switch (metricType) {
      case 'pass_completion_rate':
        return 'Pass Completion Rate';
      case 'total_events':
        return 'Total Event Involvement';
      case 'total_passes':
        return 'Total Passes';
      case 'defensive_actions':
        return 'Defensive Actions';
      default:
        return metricType.replaceAll('_', ' ').split(' ').map((word) => 
          word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : ''
        ).join(' ');
    }
  }
}