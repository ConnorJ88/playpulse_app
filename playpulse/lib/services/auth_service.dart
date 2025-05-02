import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/player.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _token;
  String? _userId;
  String? _userName;
  final ApiService _apiService = ApiService();

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get token => _token;
  String? get userId => _userId;
  String? get userName => _userName;

  // Constructor - check if user is already authenticated
  AuthService() {
    _loadAuthData();
  }

  // Load authentication data from local storage
  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');
    
    if (authData != null) {
      final decodedData = json.decode(authData) as Map<String, dynamic>;
      _token = decodedData['token'];
      _userId = decodedData['user_id'];
      _userName = decodedData['user_name'];
      _isAuthenticated = true;
      notifyListeners();
    }
  }

  // Save authentication data to local storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final authData = json.encode({
      'token': _token,
      'user_id': _userId,
      'user_name': _userName,
    });
    await prefs.setString('auth_data', authData);
  }

  // Login user with just a player ID
  Future<void> login(String playerId) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    try {
      // Convert playerId to int
      final playerIdInt = int.parse(playerId);
      
      // Fetch player data using the API service
      final player = await _apiService.getPlayerById(playerIdInt);
      
      // If we get here, the player exists and login is successful
      _isAuthenticated = true;
      _token = 'player_token_${playerIdInt}_${DateTime.now().millisecondsSinceEpoch}';
      _userId = playerId;
      _userName = player.name;
      
      await _saveAuthData();
      notifyListeners();
    } catch (e) {
      // If player not found or other error
      throw Exception('Invalid player ID or player not found');
    }
  }

  // Logout user
  Future<void> logout() async {
    // Clear authentication data
    _isAuthenticated = false;
    _token = null;
    _userId = null;
    _userName = null;
    
    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_data');
    
    notifyListeners();
  }
}