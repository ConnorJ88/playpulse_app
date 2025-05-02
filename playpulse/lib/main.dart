import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'services/auth_service.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/player_search_page.dart';
import 'screens/player_details_page.dart';
import 'screens/settings_page.dart';
import 'screens/player_id_help.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const PlayPulseApp(),
    ),
  );
}

class PlayPulseApp extends StatelessWidget {
  const PlayPulseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlayPulse',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/search': (context) => const PlayerSearchScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/player_id_help': (context) => const PlayerIdHelpScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/player') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => PlayerDetailsScreen(
              playerId: args['playerId'],
            ),
          );
        }
        return null;
      },
    );
  }
}