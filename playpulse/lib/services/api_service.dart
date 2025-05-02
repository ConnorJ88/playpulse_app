import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/prediction.dart';
import '../services/tflite_service.dart';

class ApiService {
  // Base URL for API
  final String baseUrl = 'https://api.playpulse.example.com/v1';  // Replace with your actual API URL
  
  // For demo purposes, we'll use mock data, but provide options for API and TFLite
  final bool useMockData = true;
  final bool useTFLite = true;  // Set to true to use on-device inference instead of API
  
  // TFLite service
  final TFLiteService _tfliteService = TFLiteService();

  // Get player by ID
  Future<Player> getPlayerById(int playerId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      return _getMockPlayer(playerId);
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/players/$playerId'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      return Player.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load player data');
    }
  }

  // Search players by name
  Future<List<Player>> searchPlayers(String query) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      return _getMockPlayersList().where(
        (player) => player.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/players/search?q=$query'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> playersJson = json.decode(response.body);
      return playersJson.map((json) => Player.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search players');
    }
  }

  // Get player performances
  Future<List<Performance>> getPlayerPerformances(int playerId) async {
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate network delay
      return _getMockPerformances(playerId);
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/players/$playerId/performances'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> performancesJson = json.decode(response.body);
      return performancesJson.map((json) => Performance.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load player performances');
    }
  }

  // Get player predictions using either API or on-device TFLite
  Future<List<Prediction>> getPlayerPredictions(int playerId) async {
    // Get performances first (needed for both API and TFLite)
    final performances = await getPlayerPerformances(playerId);
    
    if (performances.isEmpty) {
      throw Exception('No performance data available for predictions');
    }
    
    // Use on-device TFLite for predictions
    if (useTFLite) {
      try {
        // Initialize TFLite service if not already initialized
        await _tfliteService.initialize();
        
        // Use the last performance as input for prediction
        final lastPerformance = performances.last;
        return _tfliteService.predictAllMetrics(lastPerformance);
      } catch (e) {
        print('Error using TFLite for predictions: $e');
        // Fall back to API or mock data if TFLite fails
      }
    }
    
    // If not using TFLite or TFLite failed, use API or mock data
    if (useMockData) {
      await Future.delayed(const Duration(milliseconds: 1200)); // Simulate network delay
      return _getMockPredictions(playerId);
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/players/$playerId/predictions'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> predictionsJson = json.decode(response.body);
      return predictionsJson.map((json) => Prediction.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load player predictions');
    }
  }

  // Mock data methods
  Player _getMockPlayer(int playerId) {
    final players = _getMockPlayersList();
    return players.firstWhere(
      (player) => player.id == playerId,
      orElse: () => players.first,
    );
  }

  List<Player> _getMockPlayersList() {
    return [
      Player(
        id: 1,
        name: 'Lionel Messi',
        team: 'Inter Miami CF',
        position: 'Forward',
        age: 36,
        nationality: 'Argentina',
        imageUrl: 'https://example.com/messi.jpg',
      ),
      Player(
        id: 2,
        name: 'Cristiano Ronaldo',
        team: 'Al Nassr FC',
        position: 'Forward',
        age: 38,
        nationality: 'Portugal',
        imageUrl: 'https://example.com/ronaldo.jpg',
      ),
      Player(
        id: 3,
        name: 'Kevin De Bruyne',
        team: 'Manchester City',
        position: 'Midfielder',
        age: 32,
        nationality: 'Belgium',
        imageUrl: 'https://example.com/debruyne.jpg',
      ),
      Player(
        id: 4,
        name: 'Virgil van Dijk',
        team: 'Liverpool',
        position: 'Defender',
        age: 32,
        nationality: 'Netherlands',
        imageUrl: 'https://example.com/vandijk.jpg',
      ),
      Player(
        id: 5,
        name: 'Jude Bellingham',
        team: 'Real Madrid',
        position: 'Midfielder',
        age: 20,
        nationality: 'England',
        imageUrl: 'https://example.com/bellingham.jpg',
      ),
    ];
  }

  List<Performance> _getMockPerformances(int playerId) {
    // Generate random performances for demo purposes
    return List.generate(
      10,
      (index) => Performance(
        id: 100 + index,
        playerId: playerId,
        date: '2025-${(index % 3) + 1}-${(index * 3) + 1}', // Generate dates going backward
        competition: ['Premier League', 'Champions League', 'FA Cup'][index % 3],
        season: '2024/2025',
        homeTeam: ['Manchester City', 'Liverpool', 'Chelsea', 'Arsenal', 'Tottenham'][index % 5],
        awayTeam: ['Real Madrid', 'Barcelona', 'Bayern Munich', 'PSG', 'Inter Milan'][index % 5],
        totalEvents: 30 + (index * 2),
        totalPasses: 40 + (index * 3),
        completedPasses: 30 + (index * 2),
        passCompletionRate: 0.75 + (index * 0.01),
        totalShots: (index % 5) + 1,
        goals: index % 2,
        defensiveActions: 10 + index,
        matchNumber: index + 1,
      ),
    );
  }

  List<Prediction> _getMockPredictions(int playerId) {
    // Generate predictions with some metrics showing decline
    return [
      Prediction(
        metricType: 'pass_completion_rate',
        currentValue: 0.78,
        predictedValue: 0.71,
        percentageChange: -0.09, // 9% decline
      ),
      Prediction(
        metricType: 'total_events',
        currentValue: 42,
        predictedValue: 45,
        percentageChange: 0.07, // 7% improvement
      ),
      Prediction(
        metricType: 'total_passes',
        currentValue: 55,
        predictedValue: 50,
        percentageChange: -0.09, // 9% decline
      ),
      Prediction(
        metricType: 'defensive_actions',
        currentValue: 18,
        predictedValue: 19,
        percentageChange: 0.05, // 5% improvement
      ),
    ];
  }
}