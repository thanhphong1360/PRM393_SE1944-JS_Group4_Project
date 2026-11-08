
import 'package:flutter/material.dart';

import '../../../models/user.dart';
import 'admin_conference_list_screen.dart';
import 'admin_attendee_list_screen.dart';
import 'admin_ticket_management_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final User user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  Widget _buildMenuCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
          Text(
            'Manage your conference system.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Management',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuCard(
            context: context,
            icon: Icons.event,
            title: 'Conference Management',
            description:
            'View, create, update and cancel conferences.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdminConferenceListScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.people,
            title: 'Attendee Management',
            description:
            'Search and view attendee information.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdminAttendeeListScreen(),
                ),
              );
            },
          ),
          _buildMenuCard(
            context: context,
            icon: Icons.confirmation_number,
            title: 'Ticket Management',
            description:
            'Issue and revoke attendee tickets.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                  const AdminTicketManagementScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
