import 'package:flutter/material.dart';

import '../../core/services/auth_service.dart';
import '../../features/attendee/screens/conference_list_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/check_in/screens/qr_scanner_screen.dart';
import '../../features/staff/screens/staff_dashboard_screen.dart';
import '../../features/tickets/screens/my_tickets_screen.dart';
import '../../models/user.dart';

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
    final isStaffOrAdmin = user.role == 'Staff' || user.role == 'Admin';
    final isAttendee = user.role == 'Attendee';

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_circle,
                size: 80,
                color: Colors.blue,
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

              const SizedBox(height: 24),

              // Staff / Admin Options: QR Check-in scanner
              if (isStaffOrAdmin) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QRScannerScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text(
                      'Quét mã QR Điểm danh',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StaffDashboardScreen(initialUser: user),
                        ),
                      );
                    },
                    icon: const Icon(Icons.dashboard_customize),
                    label: const Text('Bàn Quản Lý Điểm Danh'),
                  ),
                ),
              ],

              // Attendee Options: Browse Conferences & My Tickets
              if (isAttendee) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ConferenceListScreen(),
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
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyTicketsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('Vé Của Tôi & Mã QR Điểm Danh'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
