"""
This script converts scikit-learn models to TensorFlow Lite format for mobile deployment.
"""

import tensorflow as tf
import numpy as np
import pandas as pd
import pickle
import json
import os
from sklearn.preprocessing import MinMaxScaler

# Import custom modules
from ml_models import PlayerPerformancePredictor
from data_collection import PlayerDataCollector

class TFLiteConverter:
    def __init__(self, output_dir='./tflite_models'):
        """Initialize the converter with output directory."""
        self.output_dir = output_dir
        os.makedirs(output_dir, exist_ok=True)
    
    def convert_sklearn_model_to_tflite(self, sklearn_model, input_shape, output_path):
        """Convert a scikit-learn model to TFLite format."""
        # Define a TensorFlow model that wraps the scikit-learn model
        class SklearnToTF(tf.Module):
            def __init__(self, model):
                super().__init__()
                self.model = model
            
            @tf.function(input_signature=[tf.TensorSpec(shape=input_shape, dtype=tf.float32)])
            def predict(self, x):
                # Convert tensor to numpy for sklearn
                x_np = x.numpy()
                # Get prediction from sklearn model
                prediction = self.model.predict(x_np)
                # Convert back to tensor
                return {"output": tf.convert_to_tensor(prediction, dtype=tf.float32)}
        
        # Create and save the TensorFlow model
        tf_model = SklearnToTF(sklearn_model)
        converter = tf.lite.TFLiteConverter.from_concrete_functions(
            [tf_model.predict.get_concrete_function()], tf_model)
        tflite_model = converter.convert()
        
        # Save the model
        with open(output_path, 'wb') as f:
            f.write(tflite_model)
        
        print(f"Model converted and saved to {output_path}")
        return tflite_model
    
    def prepare_player_data(self, player_id=None, player_name=None, max_matches=15):
        """Prepare player data for model training and conversion."""
        # Create data collector
        collector = PlayerDataCollector(player_id=player_id, player_name=player_name, max_matches=max_matches)
        
        # Find player if name provided
        if player_id is None and player_name is not None:
            if not collector.find_player():
                raise ValueError(f"Player '{player_name}' not found")
        
        # Collect player data
        if not collector.collect_player_data():
            raise ValueError("Failed to collect player data")
        
        # Calculate performance metrics
        if not collector.calculate_performance_metrics():
            raise ValueError("Failed to calculate performance metrics")
        
        return collector.performance_metrics
    
    def train_and_convert_models(self, performance_metrics=None, player_id=None, player_name=None):
        """Train models using player data and convert to TFLite format."""
        # Get performance metrics if not provided
        if performance_metrics is None:
            performance_metrics = self.prepare_player_data(player_id=player_id, player_name=player_name)
        
        # Create predictor
        predictor = PlayerPerformancePredictor(performance_metrics)
        
        # Train models
        if not predictor.train_models():
            raise ValueError("Failed to train prediction models")
        
        # Get window size and features
        window_size = predictor.models['window_size']
        features = predictor.models['features']
        input_shape = [1, window_size * len(features)]  # (1, window_size * num_features)
        
        # Convert Linear Regression model
        lr_model_path = os.path.join(self.output_dir, 'linear_regression_model.tflite')
        self.convert_sklearn_model_to_tflite(
            predictor.models['linear_regression'], 
            input_shape, 
            lr_model_path
        )
        
        # Convert Random Forest model
        rf_model_path = os.path.join(self.output_dir, 'random_forest_model.tflite')
        self.convert_sklearn_model_to_tflite(
            predictor.models['random_forest'], 
            input_shape, 
            rf_model_path
        )
        
        # Save scaler parameters
        scaler = predictor.models['scaler']
        scaler_params = {
            'min_': scaler.min_.tolist(),
            'scale_': scaler.scale_.tolist(),
            'feature_names': features,
            'window_size': window_size
        }
        
        scaler_path = os.path.join(self.output_dir, 'scaler_params.json')
        with open(scaler_path, 'w') as f:
            json.dump(scaler_params, f)
        
        print(f"Scaler parameters saved to {scaler_path}")
        
        # Save model info
        model_info = {
            'features': features,
            'window_size': window_size,
            'input_shape': input_shape,
            'model_files': {
                'linear_regression': 'linear_regression_model.tflite',
                'random_forest': 'random_forest_model.tflite',
                'scaler': 'scaler_params.json'
            }
        }
        
        model_info_path = os.path.join(self.output_dir, 'model_info.json')
        with open(model_info_path, 'w') as f:
            json.dump(model_info, f)
        
        print(f"Model info saved to {model_info_path}")
        return {
            'model_info': model_info,
            'scaler_params': scaler_params
        }
    
    def save_example_input(self, performance_metrics, output_path=None):
        """Save example input data for testing."""
        if output_path is None:
            output_path = os.path.join(self.output_dir, 'example_input.json')
        
        # Create predictor
        predictor = PlayerPerformancePredictor(performance_metrics)
        X, y, X_reshaped, scaler = predictor.create_time_series_features()
        
        # Get last input for prediction
        last_input = X_reshaped[-1].tolist()
        
        # Save example input
        with open(output_path, 'w') as f:
            json.dump({
                'input': last_input,
                'features': predictor.models['features'] if 'features' in predictor.models else None,
                'window_size': predictor.models['window_size'] if 'window_size' in predictor.models else None
            }, f)
        
        print(f"Example input saved to {output_path}")
        return last_input

if __name__ == "__main__":
    # Example usage
    converter = TFLiteConverter(output_dir='./tflite_models')
    
    # Convert models for a specific player
    # Uncomment and modify as needed
    # player_name = "Lionel Messi"  # Example
    # result = converter.train_and_convert_models(player_name=player_name)
    
    # Use existing data (for testing)
    import pandas as pd
    import numpy as np
    
    # Create synthetic data for testing
    match_dates = pd.date_range(start='2025-01-01', periods=15)
    matches = pd.DataFrame({
        'match_id': range(1, 16),
        'match_date': match_dates,
        'competition': ['Premier League'] * 15,
        'season': ['2024/2025'] * 15,
        'home_team': ['Team A'] * 15,
        'away_team': ['Team B'] * 15,
        'total_events': np.random.randint(20, 60, 15),
        'total_passes': np.random.randint(30, 70, 15),
        'completed_passes': np.random.randint(20, 60, 15),
        'pass_completion_rate': np.random.uniform(0.6, 0.9, 15),
        'total_shots': np.random.randint(1, 8, 15),
        'goals': np.random.randint(0, 3, 15),
        'defensive_actions': np.random.randint(5, 25, 15),
        'match_num': range(1, 16)
    })
    
    # Train and convert models
    result = converter.train_and_convert_models(performance_metrics=matches)
    
    # Save example input
    example_input = converter.save_example_input(matches)
    
    print("Conversion completed!")