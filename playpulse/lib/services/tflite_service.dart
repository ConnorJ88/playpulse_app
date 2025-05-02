import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/player.dart';
import '../models/prediction.dart';

class TFLiteService {
  static const String MODEL_LR_FILENAME = 'linear_regression_model.tflite';
  static const String MODEL_RF_FILENAME = 'random_forest_model.tflite';
  static const String SCALER_PARAMS_FILENAME = 'scaler_params.json';
  
  Interpreter? _interpreterLR;
  Interpreter? _interpreterRF;
  Map<String, dynamic>? _scalerParams;
  bool _isInitialized = false;

  // Singleton pattern
  static final TFLiteService _instance = TFLiteService._internal();
  factory TFLiteService() => _instance;
  TFLiteService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load TFLite models
      await _loadModels();
      
      // Load scaler parameters
      await _loadScalerParams();
      
      _isInitialized = true;
      print('TFLite service initialized successfully');
    } catch (e) {
      print('Error initializing TFLite service: $e');
      rethrow;
    }
  }

  Future<void> _loadModels() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      
      // Check if models exist in app directory, if not, copy from assets
      final lrModelPath = '${appDir.path}/$MODEL_LR_FILENAME';
      final rfModelPath = '${appDir.path}/$MODEL_RF_FILENAME';
      
      final lrModelFile = File(lrModelPath);
      final rfModelFile = File(rfModelPath);
      
      if (!lrModelFile.existsSync()) {
        final modelData = await rootBundle.load('assets/models/$MODEL_LR_FILENAME');
        await lrModelFile.writeAsBytes(modelData.buffer.asUint8List());
      }
      
      if (!rfModelFile.existsSync()) {
        final modelData = await rootBundle.load('assets/models/$MODEL_RF_FILENAME');
        await rfModelFile.writeAsBytes(modelData.buffer.asUint8List());
      }
      
      // Load the TFLite models
      _interpreterLR = await Interpreter.fromFile(lrModelFile);
      _interpreterRF = await Interpreter.fromFile(rfModelFile);
      
    } catch (e) {
      print('Error loading TFLite models: $e');
      rethrow;
    }
  }

  Future<void> _loadScalerParams() async {
    try {
      // Get application documents directory
      final appDir = await getApplicationDocumentsDirectory();
      final scalerParamsPath = '${appDir.path}/$SCALER_PARAMS_FILENAME';
      final scalerParamsFile = File(scalerParamsPath);
      
      if (!scalerParamsFile.existsSync()) {
        final paramsData = await rootBundle.loadString('assets/models/$SCALER_PARAMS_FILENAME');
        await scalerParamsFile.writeAsString(paramsData);
        _scalerParams = json.decode(paramsData);
      } else {
        final paramsData = await scalerParamsFile.readAsString();
        _scalerParams = json.decode(paramsData);
      }
    } catch (e) {
      print('Error loading scaler parameters: $e');
      rethrow;
    }
  }

  // Scale features using the same parameters as in Python
  List<double> _scaleFeatures(List<double> features) {
    if (_scalerParams == null) {
      throw Exception('Scaler parameters not loaded');
    }
    
    final min = _scalerParams!['min_'] as List;
    final scale = _scalerParams!['scale_'] as List;
    
    List<double> scaledFeatures = [];
    for (int i = 0; i < features.length; i++) {
      scaledFeatures.add((features[i] - min[i]) * scale[i]);
    }
    
    return scaledFeatures;
  }

  Future<Prediction> predictPerformance(Performance lastPerformance, String metricType) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (_interpreterLR == null || _interpreterRF == null) {
      throw Exception('TFLite models not loaded');
    }
    
    // Extract features from the performance data
    List<double> features = [
      lastPerformance.passCompletionRate,
      lastPerformance.totalEvents.toDouble(),
      lastPerformance.totalPasses.toDouble(),
      lastPerformance.defensiveActions.toDouble()
    ];
    
    // Scale features
    final scaledFeatures = _scaleFeatures(features);
    
    // Prepare input for TFLite
    var input = [scaledFeatures];
    
    // Prepare output tensors
    var outputLR = List<double>.filled(1, 0).reshape([1, 1]);
    var outputRF = List<double>.filled(1, 0).reshape([1, 1]);
    
    // Run inference
    _interpreterLR!.run(input, outputLR);
    _interpreterRF!.run(input, outputRF);
    
    // Calculate ensemble prediction (average of both models)
    final predictionLR = outputLR[0][0];
    final predictionRF = outputRF[0][0];
    final ensemblePrediction = (predictionLR + predictionRF) / 2;
    
    // Get current value based on metric type
    double currentValue;
    switch (metricType) {
      case 'pass_completion_rate':
        currentValue = lastPerformance.passCompletionRate;
        break;
      case 'total_events':
        currentValue = lastPerformance.totalEvents.toDouble();
        break;
      case 'total_passes':
        currentValue = lastPerformance.totalPasses.toDouble();
        break;
      case 'defensive_actions':
        currentValue = lastPerformance.defensiveActions.toDouble();
        break;
      default:
        currentValue = lastPerformance.passCompletionRate;
    }
    
    // Calculate percentage change
    final percentageChange = (ensemblePrediction - currentValue) / currentValue;
    
    return Prediction(
      metricType: metricType,
      currentValue: currentValue,
      predictedValue: ensemblePrediction,
      percentageChange: percentageChange,
    );
  }

  // Predict all metrics at once
  Future<List<Prediction>> predictAllMetrics(Performance lastPerformance) async {
    final metrics = [
      'pass_completion_rate',
      'total_events',
      'total_passes',
      'defensive_actions'
    ];
    
    List<Prediction> predictions = [];
    
    for (final metric in metrics) {
      final prediction = await predictPerformance(lastPerformance, metric);
      predictions.add(prediction);
    }
    
    return predictions;
  }

  void dispose() {
    _interpreterLR?.close();
    _interpreterRF?.close();
    _isInitialized = false;
  }
}