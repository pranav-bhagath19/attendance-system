import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              if (!context.mounted) return;
              await context.read<AuthProvider>().logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.teacher;

          return ListView(
            padding: const EdgeInsets.all(AppTheme.lg),
            children: [
              const SizedBox(height: AppTheme.xl),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.person,
                      size: 60, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.lg),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.badge,
                            color: AppTheme.textSecondary),
                        title: const Text('Name'),
                        subtitle: Text(user?['name'] ?? 'Not set'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.email,
                            color: AppTheme.textSecondary),
                        title: const Text('Email'),
                        subtitle: Text(user?['email'] ?? 'Not set'),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.business,
                            color: AppTheme.textSecondary),
                        title: const Text('Department'),
                        subtitle: Text(user?['department'] ?? 'Not set'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.xl),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _handleLogout(context),
                icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                label: const Text('Logout',
                    style: TextStyle(color: AppTheme.errorColor)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.errorColor),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
