import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/player.dart';
import '../models/prediction.dart';

class PerformanceChart extends StatelessWidget {
  final List<Performance> performances;
  final List<Prediction> predictions;
  final String metricType;
  final String title;
  final Color color;
  
  const PerformanceChart({
    Key? key,
    required this.performances,
    required this.predictions,
    required this.metricType,
    required this.title,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart title with trend indicator
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(width: 8),
            _buildTrendIndicator(),
          ],
        ),
        const SizedBox(height: 12),
        
        // Chart
        Expanded(
          child: _buildLineChart(),
        ),
      ],
    );
  }

  Widget _buildTrendIndicator() {
    // Find prediction for this metric type
    final prediction = predictions.firstWhere(
      (p) => p.metricType == metricType,
      orElse: () => Prediction(
        metricType: metricType,
        currentValue: 0,
        predictedValue: 0,
        percentageChange: 0,
      ),
    );
    
    // Determine if this metric shows a decline
    final isDecline = prediction.percentageChange < -0.05;
    
    if (prediction.percentageChange == 0) {
      return const SizedBox.shrink(); // No prediction available
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDecline ? Colors.red.shade100 : Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isDecline ? Icons.arrow_downward : Icons.arrow_upward,
            color: isDecline ? Colors.red : Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${(prediction.percentageChange * 100).abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: isDecline ? Colors.red.shade800 : Colors.green.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: _getYAxisInterval(),
          verticalInterval: 1,
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                // Show match number or label as "Next" for prediction
                final matchNum = value.toInt();
                if (matchNum == performances.length + 1) {
                  return const Text(
                    'Pred',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }
                if (matchNum > 0 && matchNum <= performances.length) {
                  // Show just the match number for cleaner display
                  return Text(
                    matchNum.toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: _getYAxisInterval(),
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                // Format y-axis values based on metric type
                if (metricType == 'pass_completion_rate') {
                  return Text(
                    '${(value * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  );
                } else {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                    ),
                  );
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.shade300),
        ),
        minX: 1,
        maxX: performances.length + 1, // +1 for prediction
        minY: _getMinY(),
        maxY: _getMaxY(),
        lineBarsData: [
          // Historical data line
          LineChartBarData(
            spots: _getDataSpots(),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
          // Prediction line (shown as dashed)
          LineChartBarData(
            spots: _getPredictionSpots(),
            isCurved: false,
            color: Colors.red,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: Colors.red,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            dashArray: [5, 5], // Dashed line
          ),
        ],
      ),
    );
  }

  // Generate data spots for historical performance
  List<FlSpot> _getDataSpots() {
    final spots = <FlSpot>[];
    for (var i = 0; i < performances.length; i++) {
      final performance = performances[i];
      final y = _getMetricValue(performance);
      spots.add(FlSpot((i + 1).toDouble(), y));
    }
    return spots;
  }

  // Generate prediction spot (connects last actual data point to prediction)
  List<FlSpot> _getPredictionSpots() {
    final prediction = predictions.firstWhere(
      (p) => p.metricType == metricType,
      orElse: () => Prediction(
        metricType: metricType,
        currentValue: 0,
        predictedValue: 0,
        percentageChange: 0,
      ),
    );
    
    if (prediction.percentageChange == 0 || performances.isEmpty) {
      return []; // No prediction available
    }
    
    final lastPerformance = performances.last;
    final lastX = performances.length.toDouble();
    final lastY = _getMetricValue(lastPerformance);
    
    // Calculate predicted value
    final predictedY = lastY * (1 + prediction.percentageChange);
    
    return [
      FlSpot(lastX, lastY),
      FlSpot(lastX + 1, predictedY),
    ];
  }

  // Extract the appropriate metric value from a performance
  double _getMetricValue(Performance performance) {
    switch (metricType) {
      case 'pass_completion_rate':
        return performance.passCompletionRate;
      case 'total_events':
        return performance.totalEvents.toDouble();
      case 'total_passes':
        return performance.totalPasses.toDouble();
      case 'defensive_actions':
        return performance.defensiveActions.toDouble();
      default:
        return 0;
    }
  }

  // Determine min Y value for chart
  double _getMinY() {
    if (performances.isEmpty) return 0;
    
    // Get minimum value from historical data
    var minY = performances
        .map((p) => _getMetricValue(p))
        .reduce((a, b) => a < b ? a : b);
    
    // Check prediction as well
    final prediction = predictions.firstWhere(
      (p) => p.metricType == metricType,
      orElse: () => Prediction(
        metricType: metricType,
        currentValue: 0,
        predictedValue: 0,
        percentageChange: 0,
      ),
    );
    
    if (prediction.percentageChange != 0) {
      final lastPerformance = performances.last;
      final lastY = _getMetricValue(lastPerformance);
      final predictedY = lastY * (1 + prediction.percentageChange);
      minY = minY < predictedY ? minY : predictedY;
    }
    
    // Add some padding (10% below the minimum)
    return minY * 0.9;
  }

  // Determine max Y value for chart
  double _getMaxY() {
    if (performances.isEmpty) return 1;
    
    // Get maximum value from historical data
    var maxY = performances
        .map((p) => _getMetricValue(p))
        .reduce((a, b) => a > b ? a : b);
    
    // Check prediction as well
    final prediction = predictions.firstWhere(
      (p) => p.metricType == metricType,
      orElse: () => Prediction(
        metricType: metricType,
        currentValue: 0,
        predictedValue: 0,
        percentageChange: 0,
      ),
    );
    
    if (prediction.percentageChange != 0) {
      final lastPerformance = performances.last;
      final lastY = _getMetricValue(lastPerformance);
      final predictedY = lastY * (1 + prediction.percentageChange);
      maxY = maxY > predictedY ? maxY : predictedY;
    }
    
    // Add some padding (10% above the maximum)
    return maxY * 1.1;
  }

  // Get appropriate Y-axis interval based on the metric type
  double _getYAxisInterval() {
    if (performances.isEmpty) return 0.1;
    
    switch (metricType) {
      case 'pass_completion_rate':
        return 0.1; // 10% intervals
      case 'total_events':
        final maxY = performances
            .map((p) => p.totalEvents)
            .reduce((a, b) => a > b ? a : b);
        return maxY > 50 ? 10 : 5;
      case 'total_passes':
        final maxY = performances
            .map((p) => p.totalPasses)
            .reduce((a, b) => a > b ? a : b);
        return maxY > 100 ? 20 : 10;
      case 'defensive_actions':
        final maxY = performances
            .map((p) => p.defensiveActions)
            .reduce((a, b) => a > b ? a : b);
        return maxY > 20 ? 5 : 2;
      default:
        return 1;
    }
  }
}