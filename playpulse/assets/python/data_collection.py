from statsbombpy import sb
import pandas as pd
import time
import warnings
warnings.filterwarnings('ignore')

class PlayerDataCollector:
    def __init__(self, player_id=None, player_name=None, max_matches=15):
        """Initialize the data collector with either player ID or name."""
        self.player_id = player_id
        self.player_name = player_name
        self.max_matches = max_matches
        self.player_events = None
        self.player_matches = None
        self.performance_metrics = None
        self.full_name = None
        
    def find_player(self):
        """Find player ID if only name is provided."""
        if self.player_id is not None:
            return self._verify_player_id()
        
        if self.player_name is None:
            raise ValueError("Either player_id or player_name must be provided")
        
        print(f"Searching for player: {self.player_name}...")
        start_time = time.time()
        
        # Get competitions (prioritize more recent ones)
        competitions = sb.competitions()
        competitions = competitions.sort_values('season_id', ascending=False)
        
        # Limit to checking at most 5 competitions to save time
        checked_competitions = 0
        
        for _, comp in competitions.iterrows():
            if checked_competitions >= 5:
                break
                
            try:
                matches = sb.matches(competition_id=comp['competition_id'], season_id=comp['season_id'])
                if matches.empty:
                    continue
                    
                checked_competitions += 1
                print(f"Checking {comp['competition_name']} {comp['season_name']}...")
                
                # Check just one match from this competition
                match_id = matches.iloc[0]['match_id']
                events = sb.events(match_id=match_id)
                
                # Get all players
                players = events[['player_id', 'player']].dropna().drop_duplicates()
                
                # Search for name
                for _, player in players.iterrows():
                    if isinstance(player['player'], str) and self.player_name.lower() in player['player'].lower():
                        search_time = time.time() - start_time
                        self.player_id = player['player_id']
                        self.full_name = player['player']
                        print(f"Found player: {self.full_name} with ID: {self.player_id}")
                        print(f"Search completed in {search_time:.2f} seconds")
                        return True
            except Exception as e:
                print(f"Error searching in competition: {e}")
                continue
        
        print(f"Player not found. Search completed in {time.time() - start_time:.2f} seconds")
        return False
    
    def _verify_player_id(self):
        """Verify a player ID exists in the dataset."""
        # Get competitions (prioritize more recent ones)
        competitions = sb.competitions()
        competitions = competitions.sort_values('season_id', ascending=False)
        
        for _, comp in competitions.iterrows():
            try:
                matches = sb.matches(competition_id=comp['competition_id'], season_id=comp['season_id'])
                if matches.empty:
                    continue
                    
                # Check just one match
                match_id = matches.iloc[0]['match_id']
                events = sb.events(match_id=match_id)
                
                # Check if player exists
                player_info = events[events['player_id'] == self.player_id][['player_id', 'player']].drop_duplicates()
                if not player_info.empty:
                    self.full_name = player_info.iloc[0]['player']
                    print(f"Verified player ID {self.player_id} ({self.full_name})")
                    return True
            except:
                continue
                
        print(f"Could not verify player ID {self.player_id}")
        return False
    
    def collect_player_data(self):
        """Collect player match and event data."""
        if self.player_id is None:
            if not self.find_player():
                return False
        
        print(f"Getting data for {self.full_name} (ID: {self.player_id})...")
        start_time = time.time()
        
        # Get competitions (prioritize more recent ones)
        competitions = sb.competitions()
        competitions = competitions.sort_values('season_id', ascending=False)
        
        # Track matches where we've found the player
        player_matches = []
        all_player_events = pd.DataFrame()
        matches_found = 0
        
        # Go through competitions from most recent
        for _, comp in competitions.iterrows():
            if matches_found >= self.max_matches:
                break
                
            comp_id = comp['competition_id']
            season_id = comp['season_id']
            
            try:
                # Get matches for this competition
                matches = sb.matches(competition_id=comp_id, season_id=season_id)
                
                # Sort matches by date (most recent first)
                matches['match_date'] = pd.to_datetime(matches['match_date'])
                matches = matches.sort_values('match_date', ascending=False)
                
                # Process each match
                for _, match in matches.iterrows():
                    if matches_found >= self.max_matches:
                        break
                        
                    match_id = match['match_id']
                    
                    try:
                        # Get events for this match
                        events = sb.events(match_id=match_id)
                        
                        # Check if player is in this match
                        player_events = events[events['player_id'] == self.player_id]
                        
                        if not player_events.empty:
                            # Player found in this match
                            matches_found += 1
                            print(f"Found match {matches_found}/{self.max_matches}: {match['home_team']} vs {match['away_team']} ({match['match_date'].date()})")
                            
                            # Add match info
                            player_events['match_id'] = match_id
                            player_events['match_date'] = match['match_date']
                            player_events['competition'] = comp['competition_name']
                            player_events['season'] = comp['season_name']
                            player_events['home_team'] = match['home_team']
                            player_events['away_team'] = match['away_team']
                            
                            # Add to collections
                            all_player_events = pd.concat([all_player_events, player_events])
                            
                            # Save match info
                            player_matches.append({
                                'match_id': match_id,
                                'match_date': match['match_date'],
                                'competition': comp['competition_name'],
                                'season': comp['season_name'],
                                'home_team': match['home_team'],
                                'away_team': match['away_team']
                            })
                            
                    except Exception as e:
                        print(f"Error with match {match_id}: {e}")
                        continue
                        
            except Exception as e:
                print(f"Error with competition {comp_id}-{season_id}: {e}")
                continue
        
        # Create DataFrame of matches
        matches_df = pd.DataFrame(player_matches)
        
        processing_time = time.time() - start_time
        print(f"Data collection completed in {processing_time:.2f} seconds")
        print(f"Found {matches_found} matches with player participation")
        
        if matches_found > 0:
            self.player_events = all_player_events
            self.player_matches = matches_df
            return True
        else:
            print("No matches found for player")
            return False
    
    def calculate_performance_metrics(self):
        """Calculate performance metrics for each match."""
        if self.player_events is None or self.player_matches is None:
            print("No player data available. Run collect_player_data() first.")
            return False
        
        metrics = []
        
        # Calculate metrics for each match
        for _, match in self.player_matches.iterrows():
            match_id = match['match_id']
            match_events = self.player_events[self.player_events['match_id'] == match_id]
            
            # Basic event counts
            total_events = len(match_events)
            
            # Pass metrics
            passes = match_events[match_events['type'] == 'Pass']
            total_passes = len(passes)
            completed_passes = sum(passes['pass_outcome'].isna())
            pass_completion_rate = completed_passes / total_passes if total_passes > 0 else 0
            
            # Shot metrics
            shots = match_events[match_events['type'] == 'Shot']
            total_shots = len(shots)
            goals = len(shots[shots['shot_outcome'] == 'Goal'])
            
            # Defensive actions
            defensive_actions = len(match_events[match_events['type'].isin(['Interception', 'Block', 'Clearance', 'Pressure', 'Tackle'])])
            
            # Create metrics dictionary
            match_metrics = {
                'match_id': match_id,
                'match_date': match['match_date'],
                'competition': match['competition'],
                'season': match['season'],
                'home_team': match['home_team'],
                'away_team': match['away_team'],
                'total_events': total_events,
                'total_passes': total_passes,
                'completed_passes': completed_passes,
                'pass_completion_rate': pass_completion_rate,
                'total_shots': total_shots,
                'goals': goals,
                'defensive_actions': defensive_actions
            }
            
            metrics.append(match_metrics)
        
        # Create metrics DataFrame and sort by date (oldest to newest for time series)
        self.performance_metrics = pd.DataFrame(metrics)
        self.performance_metrics = self.performance_metrics.sort_values('match_date')
        
        # Add a match sequence number (for easier time series indexing)
        self.performance_metrics['match_num'] = range(1, len(self.performance_metrics) + 1)
        
        print(f"Calculated performance metrics for {len(self.performance_metrics)} matches")
        return True