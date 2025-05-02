import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/player.dart';

class PlayerSearchScreen extends StatefulWidget {
  const PlayerSearchScreen({Key? key}) : super(key: key);

  @override
  _PlayerSearchScreenState createState() => _PlayerSearchScreenState();
}

class _PlayerSearchScreenState extends State<PlayerSearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  List<Player> _searchResults = [];
  String? _errorMessage;
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchPlayers(query);
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToPlayerDetails(int playerId) {
    Navigator.of(context).pushNamed(
      '/player',
      arguments: {'playerId': playerId},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Players'),
      ),
      body: Column(
        children: [
          // Search Box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _performSearch,
              textInputAction: TextInputAction.search,
              onSubmitted: _performSearch,
            ),
          ),

          // Search Filters (optional)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip('Forward'),
                _buildFilterChip('Midfielder'),
                _buildFilterChip('Defender'),
                _buildFilterChip('Goalkeeper'),
                _buildFilterChip('Premier League'),
                _buildFilterChip('La Liga'),
                _buildFilterChip('Bundesliga'),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(),
          
          // Search Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: $_errorMessage',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _searchResults.isEmpty
                        ? _buildEmptyState()
                        : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: (bool selected) {
          // In a real app, you'd apply filters here
          // For demo, we'll just perform the search with the current query
          _performSearch(_searchController.text);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    // Only show the empty search results view if the user has entered a search term
    return _searchController.text.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Search for players by name',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_off,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No players found for "${_searchController.text}"',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final player = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: player.imageUrl != null
                  ? NetworkImage(player.imageUrl!)
                  : null,
              child: player.imageUrl == null
                  ? Text(
                      player.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 24),
                    )
                  : null,
            ),
            title: Text(
              player.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text('Team: ${player.team}'),
                const SizedBox(height: 4),
                Text('Position: ${player.position}'),
                if (player.nationality != null) ...[
                  const SizedBox(height: 4),
                  Text('Nationality: ${player.nationality}'),
                ],
              ],
            ),
            onTap: () => _navigateToPlayerDetails(player.id),
          ),
        );
      },
    );
  }
}