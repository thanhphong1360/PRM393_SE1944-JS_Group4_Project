
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../core/services/auth_service.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/attendee/screens/conference_list_screen.dart';
import '../../features/attendee/screens/my_registrations_screen.dart';

class HomeScreen extends StatelessWidget {
  final User user;

  const HomeScreen({
    super.key,
    required this.user,
  });

  String _getDashboardTitle() {
    switch (user.role) {
      case 'Admin':
        return 'Administrator Dashboard';
      case 'Staff':
        return 'Staff Dashboard';
      case 'Attendee':
        return 'Attendee Dashboard';
      default:
        return 'Dashboard';
    }
  }

  Future<void> _logout(BuildContext context) async {
    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user.role == 'Admin') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Conference Management'),
          actions: [
            IconButton(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: AdminDashboardScreen(user: user),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conference Management'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user.fullName ?? user.email}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text('Email: ${user.email}'),
            Text('Role: ${user.role}'),

            const SizedBox(height: 24),

            Text(
              _getDashboardTitle(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
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

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                        const MyRegistrationsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.confirmation_number),
                  label: const Text('My Registrations'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
