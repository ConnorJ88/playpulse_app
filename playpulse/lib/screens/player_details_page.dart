import 'package:flutter/material.dart';
import '../models/player.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';
import '../widgets/alert.dart';
import '../widgets/performance_chart.dart';
import '../widgets/stats_card.dart';
import '../widgets/season_summary.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final int playerId;

  const PlayerDetailsScreen({
    Key? key, 
    required this.playerId,
  }) : super(key: key);

  @override
  _PlayerDetailsScreenState createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String? _errorMessage;
  
  Player? _player;
  List<Performance> _performances = [];
  List<Prediction> _predictions = [];
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayerData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load player data
      final player = await _apiService.getPlayerById(widget.playerId);
      
      // Load performance data
      final performances = await _apiService.getPlayerPerformances(widget.playerId);
      
      // Load predictions
      final predictions = await _apiService.getPlayerPredictions(widget.playerId);
      
      // Update state
      setState(() {
        _player = player;
        _performances = performances;
        _predictions = predictions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Get predictions that show decline
  List<Prediction> get _decliningPredictions {
    return _predictions.where((p) => p.isDecline).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_player?.name ?? 'Player Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlayerData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null 
              ? Center(
                  child: Text(
                    'Error: $_errorMessage',
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              : _buildPlayerContent(),
    );
  }

  Widget _buildPlayerContent() {
    return Column(
      children: [
        // Player header with basic info
        _buildPlayerHeader(),
        
        // Performance decline warnings (if any)
        if (_decliningPredictions.isNotEmpty)
          PredictionAlert(predictions: _decliningPredictions),
        
        // Tab bar for different sections
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Recent Matches'),
            Tab(text: 'Season Stats'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildRecentMatchesTab(),
              _buildSeasonStatsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerHeader() {
    if (_player == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          // Player avatar
          CircleAvatar(
            radius: 40,
            backgroundImage: _player!.imageUrl != null
                ? NetworkImage(_player!.imageUrl!)
                : null,
            child: _player!.imageUrl == null
                ? Text(
                    _player!.name.substring(0, 2).toUpperCase(),
                    style: const TextStyle(fontSize: 24),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _player!.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Team: ${_player!.team}',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Position: ${_player!.position}',
                  style: const TextStyle(fontSize: 16),
                ),
                if (_player!.age != null)
                  Text(
                    'Age: ${_player!.age}',
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_performances.isEmpty) {
      return const Center(child: Text('No performance data available'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance predictions
          const Text(
            'Performance Predictions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Performance charts
          Container(
            height: 250,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PerformanceChart(
              performances: _performances,
              predictions: _predictions,
              metricType: 'pass_completion_rate',
              title: 'Pass Completion Rate',
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          
          // Defensive actions chart
          Container(
            height: 250,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: PerformanceChart(
              performances: _performances,
              predictions: _predictions,
              metricType: 'defensive_actions',
              title: 'Defensive Actions',
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 24),
          
          // Key stats summary
          const Text(
            'Key Performance Metrics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats grid
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              StatsCard(
                title: 'Pass Completion',
                value: '${(_performances.last.passCompletionRate * 100).toStringAsFixed(1)}%',
                icon: Icons.compare_arrows,
                color: Colors.blue,
              ),
              StatsCard(
                title: 'Defensive Actions',
                value: _performances.last.defensiveActions.toString(),
                icon: Icons.shield,
                color: Colors.red,
              ),
              StatsCard(
                title: 'Total Events',
                value: _performances.last.totalEvents.toString(),
                icon: Icons.event,
                color: Colors.green,
              ),
              StatsCard(
                title: 'Total Passes',
                value: _performances.last.totalPasses.toString(),
                icon: Icons.swap_horiz,
                color: Colors.orange,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesTab() {
    if (_performances.isEmpty) {
      return const Center(child: Text('No recent match data available'));
    }
    
    return ListView.builder(
      itemCount: _performances.length,
      itemBuilder: (context, index) {
        // Display in reverse chronological order (newest first)
        final performance = _performances[_performances.length - 1 - index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Match info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${performance.homeTeam} vs ${performance.awayTeam}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      performance.date,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Competition: ${performance.competition}'),
                const SizedBox(height: 16),
                
                // Performance metrics
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem('Pass Completion', 
                      '${(performance.passCompletionRate * 100).toStringAsFixed(1)}%'),
                    _buildMetricItem('Total Events', 
                      performance.totalEvents.toString()),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMetricItem('Total Passes', 
                      performance.totalPasses.toString()),
                    _buildMetricItem('Defensive Actions', 
                      performance.defensiveActions.toString()),
                  ],
                ),
                if (performance.goals > 0) ...[
                  const SizedBox(height: 8),
                  _buildMetricItem('Goals', 
                    performance.goals.toString(), isHighlighted: true),
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, {bool isHighlighted = false}) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isHighlighted ? Colors.green : Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                  color: isHighlighted ? Colors.green : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SeasonSummary(performances: _performances),
    );
  }
}