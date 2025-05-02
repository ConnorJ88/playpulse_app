import 'package:flutter/material.dart';
import '../config/theme.dart';

class PlayerIdHelpScreen extends StatelessWidget {
  const PlayerIdHelpScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finding Your Player ID'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How to Find Your Player ID',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Step 1
            _buildStep(
              stepNumber: 1,
              title: 'Check Your Player Card',
              description: 'If you have a physical or digital player card, your ID should be printed on it, typically in the format "Player ID: XXXXX".'
            ),
            const SizedBox(height: 24),
            
            // Step 2
            _buildStep(
              stepNumber: 2,
              title: 'Ask Your Coach or Team Administrator',
              description: 'Your coach or team admin has access to the team roster with all player IDs.'
            ),
            const SizedBox(height: 24),
            
            // Step 3
            _buildStep(
              stepNumber: 3,
              title: 'Check the League Website',
              description: 'Many leagues provide player profiles on their official websites. Your player ID may be visible in the URL or player profile.'
            ),
            const SizedBox(height: 24),
            
            // Step 4
            _buildStep(
              stepNumber: 4,
              title: 'Contact League Support',
              description: 'If you cannot find your player ID through other methods, contact your league\'s support team for assistance.'
            ),
            const SizedBox(height: 32),
            
            // Demo accounts section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo Accounts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'For demonstration purposes, you can use these player IDs:',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDemoAccount('1', 'Lionel Messi', 'Forward'),
                  _buildDemoAccount('2', 'Cristiano Ronaldo', 'Forward'),
                  _buildDemoAccount('3', 'Kevin De Bruyne', 'Midfielder'),
                  _buildDemoAccount('4', 'Virgil van Dijk', 'Defender'),
                  _buildDemoAccount('5', 'Jude Bellingham', 'Midfielder'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Return to login button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Return to Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required int stepNumber,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
          ),
          child: Center(
            child: Text(
              stepNumber.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoAccount(String id, String name, String position) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              id,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($position)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}