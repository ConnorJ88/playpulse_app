class Player {
  final int id;
  final String name;
  final String team;
  final String position;
  final int? age;
  final String? nationality;
  final String? imageUrl;

  Player({
    required this.id,
    required this.name,
    required this.team,
    required this.position,
    this.age,
    this.nationality,
    this.imageUrl,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      team: json['team'],
      position: json['position'],
      age: json['age'],
      nationality: json['nationality'],
      imageUrl: json['image_url'],
    );
  }
}

class Performance {
  final int id;
  final int playerId;
  final String date;
  final String competition;
  final String season;
  final String homeTeam;
  final String awayTeam;
  final int totalEvents;
  final int totalPasses;
  final int completedPasses;
  final double passCompletionRate;
  final int totalShots;
  final int goals;
  final int defensiveActions;
  final int matchNumber;

  Performance({
    required this.id,
    required this.playerId,
    required this.date,
    required this.competition,
    required this.season,
    required this.homeTeam,
    required this.awayTeam,
    required this.totalEvents,
    required this.totalPasses,
    required this.completedPasses,
    required this.passCompletionRate,
    required this.totalShots,
    required this.goals,
    required this.defensiveActions,
    required this.matchNumber,
  });

  factory Performance.fromJson(Map<String, dynamic> json) {
    return Performance(
      id: json['id'],
      playerId: json['player_id'],
      date: json['match_date'],
      competition: json['competition'],
      season: json['season'],
      homeTeam: json['home_team'],
      awayTeam: json['away_team'],
      totalEvents: json['total_events'],
      totalPasses: json['total_passes'],
      completedPasses: json['completed_passes'],
      passCompletionRate: json['pass_completion_rate'].toDouble(),
      totalShots: json['total_shots'],
      goals: json['goals'],
      defensiveActions: json['defensive_actions'],
      matchNumber: json['match_num'],
    );
  }

  // Helper method to calculate team role
  String getTeamRole() {
    final isHome = homeTeam.contains(playerId.toString()); // Simplified check
    return isHome ? 'Home' : 'Away';
  }
}