import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/prediction.dart';

/// This class provides a bridge to execute Python code from Flutter
/// It uses Chaquopy library for Android and Python-Apple-Support for iOS
class PythonBridge {
  static const MethodChannel _channel = MethodChannel('com.playpulse/python');
  static const String PYTHON_ASSETS_PATH = 'assets/python';
  
  static bool _isPythonInitialized = false;
  
  // Initialize Python environment
  static Future<void> initialize() async {
    if (_isPythonInitialized) return;
    
    try {
      // Extract Python files to app directory
      await _extractPythonFiles();
      
      // Initialize Python interpreter
      final result = await _channel.invokeMethod('initializePython');
      if (result == true) {
        _isPythonInitialized = true;
        print('Python environment initialized successfully');
      } else {
        throw Exception('Failed to initialize Python environment');
      }
    } catch (e) {
      print('Error initializing Python environment: $e');
      rethrow;
    }
  }
  
  // Extract Python files from assets to app directory
  static Future<void> _extractPythonFiles() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final pythonDir = Directory('${appDir.path}/python');
      
      // Create python directory if it doesn't exist
      if (!pythonDir.existsSync()) {
        pythonDir.createSync();
      }
      
      // Extract Python files
      final pythonFiles = [
        'ml_models.py',
        'data_collection.py',
        'requirements.txt',
        '__init__.py'
      ];
      
      for (final file in pythonFiles) {
        final assetFile = '$PYTHON_ASSETS_PATH/$file';
        final targetFile = '${pythonDir.path}/$file';
        
        final fileExists = File(targetFile).existsSync();
        if (!fileExists) {
          final fileContent = await rootBundle.loadString(assetFile);
          await File(targetFile).writeAsString(fileContent);
        }
      }
      
      print('Python files extracted successfully');
    } catch (e) {
      print('Error extracting Python files: $e');
      rethrow;
    }
  }
  
  // Find player by name
  static Future<Map<String, dynamic>> findPlayer(String playerName) async {
    if (!_isPythonInitialized) {
      await initialize();
    }
    
    try {
      final result = await _channel.invokeMethod('executePython', {
        'module': 'player_search',
        'function': 'find_player',
        'args': [playerName]
      });
      
      return json.decode(result);
    } catch (e) {
      print('Error finding player: $e');
      rethrow;
    }
  }
  
  // Collect player data
  static Future<List<Performance>> collectPlayerData(int playerId) async {
    if (!_isPythonInitialized) {
      await initialize();
    }
    
    try {
      final result = await _channel.invokeMethod('executePython', {
        'module': 'data_collector',
        'function': 'collect_player_data',
        'args': [playerId]
      });
      
      final Map<String, dynamic> resultMap = json.decode(result);
      if (resultMap['success'] == true) {
        final List<dynamic> performancesData = resultMap['performance'];
        return performancesData.map((data) => Performance.fromJson(data)).toList();
      } else {
        throw Exception(resultMap['message'] ?? 'Failed to collect player data');
      }
    } catch (e) {
      print('Error collecting player data: $e');
      rethrow;
    }
  }
  
  // Predict player performance
  static Future<List<Prediction>> predictPlayerPerformance(List<Performance> performances) async {
    if (!_isPythonInitialized) {
      await initialize();
    }
    
    if (performances.isEmpty) {
      throw Exception('No performance data available for prediction');
    }
    
    try {
      // Convert performances to JSON
      final performancesJson = performances.map((p) => {
        'match_id': p.id,
        'match_date': p.date,
        'competition': p.competition,
        'season': p.season,
        'home_team': p.homeTeam,
        'away_team': p.awayTeam,
        'total_events': p.totalEvents,
        'total_passes': p.totalPasses,
        'completed_passes': p.completedPasses,
        'pass_completion_rate': p.passCompletionRate,
        'total_shots': p.totalShots,
        'goals': p.goals,
        'defensive_actions': p.defensiveActions,
        'match_num': p.matchNumber,
      }).toList();
      
      final result = await _channel.invokeMethod('executePython', {
        'module': 'performance_predictor',
        'function': 'predict_performance',
        'args': [json.encode(performancesJson)]
      });
      
      final Map<String, dynamic> resultMap = json.decode(result);
      if (resultMap['success'] == true) {
        final Map<String, dynamic> predictionData = resultMap['predictions'];
        
        List<Prediction> predictions = [];
        predictionData.forEach((metric, value) {
          predictions.add(Prediction(
            metricType: metric,
            currentValue: value['current_value'],
            predictedValue: value['predicted_value'],
            percentageChange: value['percentage_change'],
          ));
        });
        
        return predictions;
      } else {
        throw Exception(resultMap['message'] ?? 'Failed to predict player performance');
      }
    } catch (e) {
      print('Error predicting player performance: $e');
      rethrow;
    }
  }
}