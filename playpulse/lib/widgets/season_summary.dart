import 'package:flutter/material.dart';
import '../models/player.dart';
import 'dart:math' as math;

class SeasonSummary extends StatelessWidget {
  final List<Performance> performances;

  const SeasonSummary({
    Key? key,
    required this.performances,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (performances.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }

    // Calculate season stats
    final totalMatches = performances.length;
    final passCompletionRate = _calculateAveragePassCompletionRate();
    final totalEvents = _calculateTotalEvents();
    final totalPasses = _calculateTotalPasses();
    final defensiveActions = _calculateTotalDefensiveActions();
    final totalGoals = _calculateTotalGoals();
    final goalsPerMatch = totalGoals / totalMatches;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season header
          const Text(
            'Season Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Total matches card
          _buildSummaryCard(
            title: 'Total Matches',
            value: totalMatches.toString(),
            icon: Icons.sports_soccer,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          
          // Performance metrics
          const Text(
            'Overall Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Metrics grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSummaryCard(
                title: 'Average Pass Completion',
                value: '${(passCompletionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.swap_horiz,
                color: Colors.green,
              ),
              _buildSummaryCard(
                title: 'Total Goals',
                value: totalGoals.toString(),
                icon: Icons.sports_soccer,
                color: Colors.orange,
              ),
              _buildSummaryCard(
                title: 'Goals Per Match',
                value: goalsPerMatch.toStringAsFixed(2),
                icon: Icons.trending_up,
                color: Colors.purple,
              ),
              _buildSummaryCard(
                title: 'Defensive Actions',
                value: defensiveActions.toString(),
                icon: Icons.shield,
                color: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Match Distribution
          const Text(
            'Performance Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildPerformanceDistributionChart(),
          const SizedBox(height: 24),
          
          // Performance trends
          const Text(
            'Performance Highs',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          // Best performance
          _buildPerformanceHighlight(
            title: 'Best Pass Completion',
            performance: _getBestPassCompletionMatch(),
            metricName: 'Pass Completion',
            metricValue: ((_getBestPassCompletionMatch()?.passCompletionRate ?? 0) * 100).toStringAsFixed(1) + '%',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          
          _buildPerformanceHighlight(
            title: 'Most Defensive Actions',
            performance: _getMostDefensiveActionsMatch(),
            metricName: 'Defensive Actions',
            metricValue: (_getMostDefensiveActionsMatch()?.defensiveActions ?? 0).toString(),
            color: Colors.red,
          ),
          const SizedBox(height: 12),
          
          _buildPerformanceHighlight(
            title: 'Most Events',
            performance: _getMostEventsMatch(),
            metricName: 'Events',
            metricValue: (_getMostEventsMatch()?.totalEvents ?? 0).toString(),
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceDistributionChart() {
    // Simple horizontal bar chart showing key metrics
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDistributionBar(
            label: 'Pass Completion',
            value: _calculateAveragePassCompletionRate(),
            maxValue: 1.0,
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Goals',
            value: _calculateTotalGoals() / performances.length / 3, // Scale down for visibility (assuming max ~3 goals per match)
            maxValue: 1.0,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Defensive Actions',
            value: _calculateAverageDefensiveActions() / 20, // Scale down for visibility (assuming max ~20 defensive actions)
            maxValue: 1.0,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          _buildDistributionBar(
            label: 'Events',
            value: _calculateAverageTotalEvents() / 50, // Scale down for visibility (assuming max ~50 events)
            maxValue: 1.0,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionBar({
    required String label,
    required double value,
    required double maxValue,
    required Color color,
  }) {
    final percentage = math.min(1.0, value / maxValue);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            // Background bar
            Container(
              height: 12,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Value bar
            Container(
              height: 12,
              width: percentage * double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPerformanceHighlight({
    required String title,
    required Performance? performance,
    required String metricName,
    required String metricValue,
    required Color color,
  }) {
    if (performance == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Trophy icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Match details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${performance.homeTeam} vs ${performance.awayTeam}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  performance.date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Metric value
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                metricValue,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                metricName,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods to calculate statistics
  double _calculateAveragePassCompletionRate() {
    return performances.map((p) => p.passCompletionRate).reduce((a, b) => a + b) / performances.length;
  }

  int _calculateTotalEvents() {
    return performances.map((p) => p.totalEvents).reduce((a, b) => a + b);
  }

  double _calculateAverageTotalEvents() {
    return _calculateTotalEvents() / performances.length;
  }

  int _calculateTotalPasses() {
    return performances.map((p) => p.totalPasses).reduce((a, b) => a + b);
  }

  int _calculateTotalDefensiveActions() {
    return performances.map((p) => p.defensiveActions).reduce((a, b) => a + b);
  }

  double _calculateAverageDefensiveActions() {
    return _calculateTotalDefensiveActions() / performances.length;
  }

  int _calculateTotalGoals() {
    return performances.map((p) => p.goals).reduce((a, b) => a + b);
  }

  Performance? _getBestPassCompletionMatch() {
    if (performances.isEmpty) return null;
    return performances.reduce((a, b) => a.passCompletionRate > b.passCompletionRate ? a : b);
  }

  Performance? _getMostDefensiveActionsMatch() {
    if (performances.isEmpty) return null;
    return performances.reduce((a, b) => a.defensiveActions > b.defensiveActions ? a : b);
  }

  Performance? _getMostEventsMatch() {
    if (performances.isEmpty) return null;
    return performances.reduce((a, b) => a.totalEvents > b.totalEvents ? a : b);
  }
}