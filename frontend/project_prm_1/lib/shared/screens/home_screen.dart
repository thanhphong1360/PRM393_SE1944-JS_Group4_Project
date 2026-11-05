import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/attendee/screens/conference_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  String get roleDescription {
    switch (user.role) {
      case 'Admin':
        return 'Administrator Dashboard';
      case 'Staff':
        return 'Staff Dashboard';
      case 'Attendee':
        return 'Attendee Dashboard';
      default:
        return 'Unknown Role';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conference Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
              ),
              const SizedBox(height: 20),

              Text(
                'Welcome, ${user.fullName ?? user.email}!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text('Email: ${user.email}'),

              const SizedBox(height: 8),

              Text('Role: ${user.role}'),

              const SizedBox(height: 24),

              Text(
                roleDescription,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (user.role == 'Attendee') ...[
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const ConferenceListScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event),
                    label: const Text('Browse Conferences'),
                  ),
                ),
              ],            ],

          ),
        ),
      ),
    );
  }
}