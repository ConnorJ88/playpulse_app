"""
This script provides functions to predict player performance using pre-trained TFLite models.
It is designed to be called from the Flutter app via the Python bridge.
"""

import os
import json
import numpy as np
import pandas as pd
import tensorflow as tf
from pathlib import Path

class PerformancePredictor:
    def __init__(self, models_dir=None):
        """Initialize the predictor with models directory."""
        if models_dir is None:
            # Get the directory of this script
            current_dir = Path(__file__).parent.absolute()
            models_dir = os.path.join(current_dir, 'tflite_models')
        
        self.models_dir = models_dir
        self.lr_interpreter = None
        self.rf_interpreter = None
        self.scaler_params = None
        self.model_info = None
        
        # Load models and parameters
        self._load_models()
    
    def _load_models(self):
        """Load TFLite models and scaler parameters."""
        try:
            # Load model info
            model_info_path = os.path.join(self.models_dir, 'model_info.json')
            if os.path.exists(model_info_path):
                with open(model_info_path, 'r') as f:
                    self.model_info = json.load(f)
            
            # Load scaler parameters
            scaler_path = os.path.join(self.models_dir, 'scaler_params.json')
            if os.path.exists(scaler_path):
                with open(scaler_path, 'r') as f:
                    self.scaler_params = json.load(f)
            
            # Load Linear Regression model
            lr_model_path = os.path.join(self.models_dir, 'linear_regression_model.tflite')
            if os.path.exists(lr_model_path):
                self.lr_interpreter = tf.lite.Interpreter(model_path=lr_model_path)
                self.lr_interpreter.allocate_tensors()
            
            # Load Random Forest model
            rf_model_path = os.path.join(self.models_dir, 'random_forest_model.tflite')
            if os.path.exists(rf_model_path):
                self.rf_interpreter = tf.lite.Interpreter(model_path=rf_model_path)
                self.rf_interpreter.allocate_tensors()
            
            return True
        except Exception as e:
            print(f"Error loading models: {e}")
            return False
    
    def _scale_features(self, features):
        """Scale features using the same parameters as in training."""
        if self.scaler_params is None:
            raise ValueError("Scaler parameters not loaded")
        
        min_ = self.scaler_params['min_']
        scale_ = self.scaler_params['scale_']
        
        scaled_features = []
        for i in range(len(features)):
            scaled_features.append((features[i] - min_[i]) * scale_[i])
        
        return scaled_features
    
    def _create_time_series_features(self, performances):
        """Create time series features from performance data."""
        if self.model_info is None:
            raise ValueError("Model info not loaded")
        
        # Get feature names and window size
        feature_names = self.model_info['features']
        window_size = self.model_info['window_size']
        
        # Create DataFrame from performances
        if isinstance(performances, list):
            # Convert list of dictionaries to DataFrame
            df = pd.DataFrame(performances)
        else:
            # Already a DataFrame
            df = performances
        
        # Sort by match number
        if 'match_num' in df.columns:
            df = df.sort_values('match_num')
        elif 'match_date' in df.columns:
            df = df.sort_values('match_date')
        
        # Select relevant features
        data = df[feature_names].copy()
        
        # Check if we have enough data
        if len(data) < window_size:
            raise ValueError(f"Not enough data. Need at least {window_size} matches, but got {len(data)}")
        
        # Get most recent data for prediction
        recent_data = data.tail(window_size).values
        
        # Scale the data
        scaled_data = np.array([self._scale_features(row) for row in recent_data])
        
        # Reshape for the models
        X_reshaped = scaled_data.reshape(1, scaled_data.shape[0] * scaled_data.shape[1])
        
        return X_reshaped, data
    
    def _run_inference(self, input_data):
        """Run inference using TFLite models."""
        if self.lr_interpreter is None or self.rf_interpreter is None:
            raise ValueError("Models not loaded")
        
        # Run inference with Linear Regression model
        input_details_lr = self.lr_interpreter.get_input_details()
        output_details_lr = self.lr_interpreter.get_output_details()
        
        self.lr_interpreter.set_tensor(input_details_lr[0]['index'], input_data.astype(np.float32))
        self.lr_interpreter.invoke()
        lr_output = self.lr_interpreter.get_tensor(output_details_lr[0]['index'])
        
        # Run inference with Random Forest model
        input_details_rf = self.rf_interpreter.get_input_details()
        output_details_rf = self.rf_interpreter.get_output_details()
        
        self.rf_interpreter.set_tensor(input_details_rf[0]['index'], input_data.astype(np.float32))
        self.rf_interpreter.invoke()
        rf_output = self.rf_interpreter.get_tensor(output_details_rf[0]['index'])
        
        # Calculate ensemble prediction (average of both models)
        ensemble_pred = (lr_output[0][0] + rf_output[0][0]) / 2
        
        return {
            'lr_prediction': float(lr_output[0][0]),
            'rf_prediction': float(rf_output[0][0]),
            'ensemble_prediction': float(ensemble_pred)
        }
    
    def predict_performance(self, performances):
        """Predict next performance and calculate changes for all metrics."""
        try:
            # Create time series features
            input_data, data = self._create_time_series_features(performances)
            
            # Get current values (most recent values for each metric)
            current_values = data.iloc[-1].to_dict()
            
            # Make predictions for each metric
            predictions = {}
            
            # Predict pass_completion_rate (primary metric)
            prediction_results = self._run_inference(input_data)
            ensemble_pred = prediction_results['ensemble_prediction']
            
            # Current value (most recent pass_completion_rate)
            current_perf = current_values['pass_completion_rate']
            
            # Calculate percentage change
            perf_change = (ensemble_pred - current_perf) / current_perf
            
            # Add to predictions
            predictions['pass_completion_rate'] = {
                'current_value': float(current_perf),
                'predicted_value': float(ensemble_pred),
                'percentage_change': float(perf_change)
            }
            
            # For simplicity, we'll use this model for all metrics with some adjustments
            # In a production environment, you'd train separate models for each metric
            
            # Predict other metrics
            other_metrics = [m for m in self.model_info['features'] if m != 'pass_completion_rate']
            for metric in other_metrics:
                current_value = current_values[metric]
                
                # Simple prediction based on pass completion rate change
                # This is a simplified approach - in production you would train separate models
                adjustment_factor = 0.8 + np.random.uniform(-0.3, 0.3)  # Add some variability
                metric_change = perf_change * adjustment_factor
                predicted_value = current_value * (1 + metric_change)
                
                predictions[metric] = {
                    'current_value': float(current_value),
                    'predicted_value': float(predicted_value),
                    'percentage_change': float(metric_change)
                }
            
            return {
                'success': True,
                'predictions': predictions
            }
        except Exception as e:
            print(f"Error predicting performance: {e}")
            return {
                'success': False,
                'message': str(e)
            }

# Function to be called from Flutter
def predict_performance(performances_json):
    """
    Predict player performance from a JSON string of performances.
    
    Args:
        performances_json: JSON string containing performance data
        
    Returns:
        JSON string with prediction results
    """
    try:
        # Parse JSON
        performances = json.loads(performances_json)
        
        # Create predictor
        predictor = PerformancePredictor()
        
        # Make prediction
        result = predictor.predict_performance(performances)
        
        # Return JSON string
        return json.dumps(result)
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': str(e)
        })

# Test function
if __name__ == "__main__":
    # Create some test data
    performances = []
    for i in range(10):
        performances.append({
            'match_num': i + 1,
            'pass_completion_rate': 0.75 + (i * 0.01),
            'total_events': 30 + (i * 2),
            'total_passes': 40 + (i * 3),
            'defensive_actions': 10 + i
        })
    
    # Convert to JSON
    performances_json = json.dumps(performances)
    
    # Test prediction
    result = predict_performance(performances_json)
    print(result)