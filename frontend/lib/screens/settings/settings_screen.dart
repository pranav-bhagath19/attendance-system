import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.teacher;
          return ListView(
            padding: const EdgeInsets.all(AppTheme.lg),
            children: [
              const Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(user?['name'] ?? 'Teacher'),
                  subtitle: Text(user?['email'] ?? 'Not set'),
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              const Text(
                'Preferences',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle:
                          const Text('Toggle between light and dark themes'),
                      secondary: const Icon(Icons.dark_mode),
                      value: _darkMode,
                      onChanged: (bool value) {
                        setState(() => _darkMode = value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Theme change implementation coming soon!')),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Swipe Sound'),
                      subtitle: const Text('Play sound effect when swiping'),
                      secondary: const Icon(Icons.volume_up),
                      value: _soundEnabled,
                      onChanged: (bool value) {
                        setState(() => _soundEnabled = value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Sound preferences updated')),
                        );
                      },
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: const Text('Haptic Vibration'),
                      subtitle: const Text('Vibrate on attendance marked'),
                      secondary: const Icon(Icons.vibration),
                      value: _vibrationEnabled,
                      onChanged: (bool value) {
                        setState(() => _vibrationEnabled = value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Vibration settings updated')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
