import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.preprocessing import MinMaxScaler
from sklearn.linear_model import LinearRegression
from sklearn.svm import SVR
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.metrics import mean_squared_error

class PlayerPerformancePredictor:
    def __init__(self, performance_metrics=None):
        """Initialize with performance metrics data."""
        self.performance_metrics = performance_metrics
        self.models = {}
        self.decline_threshold = 0.05  # 5% decline threshold
    
    def set_metrics(self, performance_metrics):
        """Set the performance metrics data."""
        self.performance_metrics = performance_metrics
    
    def create_time_series_features(self, window_size=3):
        """Create time series features for ML models."""
        if self.performance_metrics is None:
            print("No performance metrics available.")
            return None, None, None, None
        
        # Select key metrics for prediction
        features = ['pass_completion_rate', 'total_events', 'total_passes', 'defensive_actions']
        
        # Get data
        data = self.performance_metrics[features].copy()
        
        # Normalize data
        scaler = MinMaxScaler(feature_range=(0, 1))
        scaled_data = scaler.fit_transform(data)
        
        # Create X (input features) and y (target values) for ML models
        X, y = [], []
        
        # Use sliding window approach
        for i in range(window_size, len(scaled_data)):
            X.append(scaled_data[i-window_size:i])
            y.append(scaled_data[i, 0])  # pass_completion_rate as target
        
        # Convert to numpy arrays
        X = np.array(X)
        y = np.array(y)
        
        # For non-sequential models, reshape X
        X_reshaped = X.reshape(X.shape[0], X.shape[1] * X.shape[2])
        
        return X, y, X_reshaped, scaler
    
    def train_models(self):
        """Train various models for performance prediction."""
        X, y, X_reshaped, scaler = self.create_time_series_features()
        
        if X is None or len(X) < 4:  # Need some minimum amount of data
            print("Not enough time series data for modeling")
            return False
        
        # Split into train and test
        train_size = int(len(X) * 0.8)
        X_train, X_test = X[:train_size], X[train_size:]
        y_train, y_test = y[:train_size], y[train_size:]
        
        X_train_reshaped = X_reshaped[:train_size]
        X_test_reshaped = X_reshaped[train_size:]
        
        print(f"Training models with {train_size} samples, testing with {len(X) - train_size} samples")
        
        # 1. Neural Network (instead of LSTM)
        model_nn = MLPRegressor(
            hidden_layer_sizes=(50, 50),
            activation='relu',
            solver='adam',
            max_iter=500,
            early_stopping=True,
            random_state=42,
            verbose=0
        )
        model_nn.fit(X_train_reshaped, y_train)
        
        # 2. Linear Regression
        model_lr = LinearRegression()
        model_lr.fit(X_train_reshaped, y_train)
        
        # 3. Decision Tree
        model_dt = DecisionTreeRegressor(max_depth=3)
        model_dt.fit(X_train_reshaped, y_train)
        
        # 4. SVM
        model_svm = SVR(kernel='rbf', C=1.0, epsilon=0.1)
        model_svm.fit(X_train_reshaped, y_train)
        
        # 5. Random Forest
        model_rf = RandomForestRegressor(n_estimators=100, random_state=42)
        model_rf.fit(X_train_reshaped, y_train)
        
        # Evaluate models
        print("\nModel Evaluation:")
        
        # Neural Network evaluation
        y_pred_nn = model_nn.predict(X_test_reshaped)
        mse_nn = mean_squared_error(y_test, y_pred_nn)
        print(f"Neural Network - MSE: {mse_nn:.4f}")
        
        # Linear Regression evaluation
        y_pred_lr = model_lr.predict(X_test_reshaped)
        mse_lr = mean_squared_error(y_test, y_pred_lr)
        print(f"Linear Regression - MSE: {mse_lr:.4f}")
        
        # Decision Tree evaluation
        y_pred_dt = model_dt.predict(X_test_reshaped)
        mse_dt = mean_squared_error(y_test, y_pred_dt)
        print(f"Decision Tree - MSE: {mse_dt:.4f}")
        
        # SVM evaluation
        y_pred_svm = model_svm.predict(X_test_reshaped)
        mse_svm = mean_squared_error(y_test, y_pred_svm)
        print(f"SVM - MSE: {mse_svm:.4f}")
        
        # Random Forest evaluation
        y_pred_rf = model_rf.predict(X_test_reshaped)
        mse_rf = mean_squared_error(y_test, y_pred_rf)
        print(f"Random Forest - MSE: {mse_rf:.4f}")
        
        # Store models for later use
        self.models = {
            'neural_network': model_nn,
            'linear_regression': model_lr,
            'decision_tree': model_dt,
            'svm': model_svm,
            'random_forest': model_rf,
            'scaler': scaler,
            'window_size': X_train.shape[1],
            'features': ['pass_completion_rate', 'total_events', 'total_passes', 'defensive_actions']
        }
        
        return True
    
    def predict_next_performance(self):
        """Predict next performance and check for decline."""
        if not self.models:
            print("Models not trained. Run train_models() first.")
            return
        
        if self.performance_metrics is None or len(self.performance_metrics) < self.models['window_size']:
            print("Not enough performance data for prediction")
            return
        
        # Get most recent data
        recent_data = self.performance_metrics[self.models['features']].tail(self.models['window_size']).values
        
        # Scale the data
        scaled_data = self.models['scaler'].transform(recent_data)
        
        # Prepare input for models (2D)
        X_reshaped = scaled_data.reshape(1, scaled_data.shape[0] * scaled_data.shape[1])
        
        # Make predictions
        pred_nn = self.models['neural_network'].predict(X_reshaped)[0]
        pred_lr = self.models['linear_regression'].predict(X_reshaped)[0]
        pred_dt = self.models['decision_tree'].predict(X_reshaped)[0]
        pred_svm = self.models['svm'].predict(X_reshaped)[0]
        pred_rf = self.models['random_forest'].predict(X_reshaped)[0]
        
        # Get ensemble prediction (average of all models)
        ensemble_pred = np.mean([pred_nn, pred_lr, pred_dt, pred_svm, pred_rf])
        
        # Get current performance (most recent pass_completion_rate)
        current_perf = scaled_data[-1, 0]  # First feature is pass_completion_rate
        
        # Calculate percentage change
        perf_change = (ensemble_pred - current_perf) / current_perf
        
        print("\nPerformance Prediction:")
        print(f"Current performance: {current_perf:.4f}")
        print(f"Ensemble prediction: {ensemble_pred:.4f}")
        print(f"Change: {perf_change:.2%}")
        
        # Check for decline
        if perf_change <= -self.decline_threshold:
            self._alert_decline(perf_change)
        
        return ensemble_pred, perf_change
    
    def _alert_decline(self, perf_change):
        """Send an alert when predicted decrease is by 5% or more."""
        print("\n" + "!" * 50)
        print(f"ALERT: Predicted performance decline of {abs(perf_change):.2%}")
        print("This decline exceeds the threshold of 5%")
        print("Recommendation: Consider monitoring player workload or providing additional support")
        print("!" * 50)
    
    def visualize_performance(self, player_name=None):
        """Visualize player performance over time."""
        if self.performance_metrics is None:
            print("No performance metrics available")
            return
        
        plt.figure(figsize=(12, 10))
        
        # Plot 1: Pass completion rate over time
        plt.subplot(2, 2, 1)
        plt.plot(self.performance_metrics['match_num'], self.performance_metrics['pass_completion_rate'], 'b-o')
        plt.title('Pass Completion Rate Over Time')
        plt.xlabel('Match Number')
        plt.ylabel('Pass Completion Rate')
        plt.grid(True)
        
        # Plot 2: Total events over time
        plt.subplot(2, 2, 2)
        plt.plot(self.performance_metrics['match_num'], self.performance_metrics['total_events'], 'g-o')
        plt.title('Total Events Over Time')
        plt.xlabel('Match Number')
        plt.ylabel('Total Events')
        plt.grid(True)
        
        # Plot 3: Defensive actions over time
        plt.subplot(2, 2, 3)
        plt.plot(self.performance_metrics['match_num'], self.performance_metrics['defensive_actions'], 'r-o')
        plt.title('Defensive Actions Over Time')
        plt.xlabel('Match Number')
        plt.ylabel('Defensive Actions')
        plt.grid(True)
        
        # Plot 4: Shots and goals over time
        plt.subplot(2, 2, 4)
        plt.plot(self.performance_metrics['match_num'], self.performance_metrics['total_shots'], 'c-o', label='Shots')
        plt.plot(self.performance_metrics['match_num'], self.performance_metrics['goals'], 'm-*', label='Goals')
        plt.title('Shots and Goals Over Time')
        plt.xlabel('Match Number')
        plt.ylabel('Count')
        plt.legend()
        plt.grid(True)
        
        if player_name:
            plt.suptitle(f'Performance Metrics for {player_name}', fontsize=16)
            
        plt.tight_layout()
        plt.show()