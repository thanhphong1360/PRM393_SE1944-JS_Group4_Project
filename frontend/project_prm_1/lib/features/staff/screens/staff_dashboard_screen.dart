
import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../models/conference.dart';
import 'staff_conference_selection_screen.dart';
import 'staff_qr_scanner_screen.dart';

class StaffDashboardScreen extends StatelessWidget {
  final User user;

  const StaffDashboardScreen({
    super.key,
    required this.user,
  });

  Future<void> _selectConference(BuildContext context) async {
    final Conference? selectedConference =
    await Navigator.push<Conference>(
      context,
      MaterialPageRoute(
        builder: (context) =>
        const StaffConferenceSelectionScreen(),
      ),
    );

    if (!context.mounted || selectedConference == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffQrScannerScreen(
          conference: selectedConference,
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
            'Manage attendee check-in for conferences.',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Staff Functions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 28,
                  color: Colors.blue,
                ),
              ),
              title: const Text(
                'Ticket Check-in',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Select a conference and check in attendee tickets.',
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 16,
              ),
              onTap: () => _selectConference(context),
            ),
          ),
        ],
      ),
    );
  }
}
